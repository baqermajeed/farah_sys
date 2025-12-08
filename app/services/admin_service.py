from typing import Optional
from fastapi import HTTPException

from app.models import User, Doctor, Patient
from app.constants import Role
from app.utils.qrcode_gen import ensure_patient_qr

async def create_staff_user(*, phone: str, name: Optional[str], role: Role) -> User:
    """Admin: create a staff user (Doctor/Receptionist/Photographer/Admin)."""
    if role not in {Role.DOCTOR, Role.RECEPTIONIST, Role.PHOTOGRAPHER, Role.ADMIN}:
        raise HTTPException(status_code=400, detail="Invalid role for staff creation")
    if await User.find_one(User.phone == phone):
        raise HTTPException(status_code=400, detail="Phone already exists")

    user = User(phone=phone, name=name, role=role)
    await user.insert()
    if role == Role.DOCTOR:
        await Doctor(user_id=user.id).insert()
    if role == Role.PATIENT:
        from os import urandom

        tmp_qr = f"tmp-{urandom(8).hex()}"
        p = Patient(user_id=user.id, qr_code_data=tmp_qr)
        await p.insert()
        await ensure_patient_qr(p)
    return user


async def create_patient(
    *,
    phone: str,
    name: Optional[str],
    gender: Optional[str],
    age: Optional[int],
    city: Optional[str],
) -> Patient:
    """Create a full patient (User + Patient profile) for reception/admin flows."""
    # تأكد أن رقم الهاتف غير مستخدم
    if await User.find_one(User.phone == phone):
        raise HTTPException(status_code=400, detail="Phone already exists")

    # أنشئ مستخدمًا بدور مريض
    user = User(
        phone=phone,
        name=name,
        role=Role.PATIENT,
        gender=gender,
        age=age,
        city=city,
    )
    await user.insert()

    # أنشئ ملف المريض + QR
    from os import urandom

    tmp_qr = f"tmp-{urandom(8).hex()}"
    patient = Patient(user_id=user.id, qr_code_data=tmp_qr)
    await patient.insert()
    await ensure_patient_qr(patient)
    return patient

async def assign_patient_to_doctors(
    *,
    patient_id: Optional[str],
    primary_doctor_id: Optional[str],
    secondary_doctor_id: Optional[str],
    assigned_by_user_id: Optional[str] = None,
) -> Patient:
    """Admin or Receptionist: wrapper to assign doctors using patient service semantics."""
    from app.services.patient_service import assign_patient_doctors
    return await assign_patient_doctors(
        patient_id=patient_id,
        primary_doctor_id=primary_doctor_id,
        secondary_doctor_id=secondary_doctor_id,
        assigned_by_user_id=assigned_by_user_id,
    )
