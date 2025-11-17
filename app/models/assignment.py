from beanie import Document
from beanie import PydanticObjectId as OID
from pydantic import Field
from datetime import datetime, timezone

class AssignmentLog(Document):
    """سجل تحويل/تعيين مريض إلى طبيب."""
    patient_id: OID
    doctor_id: OID
    previous_doctor_id: OID | None = None
    assigned_by_user_id: OID | None = None
    kind: str  # primary | secondary
    assigned_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "assignment_logs"
