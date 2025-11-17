from beanie import Document, Indexed
from beanie import PydanticObjectId as OID
from pydantic import Field
from datetime import datetime, timezone

class Appointment(Document):
    """موعد مريض لدى طبيب."""
    patient_id: OID
    doctor_id: OID
    scheduled_at: datetime
    note: str | None = None
    image_path: str | None = None
    status: str = "scheduled"  # scheduled|completed|canceled|late
    remind_3d_sent: bool = False
    remind_1d_sent: bool = False
    remind_day_sent: bool = False

    class Settings:
        name = "appointments"
