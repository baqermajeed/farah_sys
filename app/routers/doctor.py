from fastapi import APIRouter, Depends, UploadFile, File, Query, Form
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from datetime import datetime, timezone

from app.schemas import (
    PatientOut,
    GalleryOut,
    GalleryCreate,
    NoteCreate,
    NoteOut,
    AppointmentCreate,
    AppointmentOut,
    PatientUpdate,
)
from app.database import get_db
from app.security import require_roles, get_current_user
from app.constants import Role
from app.services import patient_service
from app.utils.r2_clinic import upload_clinic_image

IMAGE_TYPES = ("image/jpeg", "image/png", "image/webp")
MAX_IMAGE_MB = 10

router = APIRouter(prefix="/doctor", tags=["doctor"], dependencies=[Depends(require_roles([Role.DOCTOR]))])

@router.get("/patients", response_model=List[PatientOut])
async def my_patients(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current=Depends(get_current_user),
):
    """يعرض المرضى الخاصين بالطبيب (أساسي/ثانوي)."""
    patients = await patient_service.list_doctor_patients(
        str(current.doctor_profile.id), skip=skip, limit=limit
    )
    # Map to PatientOut combining user fields
    out: List[PatientOut] = []
    for p in patients:
        u = p.user
        out.append(PatientOut(
            id=str(p.id), user_id=str(p.user_id), name=u.name, phone=u.phone, gender=u.gender,
            age=u.age, city=u.city, treatment_type=p.treatment_type,
            primary_doctor_id=str(p.primary_doctor_id) if p.primary_doctor_id else None,
            secondary_doctor_id=str(p.secondary_doctor_id) if p.secondary_doctor_id else None,
            qr_code_data=p.qr_code_data, qr_image_path=p.qr_image_path,
        ))
    return out

@router.post("/patients/{patient_id}/treatment", response_model=PatientOut)
async def set_treatment(patient_id: str, treatment_type: str = Query(...), current=Depends(get_current_user)):
    """تحديد نوع العلاج للمريض."""
    p = await patient_service.set_treatment_type(patient_id=patient_id, doctor_id=str(current.doctor_profile.id), treatment_type=treatment_type)
    u = p.user
    return PatientOut(
        id=str(p.id), user_id=str(p.user_id), name=u.name, phone=u.phone, gender=u.gender, age=u.age, city=u.city,
        treatment_type=p.treatment_type, primary_doctor_id=str(p.primary_doctor_id) if p.primary_doctor_id else None, secondary_doctor_id=str(p.secondary_doctor_id) if p.secondary_doctor_id else None,
        qr_code_data=p.qr_code_data, qr_image_path=p.qr_image_path,
    )

@router.post("/patients/{patient_id}/notes", response_model=NoteOut)
async def add_note(patient_id: str, payload: NoteCreate, image: UploadFile | None = File(None), current=Depends(get_current_user)):
    """إضافة سجل (ملاحظة) مع صورة اختيارية."""
    image_path = None
    if image:
        if IMAGE_TYPES and image.content_type not in IMAGE_TYPES:
            from fastapi import HTTPException

            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type. Allowed types: {', '.join(IMAGE_TYPES)}",
            )
        file_bytes = await image.read()
        image_path = await upload_clinic_image(
            patient_id=patient_id,
            folder="notes",
            file_bytes=file_bytes,
            content_type=image.content_type,
        )
    note = await patient_service.create_note(patient_id=patient_id, doctor_id=str(current.doctor_profile.id), note=payload.note, image_path=image_path)
    return NoteOut.model_validate(note)

