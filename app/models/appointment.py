from beanie import Document, Indexed
from beanie import PydanticObjectId as OID
from pydantic import Field
from datetime import datetime, timezone

class Appointment(Document):
    """موعد مريض لدى طبيب."""
    patient_id: Indexed(OID)
    doctor_id: Indexed(OID)
    scheduled_at: Indexed(datetime)
    note: str | None = None
    image_path: str | None = None
    status: Indexed(str) = "scheduled"  # scheduled|completed|canceled|late
    remind_3d_sent: bool = False
    remind_1d_sent: bool = False
    remind_day_sent: bool = False

    class Settings:
        name = "appointments"
