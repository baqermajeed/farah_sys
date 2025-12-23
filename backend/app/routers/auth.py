from fastapi import APIRouter, Depends, Request
from fastapi.security import OAuth2PasswordRequestForm

from app.rate_limit import limiter
from app.schemas import OTPRequestIn, OTPVerifyIn, Token, UserOut, StaffLoginIn
from app.models.user import User
from app.security import get_current_user
from app.services.auth_service import (
    request_otp,
    verify_otp_and_login,
    staff_login_with_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])

@router.get("/test")
async def test_auth_endpoint():
    """Test endpoint to verify auth router is working"""
    print("✅ [AUTH ROUTER] Test endpoint called - router is working!")
    return {"message": "Auth router is working", "status": "ok"}


@router.post("/request-otp", status_code=204)
@limiter.limit("5/minute")
async def route_request_otp(request: Request, payload: OTPRequestIn):
    """طلب إرسال رمز تحقق (OTP) إلى رقم الهاتف المدخل (للمرضى فقط).
    Rate limit: 5 requests per minute per IP.
    """
    print("=" * 60)
    print("🔐 [AUTH ROUTER] /auth/request-otp endpoint called")
    print(f"   📱 Phone: {payload.phone}")
    print(f"   🌐 Client IP: {request.client.host if request.client else 'unknown'}")
    
    try:
        print("   ⏳ Calling request_otp...")
        await request_otp(payload.phone)
        print("   ✅ OTP requested successfully")
        print("=" * 60)
        return None
    except Exception as e:
        print(f"   ❌ OTP request failed: {e}")
        print(f"   🔴 Error type: {type(e).__name__}")
        import traceback
        print(f"   📋 Traceback: {traceback.format_exc()}")
        print("=" * 60)
        raise


@router.post("/verify-otp", response_model=Token)
@limiter.limit("10/minute")
async def route_verify_otp(request: Request, payload: OTPVerifyIn):
    """التحقق من رمز OTP؛ إذا لم يكن لدى الرقم حساب يتم إنشاء حساب مريض افتراضيًا.
    تُرجع JSON Web Token للدخول.
    Rate limit: 10 requests per minute per IP.
    """
    print("=" * 60)
    print("🔐 [AUTH ROUTER] /auth/verify-otp endpoint called")
    print(f"   📱 Phone: {payload.phone}")
    print(f"   🔑 Code: {payload.code}")
    print(f"   👤 Name: {payload.name}")
    print(f"   🚻 Gender: {payload.gender}")
    print(f"   📅 Age: {payload.age}")
    print(f"   🏙️ City: {payload.city}")
    
    try:
        print("   ⏳ Calling verify_otp_and_login...")
        token, user = await verify_otp_and_login(
            phone=payload.phone,
            code=payload.code,
            name=payload.name,
            gender=payload.gender,
            age=payload.age,
            city=payload.city,
        )
        print("   ✅ OTP verified successfully")
        print(f"   👤 User: {user.name} ({user.role.value})")
        print(f"   🆔 User ID: {user.id}")
        print("=" * 60)
        return Token(access_token=token)
    except Exception as e:
        print(f"   ❌ OTP verification failed: {e}")
        print(f"   🔴 Error type: {type(e).__name__}")
        import traceback
        print(f"   📋 Traceback: {traceback.format_exc()}")
        print("=" * 60)
        raise


@router.post("/staff-login", response_model=Token)
async def route_staff_login(form_data: OAuth2PasswordRequestForm = Depends()):
    """تسجيل دخول الطبيب/الموظف/المصور/المدير باستخدام username/password."""
    print("=" * 60)
    print("🔐 [AUTH ROUTER] /auth/staff-login endpoint called")
    print(f"   👤 Username: {form_data.username}")
    print(f"   🔑 Password: {'*' * len(form_data.password)}")
    print(f"   📝 Form data keys: {form_data.__dict__.keys()}")
    
    try:
        print("   ⏳ Calling staff_login_with_password...")
        token, user = await staff_login_with_password(
            username=form_data.username,
            password=form_data.password,
        )
        print("   ✅ Login successful")
        print(f"   👤 User: {user.name} ({user.role.value})")
        print(f"   🆔 User ID: {user.id}")
        print(f"   🎫 Token generated: {token[:30]}...")
        print("=" * 60)
        return Token(access_token=token)
    except Exception as e:
        print(f"   ❌ Login failed: {e}")
        print(f"   🔴 Error type: {type(e).__name__}")
        import traceback
        print(f"   📋 Traceback: {traceback.format_exc()}")
        print("=" * 60)
        raise


@router.get("/me", response_model=UserOut)
async def route_me(current: User = Depends(get_current_user)):
    """معلومات المستخدم الحالي حسب التوكن.

    نعيد UserOut بشكل صريح مع تحويل ObjectId إلى str لتجنّب
    ResponseValidationError من FastAPI/Pydantic.
    """
    return UserOut(
        id=str(current.id),
        name=current.name,
        phone=current.phone,
        gender=current.gender,
        age=current.age,
        city=current.city,
        role=current.role,
    )
