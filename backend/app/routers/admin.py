from fastapi import APIRouter, Depends, HTTPException
from typing import List

from app.schemas import UserOut, PatientOut, PatientCreate, PatientUpdate
from app.security import require_roles, get_current_user
from app.constants import Role
from app.services.admin_service import (
    create_staff_user,
    create_patient,
)
from app.services.patient_service import update_patient_by_admin, delete_patient
from app.models import Patient, Doctor
from app.services import patient_service
from app.schemas import AppointmentOut, NoteOut, GalleryOut
from datetime import datetime, timezone

router = APIRouter(
    prefix="/admin", tags=["admin"], dependencies=[Depends(require_roles([Role.ADMIN]))]
)


@router.post("/staff", response_model=UserOut)
async def create_staff(
    phone: str,
    username: str,
    password: str,
    role: Role,
    name: str | None = None,
):
    """المدير ينشئ حساب موظف (طبيب/موظف استقبال/مصور/مدير) باستخدام username/password."""
    user = await create_staff_user(
        phone=phone,
        username=username,
        password=password,
        name=name,
        role=role,
    )
    # نحوّل الـ ObjectId إلى str يدويًا ليتوافق مع UserOut
    return UserOut(
        id=str(user.id),
        name=user.name,
        phone=user.phone,
        gender=user.gender,
        age=user.age,
        city=user.city,
        role=user.role,
    )

@router.post("/assign", summary="تعيين مريض لأطباء")
async def admin_assign(patient_id: str, doctor_ids: List[str] = [], current=Depends(get_current_user)):
    """تعيين/تحويل المريض إلى قائمة من الأطباء مع تسجيل الحدث."""
    from app.services.patient_service import assign_patient_doctors
    p = await assign_patient_doctors(patient_id=patient_id, doctor_ids=doctor_ids, assigned_by_user_id=str(current.id))
    return {"ok": True, "patient_id": str(p.id), "doctor_ids": [str(did) for did in p.doctor_ids]}

@router.post("/patients", response_model=PatientOut)
async def create_patient_admin(payload: PatientCreate):
    """إنشاء مريض جديد من لوحة المدير مع توليد QR تلقائيًا (MongoDB/Beanie)."""
    # استخدم خدمة create_patient المبنية على Beanie
    p = await create_patient(
        phone=payload.phone,
        name=payload.name,
        gender=payload.gender,
        age=payload.age,
        city=payload.city,
    )
    # جلب بيانات المستخدم المرتبط بالمريض
    from app.models import User

    u = await User.get(p.user_id)
    return PatientOut(
        id=str(p.id),
        user_id=str(p.user_id),
        name=u.name if u else None,
        phone=u.phone if u else "",
        gender=u.gender if u else None,
        age=u.age if u else None,
        city=u.city if u else None,
        treatment_type=p.treatment_type,
        doctor_ids=[str(did) for did in p.doctor_ids],
        qr_code_data=p.qr_code_data,
        qr_image_path=p.qr_image_path,
    )

# تم نقل الإحصائيات إلى /stats router
# هذه endpoints للتوافق مع الإصدارات القديمة
@router.get("/stats")
async def stats():
    """إحصائيات بسيطة: عدد المرضى وإجمالي المرضى لكل طبيب (أساسي فقط).
    ملاحظة: تم نقل الإحصائيات الشاملة إلى /stats/dashboard
    """
    from app.services.stats_service import get_doctors_stats
    stats = await get_doctors_stats()
    return {
        "total_patients": sum(d["total_patients"] for d in stats["doctors"]),
        "per_doctor": [
            {
                "doctor_id": d["doctor_id"],
                "user_id": d["user_id"],
                "patients_primary": d["primary_patients"]
            }
            for d in stats["doctors"]
        ]
    }

@router.patch("/patients/{patient_id}", response_model=PatientOut)
async def update_patient_admin(patient_id: str, payload: PatientUpdate):
    """تعديل بيانات مريض من قبل المدير (يشمل تغيير الهاتف)."""
    p = await update_patient_by_admin(patient_id=patient_id, data=payload)
    from app.models import User
    u = await User.get(p.user_id)
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    return PatientOut(
        id=str(p.id),
        user_id=str(p.user_id),
        name=u.name,
        phone=u.phone,
        gender=u.gender,
        age=u.age,
        city=u.city,
        treatment_type=p.treatment_type,
        doctor_ids=[str(did) for did in p.doctor_ids],
        qr_code_data=p.qr_code_data,
        qr_image_path=p.qr_image_path,
    )

@router.delete("/patients/{patient_id}", status_code=204)
async def delete_patient_admin(patient_id: str):
    """حذف مريض نهائيًا من قبل المدير (يشمل حذف المستخدم وكل متعلقاته)."""
    await delete_patient(actor_role=Role.ADMIN, patient_id=patient_id)
    return None

@router.get("/patients/{patient_id}/appointments", response_model=list[AppointmentOut])
async def admin_patient_appointments(patient_id: str):
    primary, secondary = await patient_service.list_patient_appointments_grouped(patient_id=patient_id)
    all_apps = primary + secondary
    # Need to build AppointmentOut manually with patient_name and doctor_name
    from app.models import User
    import asyncio
    
    async def build_appointment_out(a):
        patient_name = None
        try:
            apt_patient = await Patient.get(a.patient_id)
            if apt_patient:
                user = await User.get(apt_patient.user_id)
                if user:
                    patient_name = user.name
        except Exception:
            pass
        
        doctor_name = None
        try:
            doctor = await Doctor.get(a.doctor_id)
            if doctor:
                user = await User.get(doctor.user_id)
                if user:
                    doctor_name = user.name
        except Exception:
            pass
        
        return AppointmentOut(
            id=str(a.id),
            patient_id=str(a.patient_id),
            patient_name=patient_name,
            doctor_id=str(a.doctor_id),
            doctor_name=doctor_name,
            scheduled_at=a.scheduled_at.isoformat(),
            note=a.note,
            image_path=a.image_path,
            image_paths=a.image_paths or [],
            status=a.status,
        )
    
    return await asyncio.gather(*[build_appointment_out(a) for a in all_apps])

@router.get("/patients/{patient_id}/notes", response_model=list[NoteOut])
async def admin_patient_notes(patient_id: str):
    notes = await patient_service.list_notes_for_patient(patient_id=patient_id)
    return [NoteOut.model_validate(n) for n in notes]

@router.get("/patients/{patient_id}/gallery", response_model=list[GalleryOut])
async def admin_patient_gallery(patient_id: str):
    gallery = await patient_service.list_gallery_for_patient(patient_id=patient_id)
    result = []
    for g in gallery:
        try:
            result.append(
                GalleryOut(
                    id=str(g.id),
                    patient_id=str(g.patient_id),
                    image_path=g.image_path,
                    note=g.note,
                    created_at=g.created_at.isoformat() if g.created_at else datetime.now(timezone.utc).isoformat(),
                )
            )
        except Exception as e:
            # Skip this image if there's an error
            continue
    return result
