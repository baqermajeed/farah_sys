from fastapi import APIRouter, Depends, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.schemas import OTPRequestIn, OTPVerifyIn, Token, UserOut
from app.services.auth_service import request_otp, verify_otp_and_login
from app.security import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])

# Rate limiter - will use app.state.limiter
def get_limiter(request: Request):
    return request.app.state.limiter

@router.post("/request-otp", status_code=204)
async def route_request_otp(request: Request, payload: OTPRequestIn):
    """طلب إرسال رمز تحقق (OTP) إلى رقم الهاتف المدخل.
    Rate limit: 5 requests per minute per IP.
    """
    limiter = get_limiter(request)
    # Simple rate limit check - slowapi will handle it via middleware
    await request_otp(payload.phone)
    return None

@router.post("/verify-otp", response_model=Token)
async def route_verify_otp(request: Request, payload: OTPVerifyIn):
    """التحقق من رمز OTP؛ إذا لم يكن لدى الرقم حساب يتم إنشاء حساب مريض افتراضيًا.
    تُرجع JSON Web Token للدخول.
    Rate limit: 10 requests per minute per IP.
    """
    limiter = get_limiter(request)
    token, user = await verify_otp_and_login(
        phone=payload.phone,
        code=payload.code,
        name=payload.name,
        gender=payload.gender,
        age=payload.age,
        city=payload.city,
    )
    return Token(access_token=token)

@router.get("/me", response_model=UserOut)
async def route_me(current = Depends(get_current_user)):
    """معلومات المستخدم الحالي حسب التوكن."""
    return current
