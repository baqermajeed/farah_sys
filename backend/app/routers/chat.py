from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from datetime import datetime, timezone
from beanie import PydanticObjectId as OID
from typing import Optional

from app.security import get_current_user
from app.schemas import ChatMessageOut, ChatMessageIn, ChatListItemOut
from app.models import ChatRoom, ChatMessage, Patient, User, Doctor
from app.constants import Role
from app.utils.r2_clinic import upload_clinic_image

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
        if doctor.id not in patient.doctor_ids:
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
        if not patient.doctor_ids:
            raise HTTPException(status_code=403, detail="No doctor assigned to this patient")
        doctor_id = patient.doctor_ids[0]
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

@router.get("/list", response_model=list[ChatListItemOut])
async def get_chat_list(current: User = Depends(get_current_user)):
    """جلب قائمة المحادثات للطبيب أو المريض مع آخر رسالة وعدد الرسائل غير المقروءة."""
    if current.role == Role.DOCTOR:
        doctor = await Doctor.find_one(Doctor.user_id == current.id)
        if not doctor:
            raise HTTPException(status_code=403, detail="Doctor profile not found")
        
        # جلب جميع غرف المحادثة للطبيب
        rooms = await ChatRoom.find(ChatRoom.doctor_id == doctor.id).to_list()
        
        result = []
        for room in rooms:
            # جلب معلومات المريض
            patient = await Patient.get(room.patient_id)
            if not patient:
                continue
            
            patient_user = await User.get(patient.user_id)
            if not patient_user:
                continue
            
            # جلب آخر رسالة
            last_messages = await ChatMessage.find(
                ChatMessage.room_id == room.id
            ).sort(-ChatMessage.created_at).limit(1).to_list()
            last_message = last_messages[0] if last_messages else None
            
            # جلب عدد الرسائل غير المقروءة (التي أرسلها المريض ولم يقرأها الطبيب)
            unread_count = await ChatMessage.find(
                ChatMessage.room_id == room.id,
                ChatMessage.sender_user_id == patient.user_id,
                ChatMessage.is_read == False
            ).count()
            
            last_message_text = None
            last_message_time = None
            if last_message:
                if last_message.imageUrl:
                    last_message_text = "صورة"
                else:
                    last_message_text = last_message.content
                last_message_time = last_message.created_at.isoformat()
            
            result.append(ChatListItemOut(
                patient_id=str(patient.id),
                patient_name=patient_user.name or patient.phone,
                patient_image_url=patient_user.imageUrl,
                last_message=last_message_text,
                last_message_time=last_message_time,
                unread_count=unread_count,
                room_id=str(room.id)
            ))
        
        # ترتيب حسب آخر رسالة
        result.sort(key=lambda x: x.last_message_time or "", reverse=True)
        return result
    
    elif current.role == Role.PATIENT:
        # جلب معلومات المريض
        patient = await Patient.find_one(Patient.user_id == current.id)
        if not patient:
            raise HTTPException(status_code=404, detail="Patient not found")
        
        # جلب جميع غرف المحادثة للمريض
        rooms = await ChatRoom.find(ChatRoom.patient_id == patient.id).to_list()
        
        result = []
        for room in rooms:
            # جلب معلومات الطبيب
            doctor = await Doctor.get(room.doctor_id)
            if not doctor:
                continue
            
            doctor_user = await User.get(doctor.user_id)
            if not doctor_user:
                continue
            
            # جلب آخر رسالة
            last_messages = await ChatMessage.find(
                ChatMessage.room_id == room.id
            ).sort(-ChatMessage.created_at).limit(1).to_list()
            last_message = last_messages[0] if last_messages else None
            
            # جلب عدد الرسائل غير المقروءة (التي أرسلها الطبيب ولم يقرأها المريض)
            unread_count = await ChatMessage.find(
                ChatMessage.room_id == room.id,
                ChatMessage.sender_user_id == doctor.user_id,
                ChatMessage.is_read == False
            ).count()
            
            last_message_text = None
            last_message_time = None
            if last_message:
                if last_message.imageUrl:
                    last_message_text = "صورة"
                else:
                    last_message_text = last_message.content
                last_message_time = last_message.created_at.isoformat()
            
            result.append(ChatListItemOut(
                patient_id=str(patient.id),
                patient_name=doctor_user.name or doctor.phone,
                patient_image_url=doctor_user.imageUrl,
                last_message=last_message_text,
                last_message_time=last_message_time,
                unread_count=unread_count,
                room_id=str(room.id)
            ))
        
        # ترتيب حسب آخر رسالة
        result.sort(key=lambda x: x.last_message_time or "", reverse=True)
        return result
    
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
            imageUrl=msg.imageUrl,
            is_read=msg.is_read,
            created_at=msg.created_at.isoformat()
        )
        for msg in messages
    ]

