from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.schemas import UserOut, PatientOut, PatientCreate, PatientUpdate
from app.database import get_db
from app.security import require_roles, get_current_user
from app.constants import Role
from app.services.admin_service import create_staff_user, assign_patient_to_doctors, create_patient
from app.services.patient_service import update_patient_by_admin, delete_patient
from app.models import Patient, Doctor
from sqlalchemy import func, select
from app.services import patient_service
from app.schemas import AppointmentOut, NoteOut, GalleryOut

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_roles([Role.ADMIN]))])

@router.post("/staff", response_model=UserOut)
async def create_staff(phone: str, role: Role, name: str | None = None, db: AsyncSession = Depends(get_db)):
    """المدير ينشئ حساب موظف (طبيب/موظف استقبال/مصور/مدير)."""
    user = await create_staff_user(db, phone=phone, name=name, role=role)
    return UserOut.model_validate(user)

@router.post("/assign", summary="تعيين مريض لأطباء")
async def admin_assign(patient_id: int, primary_doctor_id: int | None = None, secondary_doctor_id: int | None = None, db: AsyncSession = Depends(get_db), current=Depends(get_current_user)):
    """تعيين/تحويل المريض إلى طبيب أساسي/ثانوي مع تسجيل الحدث."""
    p = await assign_patient_to_doctors(db, patient_id=patient_id, primary_doctor_id=primary_doctor_id, secondary_doctor_id=secondary_doctor_id, assigned_by_user_id=current.id)
    return {"ok": True, "patient_id": p.id, "primary_doctor_id": p.primary_doctor_id, "secondary_doctor_id": p.secondary_doctor_id}

@router.post("/patients", response_model=PatientOut)
async def create_patient_admin(payload: PatientCreate, db: AsyncSession = Depends(get_db)):
    """إنشاء مريض جديد من لوحة المدير مع توليد QR تلقائيًا."""
    p = await create_patient(db, phone=payload.phone, name=payload.name, gender=payload.gender, age=payload.age, city=payload.city)
    # Re-fetch with user eager-loaded
    from sqlalchemy.orm import selectinload
    from sqlalchemy import select as sa_select
    res = await db.execute(sa_select(Patient).options(selectinload(Patient.user)).where(Patient.id == p.id))
    p = res.scalar_one()
    u = p.user
    return PatientOut(
        id=p.id,
        user_id=p.user_id,
        name=u.name,
        phone=u.phone,
        gender=u.gender,
        age=u.age,
        city=u.city,
        treatment_type=p.treatment_type,
        primary_doctor_id=p.primary_doctor_id,
        secondary_doctor_id=p.secondary_doctor_id,
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
async def update_patient_admin(patient_id: int, payload: PatientUpdate, db: AsyncSession = Depends(get_db)):
    """تعديل بيانات مريض من قبل المدير (يشمل تغيير الهاتف)."""
    p = await update_patient_by_admin(db, patient_id=patient_id, data=payload)
    u = p.user
    return PatientOut(
        id=p.id,
        user_id=p.user_id,
        name=u.name,
        phone=u.phone,
        gender=u.gender,
        age=u.age,
        city=u.city,
        treatment_type=p.treatment_type,
        primary_doctor_id=p.primary_doctor_id,
        secondary_doctor_id=p.secondary_doctor_id,
        qr_code_data=p.qr_code_data,
        qr_image_path=p.qr_image_path,
    )

@router.delete("/patients/{patient_id}", status_code=204)
async def delete_patient_admin(patient_id: int, db: AsyncSession = Depends(get_db)):
    """حذف مريض نهائيًا من قبل المدير (يشمل حذف المستخدم وكل متعلقاته)."""
    await delete_patient(db, actor_role=Role.ADMIN, patient_id=patient_id)
    return None

@router.get("/patients/{patient_id}/appointments", response_model=list[AppointmentOut])
async def admin_patient_appointments(patient_id: int, db: AsyncSession = Depends(get_db)):
    primary, secondary = await patient_service.list_patient_appointments_grouped(db, patient_id=patient_id)
    all_apps = primary + secondary
    return [AppointmentOut.model_validate(a) for a in all_apps]

@router.get("/patients/{patient_id}/notes", response_model=list[NoteOut])
async def admin_patient_notes(patient_id: int, db: AsyncSession = Depends(get_db)):
    notes = await patient_service.list_notes_for_patient(db, patient_id=patient_id)
    return [NoteOut.model_validate(n) for n in notes]

@router.get("/patients/{patient_id}/gallery", response_model=list[GalleryOut])
async def admin_patient_gallery(patient_id: int, db: AsyncSession = Depends(get_db)):
    gallery = await patient_service.list_gallery_for_patient(db, patient_id=patient_id)
    return [GalleryOut.model_validate(g) for g in gallery]
