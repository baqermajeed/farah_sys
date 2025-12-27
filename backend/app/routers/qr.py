from fastapi import APIRouter, Depends

from app.schemas import QRScanOut, PatientOut
from app.security import require_roles, get_current_user
from app.constants import Role

router = APIRouter(prefix="/qr", tags=["qr"])

@router.get("/scan", response_model=QRScanOut)
async def scan(code: str, current=Depends(require_roles([Role.ADMIN, Role.DOCTOR]))):
    """المسح عبر رمز المريض لإظهار ملفه (للطبيب والمدير فقط)."""
    from app.models import Patient
    from beanie import PydanticObjectId as OID
    patient = await Patient.find_one(Patient.qr_code_data == code)
    if not patient:
        return {"patient": None}
    from app.models import User
    u = await User.get(patient.user_id)
    if not u:
        return {"patient": None}
    return {
        "patient": PatientOut(
            id=str(patient.id),
            user_id=str(patient.user_id),
            name=u.name,
            phone=u.phone,
            gender=u.gender,
            age=u.age,
            city=u.city,
            treatment_type=patient.treatment_type,
            doctor_ids=[str(did) for did in patient.doctor_ids],
            qr_code_data=patient.qr_code_data,
            qr_image_path=patient.qr_image_path,
            imageUrl=u.imageUrl,
        )
    }
