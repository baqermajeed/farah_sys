from fastapi import APIRouter, Depends, HTTPException, Query
from datetime import datetime, timezone
from beanie import PydanticObjectId as OID

from app.security import get_current_user
from app.schemas import ChatMessageOut
from app.models import ChatRoom, ChatMessage, Patient, User, Doctor
from app.constants import Role

router = APIRouter(prefix="/chat", tags=["chat"]) 

async def _get_or_room_for_user(*, patient_id: str, user: User) -> ChatRoom:
    """الحصول على أو إنشاء غرفة محادثة بين الطبيب والمريض."""
    # التحقق من وجود المريض
    try:
        patient = await Patient.get(OID(patient_id))
    except Exception:
        patient = None
    
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    # التحقق من الصلاحيات وإنشاء/الحصول على الغرفة
    if user.role == Role.DOCTOR:
        # الطبيب يمكنه المحادثة مع المرضى المعينين له فقط
        doctor = await Doctor.find_one(Doctor.user_id == user.id)
        if not doctor:
            raise HTTPException(status_code=403, detail="Doctor profile not found")
        
        # التحقق من أن الطبيب معين للمريض (أساسي أو ثانوي)
        if doctor.id not in [patient.primary_doctor_id, patient.secondary_doctor_id]:
            raise HTTPException(status_code=403, detail="Doctor not assigned to this patient")
        
        # البحث عن غرفة محادثة أو إنشاء واحدة جديدة
        room = await ChatRoom.find_one(
            ChatRoom.patient_id == patient.id,
            ChatRoom.doctor_id == doctor.id
        )
        if not room:
            room = ChatRoom(
                patient_id=patient.id,
                doctor_id=doctor.id
            )
            await room.insert()
        return room
    
    elif user.role == Role.PATIENT:
        # المريض يمكنه المحادثة مع طبيبه المعين فقط
        # التحقق من أن المستخدم هو نفس المريض
        if patient.user_id != user.id:
            raise HTTPException(status_code=403, detail="Forbidden")
        
        # استخدام الطبيب الأساسي أو الثانوي
        doctor_id = patient.primary_doctor_id or patient.secondary_doctor_id
        if not doctor_id:
            raise HTTPException(status_code=403, detail="No doctor assigned to this patient")
        
        # البحث عن غرفة محادثة أو إنشاء واحدة جديدة
        room = await ChatRoom.find_one(
            ChatRoom.patient_id == patient.id,
            ChatRoom.doctor_id == doctor_id
        )
        if not room:
            room = ChatRoom(
                patient_id=patient.id,
                doctor_id=doctor_id
            )
            await room.insert()
        return room
    
    else:
        raise HTTPException(status_code=403, detail="Forbidden")

@router.get("/{patient_id}/messages", response_model=list[ChatMessageOut])
async def get_messages(
    patient_id: str, 
    limit: int = 50, 
    before: str | None = Query(None), 
    current: User = Depends(get_current_user)
):
    """استرجاع تاريخ الرسائل (أحدث أولاً) مع دعم before/limit."""
    room = await _get_or_room_for_user(patient_id=patient_id, user=current)
    
    # بناء الاستعلام
    query = ChatMessage.find(ChatMessage.room_id == room.id)
    
    if before:
        try:
            dt = datetime.fromisoformat(before.replace('Z', '+00:00'))
            query = query.find(ChatMessage.created_at < dt)
        except Exception:
            pass
    
    messages = await query.sort(-ChatMessage.created_at).limit(limit).to_list()
    
    return [
        ChatMessageOut(
            id=str(msg.id),
            room_id=str(msg.room_id),
            sender_user_id=str(msg.sender_user_id) if msg.sender_user_id else None,
            content=msg.content,
            created_at=msg.created_at.isoformat()
        )
        for msg in messages
    ]
