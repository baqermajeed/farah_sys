import asyncio
from datetime import datetime, timedelta, timezone
from app.models import Appointment, Patient
from app.services.notification_service import notify_user
from app.utils.logger import get_logger

logger = get_logger("reminder_service")

WINDOW_MINUTES = 60  # نافذة إرسال 60 دقيقة لتفادي التكرار
SLEEP_SECONDS = 300   # افحص كل 5 دقائق

async def _send_and_mark(ap: Appointment, flag: str, title: str, body: str) -> None:
    """يرسل الإشعار ويضع علامة إرسال على الموعد لعدم التكرار."""
    # Fetch patient's user_id
    try:
        patient = await Patient.get(ap.patient_id)
        if not patient:
            return
        await notify_user(user_id=patient.user_id, title=title, body=body)
        setattr(ap, flag, True)
        await ap.save()
    except Exception as e:
        # Log error but don't break the loop
        logger.error(f"Error sending notification for appointment {ap.id}: {e}", exc_info=True)

async def check_and_send_reminders() -> None:
    """يفحص المواعيد ويرسل تذكيرات 3 أيام/1 يوم/اليوم نفسه ضمن نافذة زمنية."""
    now = datetime.now(timezone.utc)

    # 3 أيام قبل
    target3_start = now + timedelta(days=3)
    target3_end = target3_start + timedelta(minutes=WINDOW_MINUTES)
    apps3 = await Appointment.find(
        Appointment.status == "scheduled",
        Appointment.remind_3d_sent == False,
        Appointment.scheduled_at >= target3_start,
        Appointment.scheduled_at < target3_end,
    ).sort(+Appointment.scheduled_at).to_list()

    # يوم واحد قبل
    target1_start = now + timedelta(days=1)
    target1_end = target1_start + timedelta(minutes=WINDOW_MINUTES)
    apps1 = await Appointment.find(
        Appointment.status == "scheduled",
        Appointment.remind_1d_sent == False,
        Appointment.scheduled_at >= target1_start,
        Appointment.scheduled_at < target1_end,
    ).sort(+Appointment.scheduled_at).to_list()

    # نفس اليوم: إذا اقترب الموعد خلال أربع ساعات ولم يُرسل تذكير اليوم
    start_today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end_today = start_today + timedelta(days=1)
    apps0_all = await Appointment.find(
        Appointment.status == "scheduled",
        Appointment.remind_day_sent == False,
        Appointment.scheduled_at >= start_today,
        Appointment.scheduled_at < end_today,
    ).sort(+Appointment.scheduled_at).to_list()
    
    # Filter: المواعيد التي تقع خلال 4 ساعات من الآن
    apps0 = [a for a in apps0_all if a.scheduled_at - timedelta(hours=4) <= now < a.scheduled_at]

    # إرسال التذكيرات
    for ap in apps3:
        when = ap.scheduled_at.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M")
        await _send_and_mark(ap, "remind_3d_sent", "تذكير بالموعد بعد 3 أيام", f"موعدك بتاريخ {when}")
    
    for ap in apps1:
        when = ap.scheduled_at.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M")
        await _send_and_mark(ap, "remind_1d_sent", "تذكير بالموعد غدًا", f"موعدك بتاريخ {when}")
    
    for ap in apps0:
        when = ap.scheduled_at.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M")
        await _send_and_mark(ap, "remind_day_sent", "تذكير موعد اليوم", f"موعدك اليوم الساعة ({when})")

async def reminder_loop() -> None:
    """حلقة خلفية دورية للتحقق من التذكيرات وتشغيلها كل بضع دقائق."""
    # حلقة خفيفة تعمل داخل العملية تفحص وتُرسل الإشعارات
    while True:
        try:
            await check_and_send_reminders()
        except Exception as e:
            # لا نكسر الحلقة في حال الخطأ
            logger.error(f"Error in reminder loop: {e}", exc_info=True)
        await asyncio.sleep(SLEEP_SECONDS)