@router.post("/patients/{patient_id}/appointments", response_model=AppointmentOut)
async def add_appointment(patient_id: str, payload: AppointmentCreate, image: UploadFile | None = File(None), current=Depends(get_current_user)):
    """إضافة موعد جديد مع ملاحظة واختيار صورة (قسم المواعيد)."""
    image_path = None
    if image:
        if IMAGE_TYPES and image.content_type not in IMAGE_TYPES:
            from fastapi import HTTPException

            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file type. Allowed types: {', '.join(IMAGE_TYPES)}",
            )
        file_bytes = await image.read()
        image_path = await upload_clinic_image(
            patient_id=patient_id,
            folder="appointments",
            file_bytes=file_bytes,
            content_type=image.content_type,
        )
    # نضمن وجود timezone؛ إن لم يوجد نفترض UTC
    _sa = datetime.fromisoformat(payload.scheduled_at)
    if _sa.tzinfo is None:
        _sa = _sa.replace(tzinfo=timezone.utc)

    ap = await patient_service.create_appointment(
        patient_id=patient_id,
        doctor_id=str(current.doctor_profile.id),
        scheduled_at=_sa,
        note=payload.note,
        image_path=image_path,
    )
    return AppointmentOut.model_validate(ap)

@router.post("/patients/{patient_id}/gallery", response_model=GalleryOut)
async def add_gallery_image(
    patient_id: str,
    note: str | None = Form(None),
    image: UploadFile = File(...),
    current=Depends(get_current_user),
):
    """رفع صورة إلى معرض المريض (قسم المعرض)."""
    if IMAGE_TYPES and image.content_type not in IMAGE_TYPES:
        from fastapi import HTTPException

        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Allowed types: {', '.join(IMAGE_TYPES)}",
        )
    file_bytes = await image.read()
    image_path = await upload_clinic_image(
        patient_id=patient_id,
        folder="gallery",
        file_bytes=file_bytes,
        content_type=image.content_type,
    )
    gi = await patient_service.create_gallery_image(
        patient_id=patient_id,
        uploaded_by_user_id=str(current.id),
        image_path=image_path,
        note=note,
    )
    return GalleryOut.model_validate(gi)

@router.get("/appointments", response_model=List[AppointmentOut])
async def list_my_appointments(
    day: str | None = None,
    date_from: str | None = None,
    date_to: str | None = None,
    status: str | None = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current=Depends(get_current_user),
):
    """مواعيدي: اليوم/غدًا/الشهر أو نطاق (مع المتأخرون)."""
    df = datetime.fromisoformat(date_from) if date_from else None
    dt = datetime.fromisoformat(date_to) if date_to else None
    apps = await patient_service.list_appointments_for_doctor(
        doctor_id=str(current.doctor_profile.id),
        day=day,
        date_from=df,
        date_to=dt,
        status=status,
        skip=skip,
        limit=limit,
    )
    return [AppointmentOut.model_validate(a) for a in apps]

@router.patch("/patients/{patient_id}", response_model=PatientOut)
async def update_patient(patient_id: int, payload: PatientUpdate, db: AsyncSession = Depends(get_db), current=Depends(get_current_user)):
    """تعديل بيانات مريض من قبل الطبيب (إن كان من مرضاه)."""
    p = await patient_service.update_patient_by_doctor(db, doctor_id=current.doctor_profile.id, patient_id=patient_id, data=payload)
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
async def delete_patient(patient_id: int, db: AsyncSession = Depends(get_db), current=Depends(get_current_user)):
    """حذف مريض من قبل الطبيب (إن كان من مرضاه)."""
    await patient_service.delete_patient(db, actor_role=Role.DOCTOR, patient_id=patient_id, actor_doctor_id=current.doctor_profile.id)
    return None

@router.get("/patients/{patient_id}/notes", response_model=List[NoteOut])
async def list_notes(
    patient_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current=Depends(get_current_user),
):
    """قائمة السجلات للمريض (القسم الأول)."""
    # Authorization ensured in create_note; here we just list
    notes = await patient_service.list_notes_for_patient(
        patient_id=patient_id, skip=skip, limit=limit
    )
    return [NoteOut.model_validate(n) for n in notes]

@router.get("/patients/{patient_id}/gallery", response_model=List[GalleryOut])
async def list_gallery(
    patient_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current=Depends(get_current_user),
):
    """قائمة صور المعرض للمريض (القسم الثالث)."""
    gallery = await patient_service.list_gallery_for_patient(
        patient_id=patient_id, skip=skip, limit=limit
    )
    return [GalleryOut.model_validate(g) for g in gallery]
