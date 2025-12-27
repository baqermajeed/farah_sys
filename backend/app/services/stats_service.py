from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, List
from collections import defaultdict

from app.models import (
    User, Patient, Doctor, Appointment, TreatmentNote, GalleryImage,
    ChatRoom, ChatMessage, Notification, DeviceToken, AssignmentLog, OTPRequest
)
from app.constants import Role
from app.utils.logger import get_logger

logger = get_logger("stats_service")


def parse_dates(date_from: Optional[str], date_to: Optional[str]) -> tuple[Optional[datetime], Optional[datetime]]:
    """تحويل سلاسل from/to إلى كائنات datetime إن وُجدت."""
    df = datetime.fromisoformat(date_from.replace('Z', '+00:00')) if date_from else None
    dt = datetime.fromisoformat(date_to.replace('Z', '+00:00')) if date_to else None
    return df, dt


def format_date_group(date: datetime, group: str) -> str:
    """تنسيق التاريخ حسب نوع التجميع."""
    if group == "day":
        return date.strftime("%Y-%m-%d")
    elif group == "month":
        return date.strftime("%Y-%m")
    elif group == "year":
        return date.strftime("%Y")
    else:
        return date.strftime("%Y-%m-%d")


async def get_overview_stats(
    group: str = "day",
    date_from: Optional[str] = None,
    date_to: Optional[str] = None
) -> Dict:
    """ملخص عام شامل: مرضى جدد، مواعيد، سجلات، صور، محادثات، إشعارات."""
    df, dt = parse_dates(date_from, date_to)
    
    # بناء queries
    user_query = User.find(User.role == Role.PATIENT)
    appointment_query = Appointment.find()
    note_query = TreatmentNote.find()
    image_query = GalleryImage.find()
    chat_room_query = ChatRoom.find()
    chat_message_query = ChatMessage.find()
    notification_query = Notification.find()
    
    if df:
        user_query = user_query.find(User.created_at >= df)
        appointment_query = appointment_query.find(Appointment.scheduled_at >= df)
        note_query = note_query.find(TreatmentNote.created_at >= df)
        image_query = image_query.find(GalleryImage.created_at >= df)
        chat_room_query = chat_room_query.find()  # ChatRoom doesn't have created_at
        chat_message_query = chat_message_query.find(ChatMessage.created_at >= df)
        notification_query = notification_query.find(Notification.sent_at >= df)
    
    if dt:
        user_query = user_query.find(User.created_at < dt)
        appointment_query = appointment_query.find(Appointment.scheduled_at < dt)
        note_query = note_query.find(TreatmentNote.created_at < dt)
        image_query = image_query.find(GalleryImage.created_at < dt)
        chat_message_query = chat_message_query.find(ChatMessage.created_at < dt)
        notification_query = notification_query.find(Notification.sent_at < dt)
    
    # جلب البيانات
    users = await user_query.to_list()
    appointments = await appointment_query.to_list()
    notes = await note_query.to_list()
    images = await image_query.to_list()
    chat_messages = await chat_message_query.to_list()
    notifications = await notification_query.to_list()
    
    # تجميع البيانات
    new_patients = defaultdict(int)
    appointments_grouped = defaultdict(int)
    notes_grouped = defaultdict(int)
    images_grouped = defaultdict(int)
    messages_grouped = defaultdict(int)
    notifications_grouped = defaultdict(int)
    
    for user in users:
        period = format_date_group(user.created_at, group)
        new_patients[period] += 1
    
    for app in appointments:
        period = format_date_group(app.scheduled_at, group)
        appointments_grouped[period] += 1
    
    for note in notes:
        period = format_date_group(note.created_at, group)
        notes_grouped[period] += 1
    
    for img in images:
        period = format_date_group(img.created_at, group)
        images_grouped[period] += 1
    
    for msg in chat_messages:
        period = format_date_group(msg.created_at, group)
        messages_grouped[period] += 1
    
    for notif in notifications:
        period = format_date_group(notif.sent_at, group)
        notifications_grouped[period] += 1
    
    return {
        "group": group,
        "range": {"from": date_from, "to": date_to},
        "new_patients": [{"period": k, "count": v} for k, v in sorted(new_patients.items())],
        "appointments": [{"period": k, "count": v} for k, v in sorted(appointments_grouped.items())],
        "notes": [{"period": k, "count": v} for k, v in sorted(notes_grouped.items())],
        "images": [{"period": k, "count": v} for k, v in sorted(images_grouped.items())],
        "chat_messages": [{"period": k, "count": v} for k, v in sorted(messages_grouped.items())],
        "notifications": [{"period": k, "count": v} for k, v in sorted(notifications_grouped.items())],
    }


