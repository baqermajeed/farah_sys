import os
import qrcode
from app.models import Patient
from app.config import get_settings

settings = get_settings()

async def ensure_patient_qr(patient: Patient) -> None:
    """توليد وحفظ QR للمريض إن لم يكن موجودًا وحفظ المسار."""
    if not patient.qr_code_data:
        salt = os.urandom(4).hex()
        # استخدم جزء من معرف المريض لتمييز الكود
        pid = str(patient.id)[-6:]
        patient.qr_code_data = f"P{pid}-{salt}"
    os.makedirs(os.path.join(settings.MEDIA_DIR, "qr"), exist_ok=True)
    img = qrcode.make(patient.qr_code_data)
    rel_path = os.path.join("qr", f"patient_{patient.id}.png")
    abs_path = os.path.join(settings.MEDIA_DIR, rel_path)
    img.save(abs_path)
    patient.qr_image_path = rel_path
    await patient.save()

async def get_patient_by_qr(code: str) -> Patient | None:
    """جلب مريض عبر قيمة qr_code_data."""
    return await Patient.find_one(Patient.qr_code_data == code)
