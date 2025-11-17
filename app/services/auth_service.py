import hashlib
import os
from datetime import datetime, timezone, timedelta
from typing import Optional
from fastapi import HTTPException

from app.constants import Role
from app.models import User, Patient, OTPRequest, Doctor
from app.security import create_access_token
from app.utils.sms import send_sms
from app.utils.qrcode_gen import ensure_patient_qr
from beanie import PydanticObjectId as OID

# ---------------- OTP helpers ----------------

def _hash_code(code: str) -> str:
    """Hash OTP code using SHA256; simple and fast."""
    return hashlib.sha256(code.encode()).hexdigest()

async def request_otp(phone: str) -> None:
    """إنشاء وإرسال رمز OTP للهاتف (يحفظ آخر طلب)."""
    code = f"{os.urandom(3).hex()[:6]}"
    code = str(int(int(code, 16) % 1000000)).zfill(6)
    expires = datetime.now(timezone.utc) + timedelta(minutes=5)
    code_hash = _hash_code(code)
    otp = OTPRequest(phone=phone, code_hash=code_hash, expires_at=expires)
    await otp.insert()
    await send_sms(phone, f"رمز التحقق الخاص بك: {code} (صالح لـ 5 دقائق)")

async def verify_otp_and_login(
    *,
    phone: str,
    code: str,
    name: Optional[str] = None,
    gender: Optional[str] = None,
    age: Optional[int] = None,
    city: Optional[str] = None,
) -> tuple[str, User]:
    """Verify OTP; create user if not exists (always as PATIENT). Returns (jwt, user)."""
    now = datetime.now(timezone.utc)
    otp = await OTPRequest.find(OTPRequest.phone == phone).sort(-OTPRequest.created_at).first_or_none()
    if not otp or otp.expires_at < now or otp.code_hash != _hash_code(code):
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    otp.verified_at = now
    await otp.save()

    user = await User.find_one(User.phone == phone)
    if not user:
        user = User(name=name, phone=phone, role=Role.PATIENT, gender=gender, age=age, city=city)
        await user.insert()
        patient = Patient(user_id=user.id, qr_code_data="", qr_image_path=None)
        await patient.insert()
        await ensure_patient_qr(patient)

    token = create_access_token({
        "sub": str(user.id),
        "role": user.role,
        "phone": user.phone,
    })
    return token, user
