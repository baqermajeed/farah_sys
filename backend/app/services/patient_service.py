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
    """All patients assigned to this doctor (via doctor_ids list)."""
    skip, limit = _normalize_pagination(skip, limit)
    try:
        did = OID(doctor_id)
    except Exception as e:
        print(f"❌ Error converting doctor_id to OID: {doctor_id}, error: {e}")
        raise HTTPException(status_code=400, detail=f"Invalid doctor_id format: {doctor_id}")

    try:
        # Use In operator to find all patients where doctor_id is in doctor_ids list
        patients = await Patient.find(In(Patient.doctor_ids, [did])).skip(skip).limit(limit or MAX_PAGE_SIZE).to_list()
        return patients
    except Exception as e:
        print(f"❌ Error in list_doctor_patients: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error fetching patients: {str(e)}")

async def update_patient_by_doctor(*, doctor_id: str, patient_id: str, data: PatientUpdate) -> Patient:
    """يسمح للطبيب بتعديل بيانات المريض إن كان من مرضاه (في doctor_ids)."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in patient.doctor_ids:
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
        if actor_doctor_id and OID(actor_doctor_id) not in patient.doctor_ids:
            raise HTTPException(status_code=403, detail="Not your patient")
    user = await User.get(patient.user_id)
    if user:
        await user.delete()
    return None

async def assign_patient_doctors(
    *,
    patient_id: str,
    doctor_ids: List[str],
    assigned_by_user_id: Optional[str] = None,
) -> Patient:
    """Receptionist/Admin can assign multiple doctors for a patient and نسجل التحويلات."""
    from app.models import AssignmentLog

    print(f"🔗 [assign_patient_doctors] patient_id: {patient_id}, doctor_ids: {doctor_ids}")

    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    # Validate all doctors exist
    doctor_oids = []
    for doctor_id in doctor_ids:
        doctor = await Doctor.get(OID(doctor_id))
        if doctor is None:
            print(f"❌ [assign_patient_doctors] Doctor {doctor_id} not found")
            raise HTTPException(status_code=404, detail=f"Doctor {doctor_id} not found")
        doctor_oids.append(OID(doctor_id))
        print(f"✅ [assign_patient_doctors] Doctor {doctor_id} found")

    prev_doctor_ids = set(patient.doctor_ids)
    new_doctor_ids = set(doctor_oids)

    print(f"📋 [assign_patient_doctors] Previous doctor_ids: {prev_doctor_ids}")
    print(f"📋 [assign_patient_doctors] Setting doctor_ids to: {new_doctor_ids}")

    # Update doctor_ids
    patient.doctor_ids = doctor_oids

    print(f"💾 [assign_patient_doctors] patient.doctor_ids set to: {patient.doctor_ids}")

    # سجل التحويلات عند التغيير
    # للأطباء الجدد (المضافين)
    added_doctors = new_doctor_ids - prev_doctor_ids
    for doctor_id in added_doctors:
        print(f"📝 [assign_patient_doctors] Creating AssignmentLog for newly added doctor {doctor_id}")
        await AssignmentLog(
            patient_id=patient.id,
            doctor_id=doctor_id,
            previous_doctor_id=None,
            assigned_by_user_id=OID(assigned_by_user_id) if assigned_by_user_id else None,
            kind="assigned",
        ).insert()
    
    # للأطباء المزالين (لم نعد نستخدم هذا حالياً، لكن يمكن إضافته لاحقاً)
    removed_doctors = prev_doctor_ids - new_doctor_ids
    for doctor_id in removed_doctors:
        print(f"📝 [assign_patient_doctors] Doctor {doctor_id} was removed (not logging removal)")

    print(f"💾 [assign_patient_doctors] Saving patient...")
    await patient.save()
    print(f"✅ [assign_patient_doctors] Patient saved. doctor_ids: {patient.doctor_ids}")
    
    # التحقق من الحفظ
    saved_patient = await Patient.get(patient.id)
    print(f"🔍 [assign_patient_doctors] Verification - saved patient doctor_ids: {saved_patient.doctor_ids}")
    
    return patient

async def set_treatment_type(*, patient_id: str, doctor_id: str, treatment_type: str) -> Patient:
    """Doctor sets the treatment type for their patient."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in patient.doctor_ids:
        raise HTTPException(status_code=403, detail="Not your patient")
    patient.treatment_type = treatment_type
    await patient.save()
    return patient

async def create_note(
    *, patient_id: str, doctor_id: str, note: Optional[str], image_path: Optional[str] = None, image_paths: Optional[List[str]] = None
) -> TreatmentNote:
    """Add a new treatment note (section 1) with optional images; date auto."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in patient.doctor_ids:
        raise HTTPException(status_code=403, detail="Not your patient")
    
    # للتوافق مع البيانات القديمة، نستخدم أول صورة كـ image_path
    final_image_path = image_path
    final_image_paths = image_paths or []
    if final_image_paths and not final_image_path:
        final_image_path = final_image_paths[0]
    
    tn = TreatmentNote(
        patient_id=patient.id,
        doctor_id=OID(doctor_id),
        note=note,
        image_path=final_image_path,
        image_paths=final_image_paths
    )
    await tn.insert()
    return tn

async def update_note(
    *, patient_id: str, note_id: str, doctor_id: str, note: Optional[str] = None, image_paths: Optional[List[str]] = None
) -> TreatmentNote:
    """Update an existing treatment note."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in patient.doctor_ids:
        raise HTTPException(status_code=403, detail="Not your patient")
    
    tn = await TreatmentNote.get(OID(note_id))
    if not tn:
        raise HTTPException(status_code=404, detail="Note not found")
    if str(tn.patient_id) != patient_id:
        raise HTTPException(status_code=403, detail="Note does not belong to this patient")
    if str(tn.doctor_id) != doctor_id:
        raise HTTPException(status_code=403, detail="Not your note")
    
    if note is not None:
        tn.note = note
    if image_paths is not None:
        # إذا كانت القائمة فارغة، نحتفظ بالصور القديمة
        if len(image_paths) > 0:
            tn.image_paths = image_paths
            # للتوافق مع البيانات القديمة
            tn.image_path = image_paths[0] if image_paths else None
    
    await tn.save()
    return tn

