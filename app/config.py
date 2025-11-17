from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import List
import os

class Settings(BaseSettings):
    """Global app settings loaded from environment.
    - Keep defaults light for dev.
    - Override via .env or real env vars.
    """
    APP_NAME: str = "clinic_api"
    APP_ENV: str = "dev"
    APP_DEBUG: bool = True

    MONGODB_URI: str = "mongodb://localhost:27017/clinic"

    JWT_SECRET: str = "change_me_super_secret"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day

    CORS_ORIGINS: List[str] = []

    MEDIA_DIR: str = "media"

    # SMS provider config (dummy | twilio)
    SMS_PROVIDER: str = "dummy"
    TWILIO_ACCOUNT_SID: str | None = None
    TWILIO_AUTH_TOKEN: str | None = None
    TWILIO_FROM_NUMBER: str | None = None

    # Firebase Admin SDK service account
    FIREBASE_CREDENTIALS_FILE: str | None = None

    class Config:
        env_file = ".env"
        case_sensitive = False

    @property
    def cors_origins(self) -> List[str]:
        # Allow comma-separated string in env
        if isinstance(self.CORS_ORIGINS, list):
            return self.CORS_ORIGINS
        raw = os.getenv("CORS_ORIGINS", "")
        return [o.strip() for o in raw.split(",") if o.strip()]

@lru_cache()
def get_settings() -> Settings:
    """Cached settings instance."""
    return Settings()