async def get_users_stats() -> Dict:
    """إحصائيات المستخدمين حسب الدور."""
    total_users = await User.count()
    patients = await User.find(User.role == Role.PATIENT).count()
    doctors = await User.find(User.role == Role.DOCTOR).count()
    receptionists = await User.find(User.role == Role.RECEPTIONIST).count()
    photographers = await User.find(User.role == Role.PHOTOGRAPHER).count()
    admins = await User.find(User.role == Role.ADMIN).count()
    
    return {
        "total_users": total_users,
        "by_role": {
            "patients": patients,
            "doctors": doctors,
            "receptionists": receptionists,
            "photographers": photographers,
            "admins": admins,
        }
    }


async def get_appointments_stats(
    date_from: Optional[str] = None,
    date_to: Optional[str] = None
) -> Dict:
    """إحصائيات المواعيد الشاملة."""
    df, dt = parse_dates(date_from, date_to)
    
    query = Appointment.find()
    if df:
        query = query.find(Appointment.scheduled_at >= df)
    if dt:
        query = query.find(Appointment.scheduled_at < dt)
    
    appointments = await query.to_list()
    
    total = len(appointments)
    by_status = defaultdict(int)
    by_doctor = defaultdict(int)
    
    now = datetime.now(timezone.utc)
    upcoming = 0
    past = 0
    
    for app in appointments:
        by_status[app.status] += 1
        by_doctor[str(app.doctor_id)] += 1
        
        if app.scheduled_at > now and app.status == "scheduled":
            upcoming += 1
        elif app.scheduled_at < now:
            past += 1
    
    return {
        "total": total,
        "by_status": dict(by_status),
        "by_doctor": dict(by_doctor),
        "upcoming": upcoming,
        "past": past,
        "range": {"from": date_from, "to": date_to},
    }


async def get_doctors_stats() -> Dict:
    """إحصائيات الأطباء ومرضاهم."""
    doctors = await Doctor.find().to_list()
    stats = []
    
    for doctor in doctors:
        user = await User.get(doctor.user_id)
        # Count patients where this doctor is in their doctor_ids list
        from beanie.operators import In
        patients = await Patient.find(In(Patient.doctor_ids, [doctor.id])).to_list()
        total_patients = len(patients)
        
        appointments = await Appointment.find(Appointment.doctor_id == doctor.id).count()
        completed = await Appointment.find(
            Appointment.doctor_id == doctor.id,
            Appointment.status == "completed"
        ).count()
        
        notes = await TreatmentNote.find(TreatmentNote.doctor_id == doctor.id).count()
        
        stats.append({
            "doctor_id": str(doctor.id),
            "user_id": str(doctor.user_id),
            "name": user.name if user else None,
            "phone": user.phone if user else None,
            "primary_patients": total_patients,  # For backward compatibility
            "secondary_patients": 0,  # No longer used
            "total_patients": total_patients,
            "total_appointments": appointments,
            "completed_appointments": completed,
            "treatment_notes": notes,
        })
    
    return {"doctors": stats, "total_doctors": len(stats)}


async def get_chat_stats(
    date_from: Optional[str] = None,
    date_to: Optional[str] = None
) -> Dict:
    """إحصائيات المحادثات."""
    df, dt = parse_dates(date_from, date_to)
    
    rooms_query = ChatRoom.find()
    messages_query = ChatMessage.find()
    
    if df:
        messages_query = messages_query.find(ChatMessage.created_at >= df)
    if dt:
        messages_query = messages_query.find(ChatMessage.created_at < dt)
    
    total_rooms = await rooms_query.count()
    total_messages = await messages_query.count()
    
    # إحصائيات حسب الطبيب
    rooms = await rooms_query.to_list()
    messages = await messages_query.to_list()
    
    messages_by_doctor = defaultdict(int)
    rooms_by_doctor = defaultdict(int)
    
    for room in rooms:
        rooms_by_doctor[str(room.doctor_id)] += 1
    
    for msg in messages:
        # نحتاج معرف الطبيب من الغرفة
        room = await ChatRoom.get(msg.room_id)
        if room:
            messages_by_doctor[str(room.doctor_id)] += 1
    
    return {
        "total_rooms": total_rooms,
        "total_messages": total_messages,
        "messages_by_doctor": dict(messages_by_doctor),
        "rooms_by_doctor": dict(rooms_by_doctor),
        "range": {"from": date_from, "to": date_to},
    }


