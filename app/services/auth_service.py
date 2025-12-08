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
from app.utils.logger import get_logger
from beanie import PydanticObjectId as OID


# ---------------- OTP helpers ----------------

def _hash_code(code: str) -> str:
    """Hash OTP code using SHA256; simple and fast."""
    return hashlib.sha256(code.encode()).hexdigest()


otp_logger = get_logger("auth.otp")


async def request_otp(phone: str) -> None:
    """إنشاء وإرسال رمز OTP للهاتف (يحفظ آخر طلب)."""
    # Generate OTP (6 digits)
    raw = os.urandom(3).hex()[:6]
    code = str(int(int(raw, 16) % 1000000)).zfill(6)

    # Log code for development (لا تستخدم في الإنتاج الحقيقي)
    otp_logger.info(f"[OTP] code={code} phone={phone}")

    # Expiration
    expires = datetime.now(timezone.utc) + timedelta(minutes=5)
    code_hash = _hash_code(code)

    # Store OTP request
    otp = OTPRequest(phone=phone, code_hash=code_hash, expires_at=expires)
    await otp.insert()

    # Send SMS (dummy for now)
    await send_sms(phone, f"OTP: {code} valid 5 min")


async def verify_otp_and_login(
    *,
    phone: str,
    code: str,
    name: Optional[str] = None,
    gender: Optional[str] = None,
    age: Optional[int] = None,
    city: Optional[str] = None,
) -> tuple[str, User]:
    """Verify OTP; create user if not exists (always PATIENT). Returns (jwt, user)."""
    now = datetime.now(timezone.utc)

    otp = (
        await OTPRequest.find(OTPRequest.phone == phone)
        .sort(-OTPRequest.created_at)
        .first_or_none()
    )

    if not otp:
        raise HTTPException(status_code=400, detail="OTP not found")

    expires_at = otp.expires_at
    if expires_at is not None and expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if expires_at < now or otp.code_hash != _hash_code(code):
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    # Mark as used
    otp.verified_at = now
    await otp.save()

    # Lookup or create user
    user = await User.find_one(User.phone == phone)

    if not user:
        user = User(
            name=name,
            phone=phone,
            role=Role.PATIENT,
            gender=gender,
            age=age,
            city=city,
        )
        await user.insert()
        # qr_code_data is unique, so avoid inserting empty string which may conflict
        from os import urandom

        tmp_qr = f"tmp-{urandom(8).hex()}"
        patient = Patient(user_id=user.id, qr_code_data=tmp_qr, qr_image_path=None)
        await patient.insert()
        await ensure_patient_qr(patient)

    token = create_access_token(
        {
            "sub": str(user.id),
            "role": user.role,
            "phone": user.phone,
        }
    )
    return token, user
