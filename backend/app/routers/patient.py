from fastapi import APIRouter, Depends, HTTPException

from app.schemas import PatientOut, PatientAppointmentsOut, AppointmentOut, NoteOut, GalleryOut
from app.security import require_roles, get_current_user
from app.constants import Role
from app.services import patient_service
from app.models import Patient
from app.utils.qrcode_gen import ensure_patient_qr

router = APIRouter(prefix="/patient", tags=["patient"], dependencies=[Depends(require_roles([Role.PATIENT]))])

@router.get("/me", response_model=PatientOut)
async def my_profile(current=Depends(get_current_user)):
    """بيانات حساب المريض، بما فيها الأطباء المعينون والباركود الخاص به."""
    # fetch patient profile by linking from user
    patient = await Patient.find_one(Patient.user_id == current.id)
    if patient and not patient.qr_code_data:
        await ensure_patient_qr(patient)
    u = current
    p = patient
    return PatientOut(
        id=str(p.id),
        user_id=str(p.user_id),
        name=u.name,
        phone=u.phone,
        gender=u.gender,
        age=u.age,
        city=u.city,
        treatment_type=p.treatment_type,
        primary_doctor_id=str(p.primary_doctor_id) if p.primary_doctor_id else None,
        secondary_doctor_id=str(p.secondary_doctor_id) if p.secondary_doctor_id else None,
        qr_code_data=p.qr_code_data,
        qr_image_path=p.qr_image_path,
    )

@router.get("/appointments", response_model=PatientAppointmentsOut)
async def my_appointments(current=Depends(get_current_user)):
    """مواعيدي مقسّمة حسب الطبيب الأساسي والثانوي."""
    # الحصول على ملف المريض المرتبط بهذا المستخدم
    patient = await Patient.find_one(Patient.user_id == current.id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")

    primary, secondary = await patient_service.list_patient_appointments_grouped(
        patient_id=str(patient.id)
    )
    return PatientAppointmentsOut(
        primary=[AppointmentOut.model_validate(a) for a in primary],
        secondary=[AppointmentOut.model_validate(a) for a in secondary],
    )

@router.get("/notes", response_model=list[NoteOut])
async def my_notes(current=Depends(get_current_user)):
    """سجلات علاجي (القسم الأول)."""
    patient = await Patient.find_one(Patient.user_id == current.id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")

    notes = await patient_service.list_notes_for_patient(
        patient_id=str(patient.id)
    )
    return [NoteOut.model_validate(n) for n in notes]

@router.get("/gallery", response_model=list[GalleryOut])
async def my_gallery(current=Depends(get_current_user)):
    """معرض صوري (القسم الثالث)."""
    patient = await Patient.find_one(Patient.user_id == current.id)
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")

    gallery = await patient_service.list_gallery_for_patient(
        patient_id=str(patient.id)
    )
    return [GalleryOut.model_validate(g) for g in gallery]
