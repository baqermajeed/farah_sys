from beanie import Document, Indexed
from pydantic import Field
from datetime import datetime, timezone
from app.constants import Role

class User(Document):
    """مستخدم النظام (مريض/طبيب/مدير/استقبال/مصور)."""
    name: str | None = None
    phone: Indexed(str, unique=True)  # فريد
    role: Role
    gender: str | None = None  # "male" | "female"
    age: int | None = None
    city: str | None = None

    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    class Settings:
        name = "users"
