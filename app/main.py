from fastapi import FastAPI, Request, status, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.config import get_settings
from app.database import init_db, ping_db
from app.utils.logger import get_logger

logger = get_logger("main")
settings = get_settings()

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

# Routers
from app.routers import auth as auth_router
from app.routers import doctor as doctor_router
from app.routers import patient as patient_router
from app.routers import reception as reception_router
from app.routers import photographer as photographer_router
from app.routers import admin as admin_router
from app.routers import notifications as notifications_router
from app.routers import qr as qr_router
from app.routers import chat_ws as chat_ws_router
from app.routers import chat as chat_router
from app.routers import stats as stats_router

app = FastAPI(title="Dental Clinic API", debug=settings.APP_DEBUG)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS for Flutter/web
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve media files (images, QR codes)
app.mount("/media", StaticFiles(directory=settings.MEDIA_DIR), name="media")

# Include routers
app.include_router(auth_router.router)
app.include_router(patient_router.router)
app.include_router(doctor_router.router)
app.include_router(reception_router.router)
app.include_router(photographer_router.router)
app.include_router(admin_router.router)
app.include_router(notifications_router.router)
app.include_router(qr_router.router)
app.include_router(chat_ws_router.router)
app.include_router(chat_router.router)
app.include_router(stats_router.router)

# Error handlers
@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Handle HTTP exceptions."""
    logger.warning(f"HTTP {exc.status_code}: {exc.detail} - Path: {request.url.path}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "status_code": exc.status_code}
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors."""
    logger.warning(f"Validation error: {exc.errors()} - Path: {request.url.path}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors(), "status_code": 422}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle all other exceptions."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal server error",
            "status_code": 500
        }
    )

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all requests."""
    import time
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    logger.info(
        f"{request.method} {request.url.path} - "
        f"Status: {response.status_code} - "
        f"Time: {process_time:.3f}s"
    )
    return response

# Apply rate limiting middleware
@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    """Apply rate limiting to auth endpoints."""
    if request.url.path.startswith("/auth/request-otp"):
        limiter = request.app.state.limiter
        try:
            # Check rate limit for OTP requests
            limiter.test_request(request, "5/minute")
        except Exception:
            from slowapi.errors import RateLimitExceeded
            raise RateLimitExceeded("5/minute")
    elif request.url.path.startswith("/auth/verify-otp"):
        limiter = request.app.state.limiter
        try:
            # Check rate limit for verify requests
            limiter.test_request(request, "10/minute")
        except Exception:
            from slowapi.errors import RateLimitExceeded
            raise RateLimitExceeded("10/minute")
    response = await call_next(request)
    return response

@app.get("/healthz")
async def healthz():
    """Liveness probe."""
    return {"status": "ok"}


@app.get("/readyz")
async def readyz():
    """Readiness probe that ensures database connectivity."""
    if not await ping_db():
        raise HTTPException(status_code=503, detail="Database not ready")
    return {"status": "ok", "database": "up"}

@app.on_event("startup")
async def on_startup():
    """Initialize database (create tables) and start reminder worker."""
    logger.info("Starting application...")
    await init_db()
    logger.info("Database initialized")
    # Start background reminder loop
    import asyncio
    from app.services.reminder_service import reminder_loop
    app.state._reminder_task = asyncio.create_task(reminder_loop())
    logger.info("Reminder service started")

@app.on_event("shutdown")
async def on_shutdown():
    """إيقاف مهام الخلفية بلطف عند إنهاء التطبيق."""
    logger.info("Shutting down application...")
    task = getattr(app.state, "_reminder_task", None)
    if task:
        task.cancel()
        logger.info("Reminder service stopped")
