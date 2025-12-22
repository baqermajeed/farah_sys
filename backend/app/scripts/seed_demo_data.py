"""
سكريبت لإضافة بيانات تجريبية شاملة للنظام
يُنشئ: مستخدمين، مرضى، مواعيد، سجلات علاجية
"""
import asyncio
from datetime import datetime, timedelta, timezone

from app.config import get_settings
from app.database import init_db
from app.constants import Role
from app.models import User, Patient, Doctor, Appointment, TreatmentNote
from app.services.admin_service import create_staff_user, create_patient, assign_patient_to_doctors
from app.services.patient_service import create_note, create_appointment, set_treatment_type


async def create_demo_users():
    """إنشاء المستخدمين الأساسيين (Admin, Doctor, Receptionist)"""
    print("\n=== إنشاء المستخدمين ===")
    
    # Admin
    admin = await create_staff_user(
        phone="07700000001",
        username="admin",
        password="admin123",
        name="مدير النظام",
        role=Role.ADMIN,
    )
    print(f"✓ تم إنشاء المدير: {admin.name} ({admin.username})")
    
    # Doctor
    doctor = await create_staff_user(
        phone="07700000000",
        username="baqer121",
        password="12345",
        name="د. باقر",
        role=Role.DOCTOR,
    )
    print(f"✓ تم إنشاء الطبيب: {doctor.name} ({doctor.username})")
    
    # Receptionist
    reception = await create_staff_user(
        phone="07700000002",
        username="reception1",
        password="12345",
        name="موظف الاستقبال",
        role=Role.RECEPTIONIST,
    )
    print(f"✓ تم إنشاء موظف الاستقبال: {reception.name} ({reception.username})")
    
    return admin, doctor, reception


async def create_demo_patients():
    """إنشاء مرضى تجريبيين"""
    print("\n=== إنشاء المرضى ===")
    
    patients_data = [
        {
            "phone": "07701234567",
            "name": "أحمد محمد",
            "gender": "male",
            "age": 35,
            "city": "بغداد",
        },
        {
            "phone": "07701234568",
            "name": "فاطمة علي",
            "gender": "female",
            "age": 28,
            "city": "البصرة",
        },
        {
            "phone": "07701234569",
            "name": "حسن كريم",
            "gender": "male",
            "age": 42,
            "city": "بغداد",
        },
        {
            "phone": "07701234570",
            "name": "زينب أحمد",
            "gender": "female",
            "age": 25,
            "city": "الموصل",
        },
        {
            "phone": "07701234571",
            "name": "علي محمود",
            "gender": "male",
            "age": 50,
            "city": "بغداد",
        },
    ]
    
    patients = []
    for data in patients_data:
        try:
            patient = await create_patient(**data)
            patients.append(patient)
            user = await User.get(patient.user_id)
            print(f"✓ تم إنشاء المريض: {user.name} ({user.phone})")
        except Exception as e:
            print(f"✗ فشل إنشاء المريض {data['name']}: {e}")
    
    return patients


async def assign_patients_to_doctor(patients, doctor_user):
    """ربط المرضى بالطبيب"""
    print("\n=== ربط المرضى بالطبيب ===")
    
    # الحصول على ملف الطبيب
    doctor = await Doctor.find_one(Doctor.user_id == doctor_user.id)
    if not doctor:
        print("✗ لم يتم العثور على ملف الطبيب")
        return
    
    doctor_id = str(doctor.id)
    
    # ربط المرضى بالطبيب الأساسي
    for patient in patients:
        try:
            await assign_patient_to_doctors(
                patient_id=str(patient.id),
                primary_doctor_id=doctor_id,
                secondary_doctor_id=None,
                assigned_by_user_id=str(doctor_user.id),
            )
            user = await User.get(patient.user_id)
            print(f"✓ تم ربط المريض {user.name} بالطبيب {doctor_user.name}")
        except Exception as e:
            print(f"✗ فشل ربط المريض: {e}")


async def create_demo_appointments(patients, doctor_user):
    """إنشاء مواعيد تجريبية"""
    print("\n=== إنشاء المواعيد ===")
    
    doctor = await Doctor.find_one(Doctor.user_id == doctor_user.id)
    if not doctor:
        print("✗ لم يتم العثور على ملف الطبيب")
        return
    
    doctor_id = str(doctor.id)
    now = datetime.now(timezone.utc)
    
    # مواعيد مختلفة (ماضية، اليوم، غداً، مستقبلية)
    appointments_data = [
        {
            "patient": patients[0] if len(patients) > 0 else None,
            "scheduled_at": now - timedelta(days=5, hours=2),
            "note": "فحص دوري - تم بنجاح",
            "status": "completed",
        },
        {
            "patient": patients[0] if len(patients) > 0 else None,
            "scheduled_at": now + timedelta(days=2, hours=10),
            "note": "موعد متابعة العلاج",
            "status": "scheduled",
        },
        {
            "patient": patients[1] if len(patients) > 1 else None,
            "scheduled_at": now + timedelta(hours=3),
            "note": "تنظيف أسنان",
            "status": "scheduled",
        },
        {
            "patient": patients[1] if len(patients) > 1 else None,
            "scheduled_at": now + timedelta(days=1, hours=14),
            "note": "موعد متابعة",
            "status": "scheduled",
        },
        {
            "patient": patients[2] if len(patients) > 2 else None,
            "scheduled_at": now + timedelta(days=7, hours=11),
            "note": "فحص شامل",
            "status": "scheduled",
        },
        {
            "patient": patients[3] if len(patients) > 3 else None,
            "scheduled_at": now - timedelta(days=2),
            "note": "علاج جذور - مكتمل",
            "status": "completed",
        },
    ]
    
    for apt_data in appointments_data:
        if not apt_data["patient"]:
            continue
            
        try:
            appointment = await create_appointment(
                patient_id=str(apt_data["patient"].id),
                doctor_id=doctor_id,
                scheduled_at=apt_data["scheduled_at"],
                note=apt_data["note"],
                image_path=None,
            )
            
            # تحديث حالة الموعد
            appointment.status = apt_data["status"]
            await appointment.save()
            
            user = await User.get(apt_data["patient"].user_id)
            print(f"✓ تم إنشاء موعد للمريض {user.name} في {apt_data['scheduled_at']}")
        except Exception as e:
            print(f"✗ فشل إنشاء الموعد: {e}")


