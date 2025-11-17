from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from app.constants import Role

# -------------------- Auth / User Schemas --------------------

class UserBase(BaseModel):
    name: Optional[str] = None
    phone: str
    gender: Optional[str] = Field(None, description="male|female")
    age: Optional[int] = None
    city: Optional[str] = None

class UserOut(UserBase):
    id: str
    role: Role

    class Config:
        from_attributes = True

class OTPRequestIn(BaseModel):
    phone: str

class OTPVerifyIn(UserBase):
    """Verify OTP؛ إنشاء مستخدم جديد دائمًا كمريض عند عدم وجوده."""
    code: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

# -------------------- Patient Schemas --------------------

class PatientCreate(BaseModel):
    name: Optional[str] = None
    phone: str
    gender: Optional[str] = None
    age: Optional[int] = None
    city: Optional[str] = None

class PatientOut(BaseModel):
    id: str
    user_id: str
    name: Optional[str]
    phone: str
    gender: Optional[str] = None
    age: Optional[int] = None
    city: Optional[str] = None
    treatment_type: Optional[str] = None
    primary_doctor_id: Optional[int] = None
    secondary_doctor_id: Optional[int] = None
    qr_code_data: str
    qr_image_path: Optional[str] = None

    class Config:
        from_attributes = True

class PatientUpdate(BaseModel):
    name: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    city: Optional[str] = None
    treatment_type: Optional[str] = None
    phone: Optional[str] = None  # Admin only

# -------------------- Doctor Schemas --------------------

class DoctorOut(BaseModel):
    id: str
    user_id: str
    name: Optional[str] = None
    phone: str

    class Config:
        from_attributes = True

# -------------------- Appointments --------------------

class AppointmentCreate(BaseModel):
    patient_id: str
    scheduled_at: str  # ISO datetime
    note: Optional[str] = None

    @field_validator("scheduled_at")
    @classmethod
    def must_include_time(cls, v: str) -> str:
        """يجب أن يحتوي التاريخ على وقت (ساعة:دقيقة). أمثلة مقبولة: 2025-11-01T14:30 أو 2025-11-01 14:30"""
        if not isinstance(v, str):
            raise ValueError("scheduled_at must be ISO string with time")
        sep = "T" if "T" in v else (" " if " " in v else None)
        if sep:
            time_part = v.split(sep, 1)[1]
            if ":" in time_part:
                return v
        raise ValueError("scheduled_at يجب أن يتضمن التاريخ والوقت مثل 2025-11-01T14:30")

class AppointmentOut(BaseModel):
    id: str
    patient_id: str
    doctor_id: str
    scheduled_at: str
    note: Optional[str] = None
    image_path: Optional[str] = None
    status: str

    class Config:
        from_attributes = True

class PatientAppointmentsOut(BaseModel):
    primary: List[AppointmentOut] = []
    secondary: List[AppointmentOut] = []

# -------------------- Notes / Gallery --------------------

class NoteCreate(BaseModel):
    patient_id: str
    note: Optional[str] = None

class NoteOut(BaseModel):
    id: str
    patient_id: str
    doctor_id: str
    note: Optional[str]
    image_path: Optional[str]
    created_at: str

    class Config:
        from_attributes = True

class GalleryCreate(BaseModel):
    patient_id: str
    note: Optional[str] = None

class GalleryOut(BaseModel):
    id: str
    patient_id: str
    image_path: str
    note: Optional[str] = None
    created_at: str

    class Config:
        from_attributes = True

# -------------------- Notifications --------------------

class DeviceTokenIn(BaseModel):
    token: str
    platform: Optional[str] = None

# -------------------- Chat --------------------

class ChatMessageOut(BaseModel):
    id: str
    room_id: str
    sender_user_id: str | None
    content: str
    created_at: str

    class Config:
        from_attributes = True

# -------------------- QR --------------------

class QRScanOut(BaseModel):
    patient: PatientOut | None
