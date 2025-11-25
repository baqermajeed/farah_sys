from beanie import Document, Indexed
from beanie import PydanticObjectId as OID
from pydantic import Field

class Patient(Document):
    """ملف المريض.
    - روابط للطبيب الأساسي/الثانوي عبر المعرفات.
    - لكل مريض رمز QR ثابت وصورته.
    """
    user_id: Indexed(OID)
    primary_doctor_id: Indexed(OID) | None = None
    secondary_doctor_id: Indexed(OID) | None = None
    treatment_type: str | None = None

    qr_code_data: Indexed(str, unique=True) = ""
    qr_image_path: str | None = None

    class Settings:
        name = "patients"
