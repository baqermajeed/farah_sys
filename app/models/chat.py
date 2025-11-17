from beanie import Document
from beanie import PydanticObjectId as OID
from pydantic import Field
from datetime import datetime, timezone

class ChatRoom(Document):
    """غرفة محادثة واحدة لكل زوج (موظف استقبال، مريض)."""
    receptionist_user_id: OID
    patient_id: OID

    class Settings:
        name = "chat_rooms"

class ChatMessage(Document):
    """رسالة دردشة محفوظة."""
    room_id: OID
    sender_user_id: OID | None = None
    content: str
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "chat_messages"
