from fastapi import APIRouter, Depends, Request
from fastapi.security import OAuth2PasswordRequestForm

from app.rate_limit import limiter
from app.schemas import OTPRequestIn, OTPVerifyIn, Token, UserOut, StaffLoginIn
from app.security import get_current_user
from app.services.auth_service import (
    request_otp,
    verify_otp_and_login,
    staff_login_with_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/request-otp", status_code=204)
@limiter.limit("5/minute")
async def route_request_otp(request: Request, payload: OTPRequestIn):
    """طلب إرسال رمز تحقق (OTP) إلى رقم الهاتف المدخل (للمرضى فقط).
    Rate limit: 5 requests per minute per IP.
    """
    await request_otp(payload.phone)
    return None


@router.post("/verify-otp", response_model=Token)
@limiter.limit("10/minute")
async def route_verify_otp(request: Request, payload: OTPVerifyIn):
    """التحقق من رمز OTP؛ إذا لم يكن لدى الرقم حساب يتم إنشاء حساب مريض افتراضيًا.
    تُرجع JSON Web Token للدخول.
    Rate limit: 10 requests per minute per IP.
    """
    token, user = await verify_otp_and_login(
        phone=payload.phone,
        code=payload.code,
        name=payload.name,
        gender=payload.gender,
        age=payload.age,
        city=payload.city,
    )
    return Token(access_token=token)


@router.post("/staff-login", response_model=Token)
async def route_staff_login(form_data: OAuth2PasswordRequestForm = Depends()):
    """تسجيل دخول الطبيب/الموظف/المصور/المدير باستخدام username/password."""
    token, user = await staff_login_with_password(
        username=form_data.username,
        password=form_data.password,
    )
    return Token(access_token=token)


@router.get("/me", response_model=UserOut)
async def route_me(current=Depends(get_current_user)):
    """معلومات المستخدم الحالي حسب التوكن."""
    return current
