from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.database import init_db

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

settings = get_settings()

app = FastAPI(title="Dental Clinic API", debug=settings.APP_DEBUG)

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

@app.get("/healthz")
async def healthz():
    """Liveness probe."""
    return {"status": "ok"}

@app.on_event("startup")
async def on_startup():
    """Initialize database (create tables) and start reminder worker."""
    await init_db()
    # Start background reminder loop
    import asyncio
    from app.services.reminder_service import reminder_loop
    app.state._reminder_task = asyncio.create_task(reminder_loop())

@app.on_event("shutdown")
async def on_shutdown():
    """إيقاف مهام الخلفية بلطف عند إنهاء التطبيق."""
    task = getattr(app.state, "_reminder_task", None)
    if task:
        task.cancel()
