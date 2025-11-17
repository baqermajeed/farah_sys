from fastapi import APIRouter, Depends, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas import GalleryOut, GalleryCreate, PatientOut
from app.database import get_db
from app.security import require_roles, get_current_user
from app.constants import Role
from app.services.patient_service import create_gallery_image
from app.utils.storage import save_upload
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.models import Patient

router = APIRouter(prefix="/photographer", tags=["photographer"], dependencies=[Depends(require_roles([Role.PHOTOGRAPHER]))])

@router.get("/patients", response_model=list[PatientOut])
async def list_patients(db: AsyncSession = Depends(get_db)):
    """قائمة جميع المرضى للمصور بهدف اختيار مريض لإرفاق الصور."""
    res = await db.execute(select(Patient).options(selectinload(Patient.user)))
    out = []
    for p in res.scalars().all():
        u = p.user
        out.append(PatientOut(
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
        ))
    return out

@router.post("/patients/{patient_id}/gallery", response_model=GalleryOut)
async def upload_patient_image(patient_id: str, payload: GalleryCreate, image: UploadFile = File(...), current=Depends(get_current_user)):
    """المصور يرفع صورة للمريض مع ملاحظة اختيارية."""
    image_path = await save_upload(image, subdir="gallery")
    gi = await create_gallery_image(patient_id=patient_id, uploaded_by_user_id=str(current.id), image_path=image_path, note=payload.note)
    return GalleryOut.model_validate(gi)
