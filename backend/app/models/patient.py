from beanie import Document, Indexed
from beanie import PydanticObjectId as OID
from pydantic import Field

class Patient(Document):
    """ملف المريض.
    - روابط للأطباء عبر قائمة المعرفات.
    - لكل مريض رمز QR ثابت وصورته.
    """
    user_id: Indexed(OID)
    doctor_ids: list[OID] = []  # قائمة معرفات الأطباء المرتبطين
    treatment_type: str | None = None

    qr_code_data: Indexed(str, unique=True) = ""
    qr_image_path: str | None = None

    class Settings:
        name = "patients"
