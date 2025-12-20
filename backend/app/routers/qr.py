from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas import QRScanOut, PatientOut
from app.database import get_db
from app.security import require_roles, get_current_user
from app.constants import Role
from app.utils.qrcode_gen import get_patient_by_qr

router = APIRouter(prefix="/qr", tags=["qr"])

@router.get("/scan", response_model=QRScanOut)
async def scan(code: str, db: AsyncSession = Depends(get_db), current=Depends(require_roles([Role.ADMIN, Role.DOCTOR]))):
    """المسح عبر رمز المريض لإظهار ملفه (للطبيب والمدير فقط)."""
    patient = await get_patient_by_qr(db, code)
    if not patient:
        return {"patient": None}
    u = patient.user
    return {
        "patient": PatientOut(
            id=patient.id,
            user_id=patient.user_id,
            name=u.name,
            phone=u.phone,
            gender=u.gender,
            age=u.age,
            city=u.city,
            treatment_type=patient.treatment_type,
            primary_doctor_id=patient.primary_doctor_id,
            secondary_doctor_id=patient.secondary_doctor_id,
            qr_code_data=patient.qr_code_data,
            qr_image_path=patient.qr_image_path,
        )
    }
