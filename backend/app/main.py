from fastapi import FastAPI, Request, status, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from fastapi.openapi.utils import get_openapi
from starlette.exceptions import HTTPException as StarletteHTTPException
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import get_settings
from app.database import init_db, ping_db
from app.utils.logger import get_logger
from app.rate_limit import limiter

logger = get_logger("main")
settings = get_settings()

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

# FastAPI مع Swagger UI الافتراضي
app = FastAPI(
    title="Dental Clinic API",
    debug=settings.APP_DEBUG,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# 🔐 Enable JWT Bearer Auth in Swagger
app.openapi_schema = None


def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title=app.title,
        version="1.0.0",
        routes=app.routes,
    )

    components = openapi_schema.setdefault("components", {})
    security_schemes = components.setdefault("securitySchemes", {})
    # أضف BearerAuth بدون حذف السكيمات الأخرى (مثل OAuth2PasswordBearer) لضمان التوافق
    security_schemes["BearerAuth"] = {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT",
    }

    for path in openapi_schema.get("paths", {}):
        for method in openapi_schema["paths"][path]:
            operation = openapi_schema["paths"][path][method]
            # إجبار كل العمليات على استخدام BearerAuth حتى يعمل زر Authorize مع التوكن الحالي
            operation["security"] = [{"BearerAuth": []}]

    app.openapi_schema = openapi_schema
    return app.openapi_schema


app.openapi = custom_openapi

# CORS for Flutter/web
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
    logger.warning(f"HTTP {exc.status_code}: {exc.detail} - Path: {request.url.path}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "status_code": exc.status_code}
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.warning(f"Validation error: {exc.errors()} - Path: {request.url.path}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors(), "status_code": 422}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error", "status_code": 500}
    )


# Middleware Logging
@app.middleware("http")
async def log_requests(request: Request, call_next):
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


@app.get("/healthz")
async def healthz():
    return {"status": "ok"}


@app.get("/readyz")
async def readyz():
    if not await ping_db():
        raise HTTPException(status_code=503, detail="Database not ready")
    return {"status": "ok", "database": "up"}


@app.on_event("startup")
async def on_startup():
    logger.info("Starting application...")
    await init_db()
    logger.info("Database initialized")
    # Reminder service disabled to avoid blocking the event loop


@app.on_event("shutdown")
async def on_shutdown():
    logger.info("Shutting down application...")