async def create_demo_treatment_notes(patients, doctor_user):
    """إنشاء سجلات علاجية تجريبية"""
    print("\n=== إنشاء السجلات العلاجية ===")
    
    doctor = await Doctor.find_one(Doctor.user_id == doctor_user.id)
    if not doctor:
        print("✗ لم يتم العثور على ملف الطبيب")
        return
    
    doctor_id = str(doctor.id)
    
    notes_data = [
        {
            "patient": patients[0] if len(patients) > 0 else None,
            "note": "فحص شامل - الأسنان في حالة جيدة. يوصى بتنظيف دوري كل 6 أشهر.",
        },
        {
            "patient": patients[0] if len(patients) > 0 else None,
            "note": "علاج تجويف في الضرس العلوي الأيمن. تم الحشو بنجاح.",
        },
        {
            "patient": patients[1] if len(patients) > 1 else None,
            "note": "تنظيف أسنان احترافي. إزالة الجير والترسبات.",
        },
        {
            "patient": patients[2] if len(patients) > 2 else None,
            "note": "فحص أولي - يحتاج المريض إلى تقويم أسنان. تم شرح الخيارات المتاحة.",
        },
        {
            "patient": patients[3] if len(patients) > 3 else None,
            "note": "علاج جذور للضرس السفلي الأيسر. تم بنجاح.",
        },
    ]
    
    for note_data in notes_data:
        if not note_data["patient"]:
            continue
            
        try:
            note = await create_note(
                patient_id=str(note_data["patient"].id),
                doctor_id=doctor_id,
                note=note_data["note"],
                image_path=None,
            )
            
            user = await User.get(note_data["patient"].user_id)
            print(f"✓ تم إنشاء سجل علاجي للمريض {user.name}")
        except Exception as e:
            print(f"✗ فشل إنشاء السجل العلاجي: {e}")


async def set_treatment_types(patients):
    """تعيين أنواع العلاج للمرضى"""
    print("\n=== تعيين أنواع العلاج ===")
    
    if not patients:
        return
    
    doctor = await Doctor.find_one()
    if not doctor:
        return
    
    doctor_id = str(doctor.id)
    treatment_types = [
        "تنظيف أسنان",
        "علاج جذور",
        "تقويم أسنان",
        "زراعة أسنان",
        "حشو أسنان",
    ]
    
    for i, patient in enumerate(patients[:len(treatment_types)]):
        try:
            await set_treatment_type(
                patient_id=str(patient.id),
                doctor_id=doctor_id,
                treatment_type=treatment_types[i],
            )
            user = await User.get(patient.user_id)
            print(f"✓ تم تعيين نوع العلاج '{treatment_types[i]}' للمريض {user.name}")
        except Exception as e:
            print(f"✗ فشل تعيين نوع العلاج: {e}")


async def main():
    """الدالة الرئيسية"""
    print("=" * 50)
    print("بدء إنشاء البيانات التجريبية")
    print("=" * 50)
    
    settings = get_settings()
    print(f"\nMongoDB URI: {settings.MONGODB_URI}")
    
    # تهيئة الاتصال بقاعدة البيانات
    await init_db()
    print("✓ تم الاتصال بقاعدة البيانات\n")
    
    try:
        # 1. إنشاء المستخدمين
        admin, doctor, reception = await create_demo_users()
        
        # 2. إنشاء المرضى
        patients = await create_demo_patients()
        
        # 3. ربط المرضى بالطبيب
        await assign_patients_to_doctor(patients, doctor)
        
        # 4. تعيين أنواع العلاج
        await set_treatment_types(patients)
        
        # 5. إنشاء المواعيد
        await create_demo_appointments(patients, doctor)
        
        # 6. إنشاء السجلات العلاجية
        await create_demo_treatment_notes(patients, doctor)
        
        print("\n" + "=" * 50)
        print("✓ تم إنشاء البيانات التجريبية بنجاح!")
        print("=" * 50)
        print("\nبيانات تسجيل الدخول:")
        print(f"  المدير: username=admin, password=admin123")
        print(f"  الطبيب: username=baqer121, password=12345")
        print(f"  الاستقبال: username=reception1, password=12345")
        print(f"\nأرقام المرضى (لاختبار OTP):")
        for i, patient in enumerate(patients[:5], 1):
            user = await User.get(patient.user_id)
            print(f"  {i}. {user.name}: {user.phone}")
        print("\n" + "=" * 50)
        
    except Exception as e:
        print(f"\n✗ حدث خطأ: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())