async def get_notifications_stats(
    date_from: Optional[str] = None,
    date_to: Optional[str] = None
) -> Dict:
    """إحصائيات الإشعارات."""
    df, dt = parse_dates(date_from, date_to)
    
    query = Notification.find()
    if df:
        query = query.find(Notification.sent_at >= df)
    if dt:
        query = query.find(Notification.sent_at < dt)
    
    total = await query.count()
    
    # عدد الأجهزة المسجلة
    total_devices = await DeviceToken.find(DeviceToken.active == True).count()
    
    return {
        "total_notifications": total,
        "total_active_devices": total_devices,
        "range": {"from": date_from, "to": date_to},
    }


async def get_transfers_stats(
    group: str = "day",
    date_from: Optional[str] = None,
    date_to: Optional[str] = None
) -> Dict:
    """إحصائيات تحويلات المرضى بين الأطباء."""
    df, dt = parse_dates(date_from, date_to)
    
    query = AssignmentLog.find()
    if df:
        query = query.find(AssignmentLog.assigned_at >= df)
    if dt:
        query = query.find(AssignmentLog.assigned_at < dt)
    
    logs = await query.to_list()
    
    by_period = defaultdict(int)
    by_doctor = defaultdict(int)
    
    for log in logs:
        period = format_date_group(log.assigned_at, group)
        by_period[period] += 1
        by_doctor[str(log.doctor_id)] += 1
    
    return {
        "group": group,
        "range": {"from": date_from, "to": date_to},
        "by_period": [{"period": k, "count": v} for k, v in sorted(by_period.items())],
        "by_doctor": dict(by_doctor),
        "total_transfers": len(logs),
    }


async def get_dashboard_stats() -> Dict:
    """إحصائيات Dashboard شاملة - ملخص سريع."""
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    this_month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    
    # إحصائيات عامة
    total_patients = await User.find(User.role == Role.PATIENT).count()
    total_doctors = await User.find(User.role == Role.DOCTOR).count()
    total_appointments = await Appointment.count()
    upcoming_appointments = await Appointment.find(
        Appointment.scheduled_at > now,
        Appointment.status == "scheduled"
    ).count()
    
    # إحصائيات اليوم
    today_patients = await User.find(
        User.role == Role.PATIENT,
        User.created_at >= today_start
    ).count()
    today_appointments = await Appointment.find(
        Appointment.scheduled_at >= today_start,
        Appointment.scheduled_at < today_start + timedelta(days=1)
    ).count()
    today_messages = await ChatMessage.find(
        ChatMessage.created_at >= today_start
    ).count()
    
    # إحصائيات هذا الشهر
    month_patients = await User.find(
        User.role == Role.PATIENT,
        User.created_at >= this_month_start
    ).count()
    month_appointments = await Appointment.find(
        Appointment.scheduled_at >= this_month_start
    ).count()
    
    # إحصائيات المواعيد حسب الحالة
    scheduled = await Appointment.find(Appointment.status == "scheduled").count()
    completed = await Appointment.find(Appointment.status == "completed").count()
    canceled = await Appointment.find(Appointment.status == "canceled").count()
    
    # إحصائيات المحادثات
    total_chat_rooms = await ChatRoom.count()
    total_chat_messages = await ChatMessage.count()
    
    # إحصائيات الإشعارات
    total_notifications = await Notification.count()
    active_devices = await DeviceToken.find(DeviceToken.active == True).count()
    
    return {
        "overview": {
            "total_patients": total_patients,
            "total_doctors": total_doctors,
            "total_appointments": total_appointments,
            "upcoming_appointments": upcoming_appointments,
        },
        "today": {
            "new_patients": today_patients,
            "appointments": today_appointments,
            "chat_messages": today_messages,
        },
        "this_month": {
            "new_patients": month_patients,
            "appointments": month_appointments,
        },
        "appointments_by_status": {
            "scheduled": scheduled,
            "completed": completed,
            "canceled": canceled,
        },
        "chat": {
            "total_rooms": total_chat_rooms,
            "total_messages": total_chat_messages,
        },
        "notifications": {
            "total_sent": total_notifications,
            "active_devices": active_devices,
        },
    }
