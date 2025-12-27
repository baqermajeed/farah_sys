"""
Socket.IO service for real-time chat communication.
"""
import socketio
from typing import Dict, Set, Optional
from beanie import PydanticObjectId as OID
from app.models import User, Patient, Doctor, ChatRoom, ChatMessage
from app.constants import Role
from jose import jwt, JWTError
from app.config import get_settings

settings = get_settings()

# Create Socket.IO server
sio = socketio.AsyncServer(
    cors_allowed_origins="*",
    async_mode='asgi',
    logger=True,
    engineio_logger=True
)

# Store active connections: userId -> Set of socketIds
active_connections: Dict[str, Set[str]] = {}

# Store socket rooms: socketId -> Set of roomIds
socket_rooms: Dict[str, Set[str]] = {}

# Store user data per socket: socketId -> user_data
socket_users: Dict[str, dict] = {}


@sio.on('connect')
async def connect(sid: str, environ: dict, auth: dict):
    """Handle socket connection with authentication."""
    try:
        # Get token from auth or headers
        token = None
        if auth:
            token = auth.get('token')
        if not token and environ:
            auth_header = environ.get('HTTP_AUTHORIZATION', '')
            if auth_header.startswith('Bearer '):
                token = auth_header.replace('Bearer ', '')
        
        if not token:
            print(f"❌ Connection rejected for {sid}: No token")
            await sio.disconnect(sid)
            return False
        
        # Decode JWT
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id_str = payload.get("sub")
        if not user_id_str:
            print(f"❌ Connection rejected for {sid}: No user ID in token")
            await sio.disconnect(sid)
            return False
        
        user_id = OID(user_id_str)
        user = await User.get(user_id)
        if not user:
            print(f"❌ Connection rejected for {sid}: User not found")
            await sio.disconnect(sid)
            return False
        
        # Store user data
        socket_users[sid] = {
            'user_id': str(user.id),
            'user': user,
            'role': payload.get("role")
        }
        
        # Track active connection
        user_id_key = str(user.id)
        if user_id_key not in active_connections:
            active_connections[user_id_key] = set()
        active_connections[user_id_key].add(sid)
        socket_rooms[sid] = set()
        
        # Join user's personal room
        await sio.enter_room(sid, f"user_{user_id_key}")
        
        print(f"✅ User connected: {user_id_key} ({user.name}) - Socket: {sid}")
        return True
    except Exception as e:
        print(f"❌ Connection error for {sid}: {e}")
        await sio.disconnect(sid)
        return False


@sio.on('disconnect')
async def disconnect(sid: str):
    """Handle socket disconnection."""
    # Get user data
    user_data = socket_users.pop(sid, None)
    user_id = user_data.get('user_id') if user_data else None
    
    # Remove from active connections
    if user_id and user_id in active_connections:
        active_connections[user_id].discard(sid)
        if not active_connections[user_id]:
            active_connections.pop(user_id, None)
    
    # Remove socket rooms
    socket_rooms.pop(sid, None)
    
    if user_id:
        print(f"❌ User disconnected: {user_id} - Socket: {sid}")
    else:
        print(f"❌ Socket disconnected: {sid}")