async def delete_note(
    *, patient_id: str, note_id: str, doctor_id: str
) -> bool:
    """Delete a treatment note."""
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in patient.doctor_ids:
        raise HTTPException(status_code=403, detail="Not your patient")
    
    tn = await TreatmentNote.get(OID(note_id))
    if not tn:
        raise HTTPException(status_code=404, detail="Note not found")
    if str(tn.patient_id) != patient_id:
        raise HTTPException(status_code=403, detail="Note does not belong to this patient")
    if str(tn.doctor_id) != doctor_id:
        raise HTTPException(status_code=403, detail="Not your note")
    
    await tn.delete()
    return True

async def create_gallery_image(
    *, patient_id: str, uploaded_by_user_id: str, image_path: str, note: Optional[str]
) -> GalleryImage:
    gi = GalleryImage(patient_id=OID(patient_id), uploaded_by_user_id=OID(uploaded_by_user_id), image_path=image_path, note=note)
    await gi.insert()
    return gi

async def delete_gallery_image(*, gallery_image_id: str, patient_id: str) -> bool:
    """حذف صورة من المعرض. يتحقق من أن الصورة تخص المريض المحدد."""
    try:
        gi = await GalleryImage.get(OID(gallery_image_id))
        if not gi:
            raise HTTPException(status_code=404, detail="Gallery image not found")
        
        # Verify it belongs to the patient
        if str(gi.patient_id) != patient_id:
            raise HTTPException(status_code=403, detail="Gallery image does not belong to this patient")
        
        await gi.delete()
        return True
    except Exception as e:
        if isinstance(e, HTTPException):
            raise
        raise HTTPException(status_code=500, detail=f"Failed to delete gallery image: {str(e)}")

async def create_appointment(
    *, patient_id: str, doctor_id: str, scheduled_at: datetime, note: Optional[str], image_path: Optional[str] = None, image_paths: Optional[List[str]] = None
) -> Appointment:
    # Validate ownership
    patient = await Patient.get(OID(patient_id))
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if OID(doctor_id) not in patient.doctor_ids:
        raise HTTPException(status_code=403, detail="Not your patient")

    # للتوافق مع البيانات القديمة: إذا كانت image_paths موجودة، استخدمها، وإلا استخدم image_path
    final_image_paths = image_paths if image_paths is not None else ([image_path] if image_path else [])
    # للتوافق مع البيانات القديمة، احتفظ بأول صورة في image_path
    final_image_path = final_image_paths[0] if final_image_paths else None

    ap = Appointment(
        patient_id=patient.id,
        doctor_id=OID(doctor_id),
        scheduled_at=scheduled_at,
        note=note,
        image_path=final_image_path,
        image_paths=final_image_paths,
    )
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

async def delete_appointment(*, appointment_id: str, patient_id: str) -> bool:
    """حذف موعد للمريض."""
    try:
        appointment = await Appointment.get(OID(appointment_id))
        if not appointment:
            return False
        # التحقق من أن الموعد يخص المريض المحدد
        if str(appointment.patient_id) != patient_id:
            return False
        await appointment.delete()
        return True
    except Exception as e:
        print(f"Error deleting appointment {appointment_id}: {e}")
        return False

async def update_appointment_status(
    *, appointment_id: str, patient_id: str, doctor_id: str, status: str
) -> Appointment | None:
    """تحديث حالة موعد."""
    try:
        appointment = await Appointment.get(OID(appointment_id))
        if not appointment:
            return None
        # التحقق من أن الموعد يخص المريض والطبيب المحددين
        if str(appointment.patient_id) != patient_id:
            return None
        if str(appointment.doctor_id) != doctor_id:
            return None
        # التحقق من أن الطبيب في قائمة أطباء المريض
        patient = await Patient.get(OID(patient_id))
        if patient and OID(doctor_id) not in patient.doctor_ids:
            return None
        # تحديث الحالة
        appointment.status = status.lower()
        await appointment.save()
        return appointment
    except Exception as e:
        print(f"Error updating appointment status {appointment_id}: {e}")
        return None

async def list_patient_appointments_grouped(*, patient_id: str) -> tuple[List[Appointment], List[Appointment]]:
    """Group appointments by doctor. Returns (appointments_for_first_doctor, all_other_appointments)."""
    p = await Patient.get(OID(patient_id))
    if not p:
        return [], []
    apps = await Appointment.find(Appointment.patient_id == p.id).sort("scheduled_at").to_list()
    if not p.doctor_ids:
        return [], apps  # No doctors assigned, return all as "other"
    
    first_doctor_id = p.doctor_ids[0]
    first_doctor_appointments = []
    other_appointments = []
    
    for a in apps:
        if a.doctor_id == first_doctor_id:
            first_doctor_appointments.append(a)
        elif a.doctor_id in p.doctor_ids:
            other_appointments.append(a)
        else:
            # Appointment with doctor not in patient's doctor_ids list
            other_appointments.append(a)
    
    return first_doctor_appointments, other_appointments

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
