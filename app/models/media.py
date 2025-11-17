from beanie import Document
from beanie import PydanticObjectId as OID
from pydantic import Field
from datetime import datetime, timezone

class GalleryImage(Document):
    """صورة مرفوعة للمريض مع ملاحظة اختيارية."""
    patient_id: OID
    uploaded_by_user_id: OID | None = None
    note: str | None = None
    image_path: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "gallery_images"
