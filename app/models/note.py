from beanie import Document
from beanie import PydanticObjectId as OID
from pydantic import Field
from datetime import datetime, timezone

class TreatmentNote(Document):
    """سجل علاجي نصي مع صورة اختيارية."""
    patient_id: OID
    doctor_id: OID
    note: str | None = None
    image_path: str | None = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "treatment_notes"
