from app.config import get_settings
from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie

settings = get_settings()

_mongo_client: AsyncIOMotorClient | None = None


async def init_db() -> None:
    """Initialize MongoDB (Beanie) and register document models."""
    global _mongo_client
    _mongo_client = AsyncIOMotorClient(settings.MONGODB_URI)
    db_name = settings.MONGODB_URI.rsplit("/", 1)[-1]
    from app.models import (
        User,
        Doctor,
        Patient,
        Appointment,
        TreatmentNote,
        GalleryImage,
        ChatRoom,
        ChatMessage,
        DeviceToken,
        Notification,
        OTPRequest,
        AssignmentLog,
    )
    await init_beanie(
        database=_mongo_client[db_name],
        document_models=[
            User,
            Doctor,
            Patient,
            Appointment,
            TreatmentNote,
            GalleryImage,
            ChatRoom,
            ChatMessage,
            DeviceToken,
            Notification,
            OTPRequest,
            AssignmentLog,
        ],
    )


async def ping_db() -> bool:
    """Check MongoDB connectivity."""
    if not _mongo_client:
        return False
    try:
        await _mongo_client.admin.command("ping")
        return True
    except Exception:
        return False


# Backward-compatible dependency (unused with Mongo)
async def get_db():
    yield None
