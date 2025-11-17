from datetime import datetime
from typing import Optional, Tuple, List, Dict
from sqlalchemy.sql import ColumnElement
from sqlalchemy import func, select, and_

from app.models import User, Appointment, TreatmentNote, GalleryImage, AssignmentLog
from app.constants import Role

# Helpers for grouping by day/month/year using SQLite strftime

FMT = {
    "day": "%Y-%m-%d",
    "month": "%Y-%m",
    "year": "%Y",
}

def group_expr(column, group: str) -> ColumnElement:
    """إرجاع تعبير تجميعي باستخدام strftime حسب نوع التجميع (يوم/شهر/سنة)."""
    fmt = FMT.get(group, "%Y-%m-%d")
    return func.strftime(fmt, column)


def parse_dates(date_from: Optional[str], date_to: Optional[str]) -> Tuple[Optional[datetime], Optional[datetime]]:
    """تحويل سلاسل from/to إلى كائنات datetime إن وُجدت."""
    df = datetime.fromisoformat(date_from) if date_from else None
    dt = datetime.fromisoformat(date_to) if date_to else None
    return df, dt

async def _count_grouped(db, *, column, where_clauses: List = [], group: str = "day", df: Optional[datetime] = None, dt: Optional[datetime] = None):
    """حساب مجمّع لعدد السجلات بحسب الفترة الزمنية مع شروط اختيارية."""
    expr = group_expr(column, group)
    stmt = select(expr.label("period"), func.count().label("count"))
    if where_clauses:
        stmt = stmt.where(and_(*where_clauses))
    if df is not None:
        stmt = stmt.where(column >= df)
    if dt is not None:
        stmt = stmt.where(column < dt)
    stmt = stmt.group_by(expr).order_by(expr)
    res = await db.execute(stmt)
    return [{"period": r[0], "count": r[1]} for r in res.all()]

async def overview(db, *, group: str = "day", date_from: Optional[str] = None, date_to: Optional[str] = None):
    """ملخص عام (مرضى جدد/مواعيد/سجلات/صور) مجمّع يوميًا/شهريًا/سنويًا."""
    df, dt = parse_dates(date_from, date_to)

    new_patients = await _count_grouped(
        db,
        column=User.created_at,
        where_clauses=[User.role == Role.PATIENT],
        group=group,
        df=df,
        dt=dt,
    )
    appointments = await _count_grouped(db, column=Appointment.scheduled_at, group=group, df=df, dt=dt)
    notes = await _count_grouped(db, column=TreatmentNote.created_at, group=group, df=df, dt=dt)
    images = await _count_grouped(db, column=GalleryImage.created_at, group=group, df=df, dt=dt)

    return {
        "group": group,
        "range": {"from": date_from, "to": date_to},
        "new_patients": new_patients,
        "appointments": appointments,
        "notes": notes,
        "images": images,
    }

async def transfers(db, *, group: str = "day", date_from: Optional[str] = None, date_to: Optional[str] = None):
    """عدد تحويلات المرضى لكل طبيب مجمّعة حسب الفترة."""
    df, dt = parse_dates(date_from, date_to)
    expr = group_expr(AssignmentLog.assigned_at, group)
    stmt = select(
        expr.label("period"),
        AssignmentLog.doctor_id,
        func.count().label("count"),
    )
    if df is not None:
        stmt = stmt.where(AssignmentLog.assigned_at >= df)
    if dt is not None:
        stmt = stmt.where(AssignmentLog.assigned_at < dt)
    stmt = stmt.group_by(expr, AssignmentLog.doctor_id).order_by(expr)
    res = await db.execute(stmt)
    rows = res.all()
    series: Dict[int, List[dict]] = {}
    for period, doctor_id, count in rows:
        series.setdefault(doctor_id, []).append({"period": period, "count": count})
    total_by_doctor = {doctor_id: sum(p["count"] for p in points) for doctor_id, points in series.items()}
    return {"group": group, "range": {"from": date_from, "to": date_to}, "series": series, "total_by_doctor": total_by_doctor}