@sio.on('join_conversation')
async def join_conversation(sid: str, data: dict):
    """Join a conversation room."""
    try:
        patient_id = data.get('patient_id')
        if not patient_id:
            await sio.emit('error', {'message': 'معرف المريض مطلوب', 'code': 'E400'}, room=sid)
            return
        
        # Get user from socket
        user_data = socket_users.get(sid)
        if not user_data:
            await sio.emit('error', {'message': 'غير مصرح', 'code': 'E401'}, room=sid)
            return
        
        user_id = user_data['user_id']
        user = user_data['user']
        
        # Get or create room
        try:
            patient = await Patient.get(OID(patient_id))
        except Exception:
            await sio.emit('error', {'message': 'المريض غير موجود', 'code': 'E404'}, room=sid)
            return
        
        room = None
        if user.role == Role.DOCTOR:
            doctor = await Doctor.find_one(Doctor.user_id == user.id)
            if not doctor or doctor.id not in patient.doctor_ids:
                await sio.emit('error', {'message': 'غير مصرح', 'code': 'E403'}, room=sid)
                return
            room = await ChatRoom.find_one(
                ChatRoom.patient_id == patient.id,
                ChatRoom.doctor_id == doctor.id
            )
            if not room:
                room = ChatRoom(patient_id=patient.id, doctor_id=doctor.id)
                await room.insert()
        elif user.role == Role.PATIENT:
            if patient.user_id != user.id:
                await sio.emit('error', {'message': 'غير مصرح', 'code': 'E403'}, room=sid)
                return
            if not patient.doctor_ids:
                await sio.emit('error', {'message': 'لا يوجد طبيب معين', 'code': 'E403'}, room=sid)
                return
            doctor_id = patient.doctor_ids[0]
            room = await ChatRoom.find_one(
                ChatRoom.patient_id == patient.id,
                ChatRoom.doctor_id == doctor_id
            )
            if not room:
                room = ChatRoom(patient_id=patient.id, doctor_id=doctor_id)
                await room.insert()
        else:
            await sio.emit('error', {'message': 'غير مصرح', 'code': 'E403'}, room=sid)
            return
        
        # Join room
        room_key = f"room_{room.id}"
        await sio.enter_room(sid, room_key)
        
        # Track room membership
        if sid in socket_rooms:
            socket_rooms[sid].add(str(room.id))
        
        print(f"👤 User {user_id} joined conversation {room.id}")
        await sio.emit('joined_conversation', {'room_id': str(room.id), 'patient_id': patient_id}, room=sid)
    except Exception as e:
        print(f"❌ Error joining conversation: {e}")
        await sio.emit('error', {'message': f'خطأ في الانضمام للمحادثة: {str(e)}', 'code': 'E500'}, room=sid)


@sio.on('leave_conversation')
async def leave_conversation(sid: str, data: dict):
    """Leave a conversation room."""
    try:
        room_id = data.get('room_id')
        if room_id:
            room_key = f"room_{room_id}"
            await sio.leave_room(sid, room_key)
            
            # Remove from tracking
            if sid in socket_rooms:
                socket_rooms[sid].discard(room_id)
            
            print(f"👋 Socket {sid} left conversation {room_id}")
            await sio.emit('left_conversation', {'room_id': room_id}, room=sid)
    except Exception as e:
        print(f"❌ Error leaving conversation: {e}")


