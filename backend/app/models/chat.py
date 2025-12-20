from beanie import Document, Indexed
from beanie import PydanticObjectId as OID
from pydantic import Field
from datetime import datetime, timezone

class ChatRoom(Document):
    """غرفة محادثة واحدة لكل زوج (طبيب، مريض)."""
    doctor_id: Indexed(OID)
    patient_id: Indexed(OID)

    class Settings:
        name = "chat_rooms"

class ChatMessage(Document):
    """رسالة دردشة محفوظة."""
    room_id: Indexed(OID)
    sender_user_id: Indexed(OID) | None = None
    content: str
    created_at: Indexed(datetime) = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "chat_messages"
