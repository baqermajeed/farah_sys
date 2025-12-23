from datetime import datetime, timedelta, timezone
from typing import Optional, List, Tuple
from fastapi import HTTPException
from beanie import PydanticObjectId as OID
from beanie.operators import In

from app.models import Patient, User, Doctor, Appointment, TreatmentNote, GalleryImage
from app.constants import Role
from app.schemas import PatientUpdate

MAX_PAGE_SIZE = 100


def _normalize_pagination(skip: int = 0, limit: Optional[int] = None) -> Tuple[int, Optional[int]]:
    """Ensure pagination params stay within safe bounds."""
    safe_skip = max(0, skip)
    if limit is None:
        return safe_skip, None
    safe_limit = max(1, min(limit, MAX_PAGE_SIZE))
    return safe_skip, safe_limit


async def _attach_users(patients: List[Patient]) -> None:
    """Attach User documents to patient objects for legacy attributes."""
    if not patients:
        return
    user_ids = list({p.user_id for p in patients if p.user_id})
    if not user_ids:
        return
    users = await User.find(In(User.id, user_ids)).to_list()
    user_map = {u.id: u for u in users}
    for patient in patients:
        setattr(patient, "user", user_map.get(patient.user_id))

async def get_patient_by_id(patient_id: str) -> Tuple[Patient, User]:
    """Fetch patient and its user info or 404."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    user = await User.get(patient.user_id)
    return patient, user

async def list_doctor_patients(doctor_id: str, skip: int = 0, limit: Optional[int] = None) -> List[Patient]:
    """All patients assigned to this doctor (primary or secondary)."""
    skip, limit = _normalize_pagination(skip, limit)
    try:
        did = OID(doctor_id)
    except Exception as e:
        print(f"❌ Error converting doctor_id to OID: {doctor_id}, error: {e}")
        raise HTTPException(status_code=400, detail=f"Invalid doctor_id format: {doctor_id}")

    try:
        # Beanie v1.x لا يدعم استخدام عامل OR "|" مباشرة بين تعابير المقارنة بهذه الطريقة،
        # لذلك نجلب المرضى الأساسيين والثانويين في استعلامين منفصلين ثم ندمج النتائج.
        primary_patients = await Patient.find(Patient.primary_doctor_id == did).to_list()
        secondary_patients = await Patient.find(Patient.secondary_doctor_id == did).to_list()

        # دمج القوائم مع إزالة التكرار (في حال كان الطبيب أساسيًا وثانويًا لنفس المريض)
        patients_map: dict[OID, Patient] = {p.id: p for p in primary_patients}
        for p in secondary_patients:
            patients_map.setdefault(p.id, p)

        patients = list(patients_map.values())

        # تطبيق التقطيع (skip / limit) بعد الدمج
        if skip:
            patients = patients[skip:]
        if limit is not None:
            patients = patients[:limit]

        # لا نحتاج _attach_users هنا لأننا نجلب User مباشرة في router
        # await _attach_users(patients)
        return patients
    except Exception as e:
        print(f"❌ Error in list_doctor_patients: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error fetching patients: {str(e)}")

async def update_patient_by_doctor(*, doctor_id: str, patient_id: str, data: PatientUpdate) -> Patient:
    """يسمح للطبيب بتعديل بيانات المريض إن كان من مرضاه (أساسي/ثانوي)."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in [patient.primary_doctor_id, patient.secondary_doctor_id]:
        raise HTTPException(status_code=403, detail="Not your patient")
    u = await User.get(patient.user_id)
    if data.name is not None:
        u.name = data.name
    if data.gender is not None:
        u.gender = data.gender
    if data.age is not None:
        u.age = data.age
    if data.city is not None:
        u.city = data.city
    if data.treatment_type is not None:
        patient.treatment_type = data.treatment_type
    await u.save()
    await patient.save()
    return patient

