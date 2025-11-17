import asyncio
from datetime import datetime, timedelta, timezone
from typing import Iterable
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func

from app.database import async_session
from app.models import Appointment, Patient
from app.services.notification_service import notify_user

WINDOW_MINUTES = 60  # نافذة إرسال 60 دقيقة لتفادي التكرار
SLEEP_SECONDS = 300   # افحص كل 5 دقائق

async def _send_and_mark(session: AsyncSession, ap: Appointment, flag: str, title: str, body: str) -> None:
    """يرسل الإشعار ويضع علامة إرسال على الموعد لعدم التكرار."""
    # Fetch patient's user_id
    pres = await session.execute(select(Patient).where(Patient.id == ap.patient_id))
    patient = pres.scalar_one_or_none()
    if not patient:
        return
    await notify_user(session, user_id=patient.user_id, title=title, body=body)
    setattr(ap, flag, True)

async def check_and_send_reminders(session: AsyncSession) -> None:
    """يفحص المواعيد ويرسل تذكيرات 3 أيام/1 يوم/اليوم نفسه ضمن نافذة زمنية."""
    now = datetime.now(timezone.utc)
    window_end = now + timedelta(minutes=WINDOW_MINUTES)

    # 3 أيام قبل
    target3_start = now + timedelta(days=3)
    target3_end = target3_start + timedelta(minutes=WINDOW_MINUTES)
    res3 = await session.execute(
        select(Appointment)
        .where(
            Appointment.status == "scheduled",
            Appointment.remind_3d_sent.is_(False),
            Appointment.scheduled_at >= target3_start,
            Appointment.scheduled_at < target3_end,
        )
        .order_by(Appointment.scheduled_at)
    )
    apps3 = res3.scalars().all()

    # يوم واحد قبل
    target1_start = now + timedelta(days=1)
    target1_end = target1_start + timedelta(minutes=WINDOW_MINUTES)
    res1 = await session.execute(
        select(Appointment)
        .where(
            Appointment.status == "scheduled",
            Appointment.remind_1d_sent.is_(False),
            Appointment.scheduled_at >= target1_start,
            Appointment.scheduled_at < target1_end,
        )
        .order_by(Appointment.scheduled_at)
    )
    apps1 = res1.scalars().all()

# نفس اليوم: إذا اقترب الموعد خلال أربع ساعات ولم يُرسل تذكير اليوم
    start_today = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end_today = start_today + timedelta(days=1)
    res0 = await session.execute(
        select(Appointment)
        .where(
            Appointment.status == "scheduled",
            Appointment.remind_day_sent.is_(False),
            Appointment.scheduled_at >= start_today,
            Appointment.scheduled_at < end_today,
        )
        .order_by(Appointment.scheduled_at)
    )
    apps0_all = res0.scalars().all()
    apps0 = [a for a in apps0_all if a.scheduled_at - timedelta(hours=4) <= now < a.scheduled_at]

    # إرسال التذكيرات
    for ap in apps3:
        when = ap.scheduled_at.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M")
        await _send_and_mark(session, ap, "remind_3d_sent", "تذكير بالموعد بعد 3 أيام", f"موعدك بتاريخ {when}")
    for ap in apps1:
        when = ap.scheduled_at.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M")
        await _send_and_mark(session, ap, "remind_1d_sent", "تذكير بالموعد غدًا", f"موعدك بتاريخ {when}")
    for ap in apps0:
        when = ap.scheduled_at.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M")
        await _send_and_mark(session, ap, "remind_day_sent", "تذكير موعد اليوم", f"موعدك اليوم الساعة ({when})")

    if apps3 or apps1 or apps0:
        await session.commit()

async def reminder_loop() -> None:
    """حلقة خلفية دورية للتحقق من التذكيرات وتشغيلها كل بضع دقائق."""
    # حلقة خفيفة تعمل داخل العملية تفحص وتُرسل الإشعارات
    while True:
        try:
            async with async_session() as session:
                await check_and_send_reminders(session)
        except Exception as e:
            # لا نكسر الحلقة في حال الخطأ
            print(f"[reminder] error: {e}")
        await asyncio.sleep(SLEEP_SECONDS)
