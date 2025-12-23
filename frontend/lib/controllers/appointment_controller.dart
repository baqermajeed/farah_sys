import 'package:get/get.dart';
import 'package:farah_sys_final/models/appointment_model.dart';
import 'package:farah_sys_final/services/patient_service.dart';
import 'package:farah_sys_final/services/doctor_service.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class AppointmentController extends GetxController {
  final _patientService = PatientService();
  final _doctorService = DoctorService();

  final RxList<AppointmentModel> appointments = <AppointmentModel>[].obs;
  final RxList<AppointmentModel> primaryAppointments = <AppointmentModel>[].obs;
  final RxList<AppointmentModel> secondaryAppointments =
      <AppointmentModel>[].obs;
  final RxBool isLoading = false.obs;

  // جلب مواعيد المريض أو جميع المواعيد للاستقبال
  Future<void> loadPatientAppointments() async {
    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      final userType = authController.currentUser.value?.userType;

      if (userType == 'receptionist') {
        // موظف الاستقبال: يجلب جميع المواعيد من /reception/appointments
        final list = await _doctorService.getAllAppointmentsForReception();
        appointments.value = list;
        primaryAppointments.clear();
        secondaryAppointments.clear();
      } else {
        // المريض: يجلب مواعيده الخاصة من /patient/appointments
        final result = await _patientService.getMyAppointments();
        primaryAppointments.value = result['primary'] ?? [];
        secondaryAppointments.value = result['secondary'] ?? [];

        // دمج المواعيد
        appointments.value = [...primaryAppointments, ...secondaryAppointments];
      }
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل المواعيد');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب مواعيد الطبيب
  Future<void> loadDoctorAppointments({
    String? day,
    String? dateFrom,
    String? dateTo,
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      isLoading.value = true;
      final appointmentsList = await _doctorService.getMyAppointments(
        day: day,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
        skip: skip,
        limit: limit,
      );
      appointments.value = appointmentsList;
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل المواعيد');
    } finally {
      isLoading.value = false;
    }
  }

  // إضافة موعد جديد (للطبيب)
  Future<void> addAppointment({
    required String patientId,
    required DateTime scheduledAt,
    String? note,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    try {
      isLoading.value = true;
      final appointment = await _doctorService.addAppointment(
        patientId: patientId,
        scheduledAt: scheduledAt,
        note: note,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      appointments.add(appointment);
      Get.snackbar('نجح', 'تم إضافة الموعد بنجاح');
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إضافة الموعد');
    } finally {
      isLoading.value = false;
    }
  }

  List<AppointmentModel> getUpcomingAppointments() {
    final now = DateTime.now();
    return appointments.where((appointment) {
      return appointment.date.isAfter(now) &&
          (appointment.status == 'pending' ||
              appointment.status == 'scheduled');
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<AppointmentModel> getPastAppointments() {
    final now = DateTime.now();
    return appointments.where((appointment) {
      return appointment.date.isBefore(now) ||
          appointment.status == 'completed' ||
          appointment.status == 'cancelled';
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  // مواعيد اليوم
  List<AppointmentModel> getTodayAppointments() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return appointments.where((appointment) {
      final appointmentDate = appointment.date;
      return appointmentDate.isAfter(todayStart) &&
          appointmentDate.isBefore(todayEnd) &&
          (appointment.status == 'pending' ||
              appointment.status == 'scheduled');
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  // المواعيد المتأخرة (مواعيد فاتت ولم تكتمل)
  List<AppointmentModel> getLateAppointments() {
    final now = DateTime.now();
    return appointments.where((appointment) {
      return appointment.date.isBefore(now) &&
          (appointment.status == 'pending' ||
              appointment.status == 'scheduled');
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  // مواعيد هذا الشهر
  List<AppointmentModel> getThisMonthAppointments() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    return appointments.where((appointment) {
      final appointmentDate = appointment.date;
      return appointmentDate.isAfter(monthStart) &&
          appointmentDate.isBefore(monthEnd) &&
          (appointment.status == 'pending' ||
              appointment.status == 'scheduled');
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}