async def update_patient_by_admin(*, patient_id: str, data: PatientUpdate) -> Patient:
    """المدير يعدّل بيانات أي مريض (بما فيها الهاتف مع التحقق من التفرّد)."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    u = await User.get(patient.user_id)
    if data.phone is not None and data.phone != u.phone:
        if await User.find_one(User.phone == data.phone):
            raise HTTPException(status_code=400, detail="Phone already exists")
        u.phone = data.phone
    if data.name is not None:
        u.name = data.name
    if data.gender is not None:
        u.gender = data.gender
    if data.age is not None:
        u.age = data.age
    if data.city is not None:
        u.city = data.city
    if data.treatment_type is not None:
        patient.treatment_type = data.treatment_type
    await u.save()
    await patient.save()
    return patient

async def delete_patient(*, actor_role: Role, patient_id: str, actor_doctor_id: str | None = None) -> None:
    """حذف مريض: المدير دائمًا، والطبيب فقط إن كان من مرضاه."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if actor_role == Role.DOCTOR:
        if OID(actor_doctor_id) not in [patient.primary_doctor_id, patient.secondary_doctor_id]:
            raise HTTPException(status_code=403, detail="Not your patient")
    user = await User.get(patient.user_id)
    if user:
        await user.delete()
    return None

async def assign_patient_doctors(
    *,
    patient_id: str,
    primary_doctor_id: Optional[str],
    secondary_doctor_id: Optional[str],
    assigned_by_user_id: Optional[str] = None,
) -> Patient:
    """Receptionist/Admin can assign 0..2 doctors for a patient and نسجل التحويلات."""
    from app.models import AssignmentLog

    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # Validate doctors exist
    if primary_doctor_id and (await Doctor.get(OID(primary_doctor_id))) is None:
        raise HTTPException(status_code=404, detail="Primary doctor not found")
    if secondary_doctor_id and (await Doctor.get(OID(secondary_doctor_id))) is None:
        raise HTTPException(status_code=404, detail="Secondary doctor not found")

    prev_primary = patient.primary_doctor_id
    prev_secondary = patient.secondary_doctor_id

    patient.primary_doctor_id = OID(primary_doctor_id) if primary_doctor_id else None
    patient.secondary_doctor_id = OID(secondary_doctor_id) if secondary_doctor_id else None

    # سجل التحويلات عند التغيير
    if patient.primary_doctor_id != prev_primary and patient.primary_doctor_id is not None:
        await AssignmentLog(
            patient_id=patient.id,
            doctor_id=patient.primary_doctor_id,
            previous_doctor_id=prev_primary,
            assigned_by_user_id=OID(assigned_by_user_id) if assigned_by_user_id else None,
            kind="primary",
        ).insert()
    if patient.secondary_doctor_id != prev_secondary and patient.secondary_doctor_id is not None:
        await AssignmentLog(
            patient_id=patient.id,
            doctor_id=patient.secondary_doctor_id,
            previous_doctor_id=prev_secondary,
            assigned_by_user_id=OID(assigned_by_user_id) if assigned_by_user_id else None,
            kind="secondary",
        ).insert()

    await patient.save()
    return patient

async def set_treatment_type(*, patient_id: str, doctor_id: str, treatment_type: str) -> Patient:
    """Doctor sets the treatment type for their patient."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in [patient.primary_doctor_id, patient.secondary_doctor_id]:
        raise HTTPException(status_code=403, detail="Not your patient")
    patient.treatment_type = treatment_type
    await patient.save()
    return patient

async def create_note(
    *, patient_id: str, doctor_id: str, note: Optional[str], image_path: Optional[str]
) -> TreatmentNote:
    """Add a new treatment note (section 1) with optional image; date auto."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in [patient.primary_doctor_id, patient.secondary_doctor_id]:
        raise HTTPException(status_code=403, detail="Not your patient")
    tn = TreatmentNote(patient_id=patient.id, doctor_id=OID(doctor_id), note=note, image_path=image_path)
    await tn.insert()
    return tn

async def create_gallery_image(
    *, patient_id: str, uploaded_by_user_id: str, image_path: str, note: Optional[str]
) -> GalleryImage:
    gi = GalleryImage(patient_id=OID(patient_id), uploaded_by_user_id=OID(uploaded_by_user_id), image_path=image_path, note=note)
    await gi.insert()
    return gi

