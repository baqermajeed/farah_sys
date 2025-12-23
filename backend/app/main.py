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
# Reset OpenAPI schema to force regeneration
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
print("📋 [STARTUP] Registering routers...")
app.include_router(auth_router.router)
print("   ✅ Auth router registered at /auth")
app.include_router(patient_router.router)
print("   ✅ Patient router registered")
app.include_router(doctor_router.router)
print("   ✅ Doctor router registered")
app.include_router(reception_router.router)
print("   ✅ Reception router registered")
app.include_router(photographer_router.router)
print("   ✅ Photographer router registered")
app.include_router(admin_router.router)
print("   ✅ Admin router registered")
app.include_router(notifications_router.router)
print("   ✅ Notifications router registered")
app.include_router(qr_router.router)
print("   ✅ QR router registered")
app.include_router(chat_ws_router.router)
print("   ✅ Chat WS router registered")
app.include_router(chat_router.router)
print("   ✅ Chat router registered")
app.include_router(stats_router.router)
print("   ✅ Stats router registered")
print("✅ [STARTUP] All routers registered successfully!")
print(f"   📍 Auth endpoints available at: /auth/*")
print(f"   🔗 Test endpoint: http://localhost:8000/auth/test")
print(f"   🔗 Staff login: http://localhost:8000/auth/staff-login")


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
    
    # Log request details - ALWAYS log to debug 404 issues
    print(f"\n{'='*60}")
    print(f"📥 [REQUEST] {request.method} {request.url.path}")
    print(f"   🌐 Full URL: {request.url}")
    print(f"   🌍 Client: {request.client.host if request.client else 'unknown'}:{request.client.port if request.client else 'unknown'}")
    print(f"   📋 Query params: {dict(request.query_params)}")
    print(f"   📋 Path: {request.url.path}")
    # Log available routes for debugging
    try:
        route_paths = []
        for route in app.routes:
            if hasattr(route, 'path'):
                route_paths.append(route.path)
            elif hasattr(route, 'path_regex'):
                route_paths.append(str(route.path_regex))
        print(f"   📋 Available routes ({len(route_paths)}): {route_paths[:10]}...")  # Show first 10
    except Exception as e:
        print(f"   ⚠️ Could not list routes: {e}")
    if request.headers:
        auth_header = request.headers.get("authorization")
        if auth_header:
            print(f"   🔐 Authorization: {auth_header[:30]}...")
        content_type = request.headers.get("content-type")
        if content_type:
            print(f"   📄 Content-Type: {content_type}")
    
    response = await call_next(request)
    process_time = time.time() - start_time
    
    # Log response details
    print(f"📤 [RESPONSE] Status: {response.status_code} | Time: {process_time:.3f}s")
    if response.status_code == 404:
        print(f"   ⚠️  404 Not Found - Path: {request.url.path}")
        print(f"   🔍 Method: {request.method}")
        print(f"   🔍 Full URL: {request.url}")
        # List all routes for debugging
        all_routes = []
        for route in app.routes:
            if hasattr(route, 'path'):
                methods = getattr(route, 'methods', set())
                all_routes.append(f"{', '.join(methods)} {route.path}")
        print(f"   🔍 Total routes: {len(all_routes)}")
        # Show auth routes
        auth_routes = [r for r in all_routes if '/auth' in r]
        if auth_routes:
            print(f"   🔍 Auth routes ({len(auth_routes)}):")
            for route in auth_routes[:15]:  # Show first 15
                print(f"      - {route}")
        else:
            print(f"   🔍 No /auth routes found!")
    print(f"{'='*60}\n")
    
    logger.info(
        f"{request.method} {request.url.path} - "
        f"Status: {response.status_code} - "
        f"Time: {process_time:.3f}s"
    )
    return response


@app.get("/healthz")
async def healthz():
    print("💚 [HEALTH CHECK] /healthz endpoint called")
    return {"status": "ok"}


@app.get("/readyz")
async def readyz():
    if not await ping_db():
        raise HTTPException(status_code=503, detail="Database not ready")
    return {"status": "ok", "database": "up"}


@app.on_event("startup")
async def on_startup():
    import socket
    hostname = socket.gethostname()
    try:
        # Get local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except:
        local_ip = "unknown"
    
    print("=" * 60)
    print("🚀 [STARTUP] Starting application...")
    print(f"   📍 Hostname: {hostname}")
    print(f"   🌐 Local IP: {local_ip}")
    print(f"   📍 App running at: http://0.0.0.0:8000")
    print(f"   📖 Swagger UI (localhost): http://localhost:8000/docs")
    print(f"   📖 Swagger UI (network): http://{local_ip}:8000/docs")
    print(f"   💚 Health check: http://{local_ip}:8000/healthz")
    print(f"   🔐 Staff login: http://{local_ip}:8000/auth/staff-login")
    print("=" * 60)
    logger.info("Starting application...")
    await init_db()
    logger.info("Database initialized")
    print("✅ [STARTUP] Database initialized")
    print("✅ [STARTUP] Application ready!")
    print("=" * 60)
    # Reminder service disabled to avoid blocking the event loop


@app.on_event("shutdown")
async def on_shutdown():
    logger.info("Shutting down application...")
