import asyncio
from datetime import datetime
from typing import Optional

import boto3
from fastapi import HTTPException

from app.config import get_settings
from app.utils.logger import get_logger

settings = get_settings()
logger = get_logger("r2")

_r2_client = None


def _get_r2_client():
    """Create (once) and return a boto3 S3 client configured for Cloudflare R2."""
    global _r2_client
    if _r2_client is not None:
        return _r2_client

    if not (
        settings.R2_ACCOUNT_ID
        and settings.R2_ACCESS_KEY_ID
        and settings.R2_SECRET_ACCESS_KEY
        and settings.R2_BUCKET_NAME
        and settings.R2_PUBLIC_BASE
    ):
        raise RuntimeError("R2 storage is not configured. Please set R2_* settings.")

    endpoint_url = f"https://{settings.R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

    _r2_client = boto3.client(
        "s3",
        endpoint_url=endpoint_url,
        aws_access_key_id=settings.R2_ACCESS_KEY_ID,
        aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
        region_name="auto",
    )
    return _r2_client


def _ext_from_content_type(content_type: Optional[str]) -> str:
    if not content_type:
        return ""
    ct = content_type.lower()
    if ct == "image/jpeg" or ct == "image/jpg":
        return ".jpg"
    if ct == "image/png":
        return ".png"
    if ct == "image/webp":
        return ".webp"
    if ct == "image/gif":
        return ".gif"
    return ""


async def upload_clinic_image(
    patient_id: str,
    folder: str,
    file_bytes: bytes,
    content_type: str = "image/jpeg",
) -> str:
    """
    Upload an image to Cloudflare R2 and return its public URL.

    Object key pattern:
        patients/{patient_id}/{folder}/{file_name}
    where file_name is generated from a timestamp for uniqueness.
    """
    if not patient_id:
        raise HTTPException(status_code=400, detail="Missing patient_id for upload")
    if not folder:
        raise HTTPException(status_code=400, detail="Missing folder for upload")
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Empty file")

    ts = datetime.utcnow().strftime("%Y%m%d%H%M%S%f")
    ext = _ext_from_content_type(content_type)
    file_name = f"{ts}{ext}"
    key = f"patients/{patient_id}/{folder}/{file_name}"

    # DEV MODE: R2 موقَّف حاليًا – لا نرفع فعليًا، فقط نرجع رابطًا وهميًا
    logger.warning("R2 upload disabled in dev; skipping upload for key %s", key)
    return f"r2-disabled://{key}"