async def create_appointment(
    *, patient_id: str, doctor_id: str, scheduled_at: datetime, note: Optional[str], image_path: Optional[str]
) -> Appointment:
    # Validate ownership
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in [patient.primary_doctor_id, patient.secondary_doctor_id]:
        raise HTTPException(status_code=403, detail="Not your patient")

    ap = Appointment(patient_id=patient.id, doctor_id=OID(doctor_id), scheduled_at=scheduled_at, note=note, image_path=image_path)
    await ap.insert()

    # Notify patient about new appointment (push notification)
    try:
        from app.services.notification_service import notify_user
        await notify_user(user_id=patient.user_id, title="موعد جديد", body="تم تحديد موعدك القادم")
    except Exception:
        pass

    return ap

# ---------------------- Listings & Filters ----------------------

async def _date_bounds(day: Optional[str], date_from: Optional[datetime], date_to: Optional[datetime]) -> tuple[Optional[datetime], Optional[datetime]]:
    now = datetime.now(timezone.utc)
    if day == "today":
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        return start, end
    if day == "tomorrow":
        start = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        return start, end
    if day == "month":
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        # naive month end calc
        if start.month == 12:
            end = start.replace(year=start.year+1, month=1)
        else:
            end = start.replace(month=start.month+1)
        return start, end
    return date_from, date_to

async def list_appointments_for_doctor(
    *,
    doctor_id: str,
    day: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    status: Optional[str] = None,
    skip: int = 0,
    limit: Optional[int] = None,
) -> List[Appointment]:
    start, end = await _date_bounds(day, date_from, date_to)
    skip, limit = _normalize_pagination(skip, limit)
    did = OID(doctor_id)
    query = Appointment.find(Appointment.doctor_id == did)
    if start:
        query = query.find(Appointment.scheduled_at >= start)
    if end:
        query = query.find(Appointment.scheduled_at < end)
    if status == "late":
        now = datetime.now(timezone.utc)
        query = query.find((Appointment.scheduled_at < now) & (Appointment.status == "scheduled"))
    elif status:
        query = query.find(Appointment.status == status)
    query = query.sort("scheduled_at").skip(skip)
    if limit is not None:
        query = query.limit(limit)
    return await query.to_list()

async def list_appointments_for_all(
    *,
    day: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    status: Optional[str] = None,
    skip: int = 0,
    limit: Optional[int] = None,
) -> List[Appointment]:
    start, end = await _date_bounds(day, date_from, date_to)
    skip, limit = _normalize_pagination(skip, limit)
    query = Appointment.find({})
    if start:
        query = query.find(Appointment.scheduled_at >= start)
    if end:
        query = query.find(Appointment.scheduled_at < end)
    if status == "late":
        now = datetime.now(timezone.utc)
        query = query.find((Appointment.scheduled_at < now) & (Appointment.status == "scheduled"))
    elif status:
        query = query.find(Appointment.status == status)
    query = query.sort("scheduled_at").skip(skip)
    if limit is not None:
        query = query.limit(limit)
    return await query.to_list()

async def list_patient_appointments_grouped(*, patient_id: str) -> tuple[List[Appointment], List[Appointment]]:
    p = await Patient.get(OID(patient_id))
    if not p:
        return [], []
    apps = await Appointment.find(Appointment.patient_id == p.id).sort("scheduled_at").to_list()
    primary, secondary = [], []
    for a in apps:
        if p.primary_doctor_id and a.doctor_id == p.primary_doctor_id:
            primary.append(a)
        elif p.secondary_doctor_id and a.doctor_id == p.secondary_doctor_id:
            secondary.append(a)
    return primary, secondary

async def list_notes_for_patient(*, patient_id: str, skip: int = 0, limit: Optional[int] = None) -> List[TreatmentNote]:
    skip, limit = _normalize_pagination(skip, limit)
    query = TreatmentNote.find(TreatmentNote.patient_id == OID(patient_id)).sort("-created_at").skip(skip)
    if limit is not None:
        query = query.limit(limit)
    return await query.to_list()

async def list_gallery_for_patient(*, patient_id: str, skip: int = 0, limit: Optional[int] = None) -> List[GalleryImage]:
    skip, limit = _normalize_pagination(skip, limit)
    query = GalleryImage.find(GalleryImage.patient_id == OID(patient_id)).sort("-created_at").skip(skip)
    if limit is not None:
        query = query.limit(limit)
    return await query.to_list()