@sio.on('send_message')
async def send_message(sid: str, data: dict):
    """Send a text message."""
    try:
        patient_id = data.get('patient_id')
        content = data.get('content', '').strip()
        image_url = data.get('image_url')
        
        if not patient_id:
            await sio.emit('error', {'message': 'معرف المريض مطلوب', 'code': 'E400'}, room=sid)
            return
        
        if not content and not image_url:
            await sio.emit('error', {'message': 'يجب أن تحتوي الرسالة على نص أو صورة', 'code': 'E400'}, room=sid)
            return
        
        # Get user from socket
        user_data = socket_users.get(sid)
        if not user_data:
            await sio.emit('error', {'message': 'غير مصرح', 'code': 'E401'}, room=sid)
            return
        
        user_id = user_data['user_id']
        user = user_data['user']
        
        # Get or create room (same logic as join_conversation)
        try:
            patient = await Patient.get(OID(patient_id))
        except Exception:
            await sio.emit('error', {'message': 'المريض غير موجود', 'code': 'E404'}, room=sid)
            return
        
        room = None
        if user.role == Role.DOCTOR:
            doctor = await Doctor.find_one(Doctor.user_id == user.id)
            if not doctor or doctor.id not in patient.doctor_ids:
                await sio.emit('error', {'message': 'غير مصرح', 'code': 'E403'}, room=sid)
                return
            room = await ChatRoom.find_one(
                ChatRoom.patient_id == patient.id,
                ChatRoom.doctor_id == doctor.id
            )
            if not room:
                room = ChatRoom(patient_id=patient.id, doctor_id=doctor.id)
                await room.insert()
        elif user.role == Role.PATIENT:
            if patient.user_id != user.id:
                await sio.emit('error', {'message': 'غير مصرح', 'code': 'E403'}, room=sid)
                return
            if not patient.doctor_ids:
                await sio.emit('error', {'message': 'لا يوجد طبيب معين', 'code': 'E403'}, room=sid)
                return
            doctor_id = patient.doctor_ids[0]
            room = await ChatRoom.find_one(
                ChatRoom.patient_id == patient.id,
                ChatRoom.doctor_id == doctor_id
            )
            if not room:
                room = ChatRoom(patient_id=patient.id, doctor_id=doctor_id)
                await room.insert()
        else:
            await sio.emit('error', {'message': 'غير مصرح', 'code': 'E403'}, room=sid)
            return
        
        # Create message
        message = ChatMessage(
            room_id=room.id,
            sender_user_id=user.id,
            content=content or "",
            imageUrl=image_url,
            is_read=False
        )
        await message.insert()
        
        # Broadcast to room
        room_key = f"room_{room.id}"
        message_data = {
            "id": str(message.id),
            "room_id": str(message.room_id),
            "sender_user_id": str(message.sender_user_id) if message.sender_user_id else None,
            "content": message.content,
            "imageUrl": message.imageUrl,
            "is_read": message.is_read,
            "created_at": message.created_at.isoformat()
        }
        
        await sio.emit('message_received', {'message': message_data}, room=room_key)
        await sio.emit('message_sent', {'message': message_data}, room=sid)
        
        print(f"📨 Message sent from {user_id} in room {room.id}")
    except Exception as e:
        print(f"❌ Error sending message: {e}")
        await sio.emit('error', {'message': f'خطأ في إرسال الرسالة: {str(e)}', 'code': 'E500'}, room=sid)


@sio.on('mark_read')
async def mark_read(sid: str, data: dict):
    """Mark messages as read."""
    try:
        room_id = data.get('room_id')
        if not room_id:
            await sio.emit('error', {'message': 'معرف المحادثة مطلوب', 'code': 'E400'}, room=sid)
            return
        
        # Get user from socket
        user_data = socket_users.get(sid)
        if not user_data:
            await sio.emit('error', {'message': 'غير مصرح', 'code': 'E401'}, room=sid)
            return
        
        user_id = user_data['user_id']
        
        # Mark messages as read
        room = await ChatRoom.get(OID(room_id))
        if not room:
            await sio.emit('error', {'message': 'المحادثة غير موجودة', 'code': 'E404'}, room=sid)
            return
        
        # Update unread messages
        from beanie.operators import Set as UpdateSet
        await ChatMessage.find(
            ChatMessage.room_id == room.id,
            ChatMessage.sender_user_id != OID(user_id),
            ChatMessage.is_read == False
        ).update(UpdateSet({"is_read": True}))
        
        await sio.emit('marked_read', {'room_id': room_id}, room=sid)
    except Exception as e:
        print(f"❌ Error marking messages as read: {e}")
        await sio.emit('error', {'message': f'خطأ في تعليم الرسائل كمقروءة: {str(e)}', 'code': 'E500'}, room=sid)


async def emit_message_to_room(room_id: str, message_data: dict):
    """Emit message to a room (called from HTTP endpoints)."""
    try:
        room_key = f"room_{room_id}"
        await sio.emit('message_received', {'message': message_data}, room=room_key)
    except Exception as e:
        print(f"⚠️ Failed to emit message to room {room_id}: {e}")


def get_socket_app():
    """Get Socket.IO ASGI app."""
    return socketio.ASGIApp(sio, socketio_path='socket.io')

