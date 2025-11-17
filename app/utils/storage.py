import os
from typing import Optional
from fastapi import UploadFile

from app.config import get_settings

settings = get_settings()

async def save_upload(file: UploadFile, *, subdir: str) -> str:
    """Save uploaded file under MEDIA_DIR/subdir and return relative path.
    - Uses chunked write to keep memory low.
    """
    dir_path = os.path.join(settings.MEDIA_DIR, subdir)
    os.makedirs(dir_path, exist_ok=True)
    filename = file.filename or "upload.bin"
    # Prefix with a random component to avoid collisions
    rand = os.urandom(4).hex()
    rel_path = os.path.join(subdir, f"{rand}_{filename}")
    abs_path = os.path.join(settings.MEDIA_DIR, rel_path)

    with open(abs_path, "wb") as f:
        while True:
            chunk = await file.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
    return rel_path
