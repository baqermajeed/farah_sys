import os
from typing import Optional, Sequence
from fastapi import UploadFile, HTTPException

from app.config import get_settings

settings = get_settings()

async def save_upload(
    file: UploadFile,
    *,
    subdir: str,
    allowed_content_types: Optional[Sequence[str]] = None,
    max_size_mb: Optional[int] = None,
) -> str:
    """Save uploaded file under MEDIA_DIR/subdir and return relative path.
    - Validates content type and size if provided.
    - Uses chunked write to keep memory low.
    """
    if allowed_content_types and file.content_type not in allowed_content_types:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type. Allowed types: {', '.join(allowed_content_types)}",
        )

    max_bytes = (max_size_mb * 1024 * 1024) if max_size_mb else None
    written_bytes = 0
    dir_path = os.path.join(settings.MEDIA_DIR, subdir)
    os.makedirs(dir_path, exist_ok=True)
    filename = file.filename or "upload.bin"
    # Prefix with a random component to avoid collisions
    rand = os.urandom(4).hex()
    rel_path = os.path.join(subdir, f"{rand}_{filename}")
    abs_path = os.path.join(settings.MEDIA_DIR, rel_path)

    try:
        with open(abs_path, "wb") as f:
            while True:
                chunk = await file.read(1024 * 1024)
                if not chunk:
                    break
                written_bytes += len(chunk)
                if max_bytes and written_bytes > max_bytes:
                    raise HTTPException(
                        status_code=400,
                        detail=f"File too large. Max size is {max_size_mb} MB",
                    )
                f.write(chunk)
    except Exception:
        if os.path.exists(abs_path):
            os.remove(abs_path)
        raise

    return rel_path
