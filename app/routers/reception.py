from fastapi import APIRouter, Depends
from typing import List, Optional
from datetime import datetime

from app.schemas import PatientOut, PatientCreate, AppointmentOut
from app.security import require_roles, get_current_user
from app.constants import Role
from app.models import Patient
from app.services import patient_service
from app.services.admin_service import create_patient
from app.services.admin_service import create_patient

router = APIRouter(prefix="/reception", tags=["reception"], dependencies=[Depends(require_roles([Role.RECEPTIONIST, Role.ADMIN]))])

@router.get("/patients", response_model=List[PatientOut])
async def list_patients():
    """يعرض جميع المرضى مع بياناتهم الأساسية."""
    patients = await Patient.find({}).to_list()
    out: List[PatientOut] = []
    from app.models import User
    for p in patients:
        u = await User.get(p.user_id)
        out.append(PatientOut(
            id=str(p.id),
            user_id=str(p.user_id),
            name=u.name if u else None,
            phone=u.phone if u else "",
            gender=u.gender if u else None,
            age=u.age if u else None,
            city=u.city if u else None,
            treatment_type=p.treatment_type,
            primary_doctor_id=str(p.primary_doctor_id) if p.primary_doctor_id else None,
            secondary_doctor_id=str(p.secondary_doctor_id) if p.secondary_doctor_id else None,
            qr_code_data=p.qr_code_data,
            qr_image_path=p.qr_image_path,
        ))
    return out

@router.post("/assign")
async def assign_patient(patient_id: str, primary_doctor_id: str | None = None, secondary_doctor_id: str | None = None, current=Depends(require_roles([Role.RECEPTIONIST, Role.ADMIN]))):
    """تحويل/تعيين مريض إلى طبيب (أساسي/ثانوي)."""
    from app.services.patient_service import assign_patient_doctors
    p = await assign_patient_doctors(patient_id=patient_id, primary_doctor_id=primary_doctor_id, secondary_doctor_id=secondary_doctor_id, assigned_by_user_id=str(current.id))
    return {"ok": True, "patient_id": str(p.id), "primary_doctor_id": str(p.primary_doctor_id) if p.primary_doctor_id else None, "secondary_doctor_id": str(p.secondary_doctor_id) if p.secondary_doctor_id else None}

@router.post("/patients", response_model=PatientOut)
async def create_patient_reception(payload: PatientCreate):
    """إضافة مريض جديد من قبل موظف الاستقبال."""
    p = await create_patient(phone=payload.phone, name=payload.name, gender=payload.gender, age=payload.age, city=payload.city)
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
        primary_doctor_id=str(p.primary_doctor_id) if p.primary_doctor_id else None,
        secondary_doctor_id=str(p.secondary_doctor_id) if p.secondary_doctor_id else None,
        qr_code_data=p.qr_code_data,
        qr_image_path=p.qr_image_path,
    )

@router.get("/appointments", response_model=List[AppointmentOut])
async def list_appointments(day: str | None = None, date_from: str | None = None, date_to: str | None = None, status: str | None = None):
    """جداول مواعيد جميع المرضى (اليوم/غدًا/نطاق تاريخ)، مع خيار المتأخرون."""
    df = datetime.fromisoformat(date_from) if date_from else None
    dt = datetime.fromisoformat(date_to) if date_to else None
    apps = await patient_service.list_appointments_for_all(day=day, date_from=df, date_to=dt, status=status)
    return [AppointmentOut.model_validate(a) for a in apps]