@router.post("/{patient_id}/messages", response_model=ChatMessageOut)
async def send_message(
    patient_id: str,
    content: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    current: User = Depends(get_current_user)
):
    """إرسال رسالة جديدة (نصية أو مع صورة)."""
    room = await _get_or_room_for_user(patient_id=patient_id, user=current)
    
    # التحقق من وجود محتوى (نص أو صورة)
    if not content and not image:
        raise HTTPException(status_code=400, detail="يجب أن تحتوي الرسالة على نص أو صورة على الأقل")
    
    # رفع الصورة إذا كانت موجودة
    image_url = None
    if image:
        if image.content_type not in ("image/jpeg", "image/png", "image/webp"):
            raise HTTPException(status_code=400, detail="نوع الملف غير مدعوم. فقط JPEG, PNG, WEBP")
        
        file_bytes = await image.read()
        # استخدام room_id كمعرف فريد لصورة الرسالة
        image_path = await upload_clinic_image(
            patient_id=str(room.id),
            folder="chat_images",
            file_bytes=file_bytes,
            content_type=image.content_type,
        )
        
        # تحويل r2-disabled:// إلى URL عام
        if image_path.startswith("r2-disabled://"):
            key = image_path.replace("r2-disabled://", "")
            image_url = f"/media/{key}"
        else:
            image_url = image_path
    
    # إنشاء الرسالة
    message = ChatMessage(
        room_id=room.id,
        sender_user_id=current.id,
        content=content or "",
        imageUrl=image_url,
        is_read=False
    )
    await message.insert()
    
    # إرسال الرسالة عبر Socket.IO إذا كان متاحاً
    try:
        from app.services.socket_service import emit_message_to_room
        await emit_message_to_room(str(room.id), {
            "id": str(message.id),
            "room_id": str(message.room_id),
            "sender_user_id": str(message.sender_user_id) if message.sender_user_id else None,
            "content": message.content,
            "imageUrl": message.imageUrl,
            "is_read": message.is_read,
            "created_at": message.created_at.isoformat()
        })
    except Exception as e:
        # لا نفشل الطلب إذا فشل Socket.IO
        print(f"⚠️ Failed to emit message via Socket.IO: {e}")
    
    return ChatMessageOut(
        id=str(message.id),
        room_id=str(message.room_id),
        sender_user_id=str(message.sender_user_id) if message.sender_user_id else None,
        content=message.content,
        imageUrl=message.imageUrl,
        is_read=message.is_read,
        created_at=message.created_at.isoformat()
    )

@router.put("/{patient_id}/messages/{message_id}/read", response_model=ChatMessageOut)
async def mark_message_as_read(
    patient_id: str,
    message_id: str,
    current: User = Depends(get_current_user)
):
    """تعليم رسالة كمقروءة."""
    room = await _get_or_room_for_user(patient_id=patient_id, user=current)
    
    try:
        message = await ChatMessage.get(OID(message_id))
    except Exception:
        raise HTTPException(status_code=404, detail="Message not found")
    
    # التحقق من أن الرسالة في نفس الغرفة
    if message.room_id != room.id:
        raise HTTPException(status_code=403, detail="Forbidden")
    
    # تحديث حالة القراءة
    message.is_read = True
    await message.save()
    
    return ChatMessageOut(
        id=str(message.id),
        room_id=str(message.room_id),
        sender_user_id=str(message.sender_user_id) if message.sender_user_id else None,
        content=message.content,
        imageUrl=message.imageUrl,
        is_read=message.is_read,
        created_at=message.created_at.isoformat()
    )
