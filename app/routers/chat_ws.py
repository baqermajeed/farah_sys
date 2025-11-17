from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from beanie import PydanticObjectId as OID

from app.constants import Role
from app.services.chat_service import ConnectionManager
from app.models import ChatRoom, ChatMessage, Patient, User

router = APIRouter(prefix="/ws", tags=["chat"])
manager = ConnectionManager()

async def _ensure_room(*, patient_id: OID, receptionist_user_id: OID) -> ChatRoom:
    """الحصول على أو إنشاء غرفة محادثة بين موظف الاستقبال والمريض."""
    room = await ChatRoom.find_one(
        ChatRoom.patient_id == patient_id,
        ChatRoom.receptionist_user_id == receptionist_user_id
    )
    if room:
        return room
    room = ChatRoom(patient_id=patient_id, receptionist_user_id=receptionist_user_id)
    await room.insert()
    return room

@router.websocket("/chat/{patient_id}")
async def chat_ws(websocket: WebSocket, patient_id: str, token: str = Query("")):
    """قناة محادثة مباشرة بين موظف الاستقبال والمريض عبر WebSocket.
    - المصادقة عبر JWT في كويري بارام 'token'.
    - يتحقق من أن المستخدم هو موظف استقبال أو المريض نفسه.
    """
    # Authenticate
    from jose import jwt, JWTError
    from app.config import get_settings

    settings = get_settings()
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id_str = payload.get("sub")
        if not user_id_str:
            await websocket.close(code=4401)
            return
        user_id = OID(user_id_str)
        role_val = payload.get("role")
        role_str = str(role_val) if role_val else None
    except Exception:
        await websocket.close(code=4401)
        return

    try:
        user = await User.get(user_id)
    except Exception:
        user = None
    
    if not user:
        await websocket.close(code=4401)
        return

    # التحقق من وجود المريض
    try:
        patient = await Patient.get(OID(patient_id))
    except Exception:
        patient = None
    
    if not patient:
        await websocket.close(code=4404)
        return

    # Authorization: موظف استقبال أو المريض نفسه
    room = None
    if role_str == Role.RECEPTIONIST.value:
        # موظف الاستقبال يمكنه المحادثة مع أي مريض
        room = await _ensure_room(patient_id=patient.id, receptionist_user_id=user.id)
        room_key = f"room:{room.id}"
    
    elif role_str == Role.PATIENT.value:
        # المريض يمكنه المحادثة فقط مع موظف الاستقبال
        # التحقق من أن المستخدم هو نفس المريض
        if patient.user_id != user.id:
            await websocket.close(code=4403)
            return
        
        # البحث عن أي غرفة محادثة موجودة لهذا المريض
        room = await ChatRoom.find_one(ChatRoom.patient_id == patient.id)
        if not room:
            # إذا لم توجد غرفة، نبحث عن أي موظف استقبال وننشئ غرفة معه
            receptionist = await User.find_one(User.role == Role.RECEPTIONIST)
            if not receptionist:
                await websocket.close(code=4403, reason="No receptionist available")
                return
            room = await _ensure_room(patient_id=patient.id, receptionist_user_id=receptionist.id)
        room_key = f"room:{room.id}"
    
    else:
        await websocket.close(code=4403)
        return

    await manager.connect(room_key, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            content = str(data.get("message", "")).strip()
            if not content:
                continue
            msg = ChatMessage(room_id=room.id, sender_user_id=user.id, content=content)
            await msg.insert()
            await manager.broadcast(room_key, {
                "sender_id": str(user.id),
                "message": content,
                "room_id": str(room.id)
            })
    except WebSocketDisconnect:
        await manager.disconnect(room_key, websocket)
