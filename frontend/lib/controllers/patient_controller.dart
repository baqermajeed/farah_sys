import 'package:get/get.dart';
import 'package:farah_sys_final/models/patient_model.dart';
import 'package:farah_sys_final/services/patient_service.dart';
import 'package:farah_sys_final/services/doctor_service.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class PatientController extends GetxController {
  final _patientService = PatientService();
  final _doctorService = DoctorService();

  final RxList<PatientModel> patients = <PatientModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<PatientModel?> selectedPatient = Rx<PatientModel?>(null);
  final Rx<PatientModel?> myProfile = Rx<PatientModel?>(null);

  // جلب قائمة المرضى (للطبيب أو موظف الاستقبال)
  Future<void> loadPatients({int skip = 0, int limit = 50}) async {
    try {
      isLoading.value = true;
      print('📋 [PatientController] Loading patients...');

      // تحديد نوع المستخدم الحالي
      final authController = Get.find<AuthController>();
      final userType = authController.currentUser.value?.userType;
      print('📋 [PatientController] Current user type: $userType');

      if (userType == 'receptionist') {
        // موظف الاستقبال: يجلب جميع المرضى من /reception/patients
        print('📋 [PatientController] Loading all patients (receptionist)...');
        final patientsList = await _patientService.getAllPatients(
          skip: skip,
          limit: limit,
        );
        patients.value = patientsList;
        print(
          '✅ [PatientController] Loaded ${patientsList.length} patients (receptionist)',
        );
      } else {
        // الطبيب (أو أي نوع آخر): يجلب مرضاه فقط من /doctor/patients
        print('📋 [PatientController] Loading doctor patients...');
        final patientsList = await _doctorService.getMyPatients(
          skip: skip,
          limit: limit,
        );
        patients.value = patientsList;
        print(
          '✅ [PatientController] Loaded ${patientsList.length} patients (doctor)',
        );

        if (patientsList.isEmpty) {
          print('⚠️ [PatientController] No patients found for this doctor!');
          print(
            '   💡 Make sure patients are assigned to this doctor in the backend.',
          );
          print(
            '   💡 Patients need primary_doctor_id or secondary_doctor_id set.',
          );
        }
      }
    } on ApiException catch (e) {
      print('❌ [PatientController] ApiException: ${e.message}');
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      print('❌ [PatientController] Error: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل المرضى');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب بيانات المريض الحالي (للمريض)
  Future<void> loadMyProfile() async {
    try {
      isLoading.value = true;
      final profile = await _patientService.getMyProfile();
      myProfile.value = profile;
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل البيانات');
    } finally {
      isLoading.value = false;
    }
  }

  // تحديد نوع العلاج (للطبيب)
  Future<void> setTreatmentType({
    required String patientId,
    required String treatmentType,
  }) async {
    try {
      isLoading.value = true;
      final updatedPatient = await _doctorService.setTreatmentType(
        patientId: patientId,
        treatmentType: treatmentType,
      );

      // تحديث القائمة
      final index = patients.indexWhere((p) => p.id == patientId);
      if (index != -1) {
        patients[index] = updatedPatient;
      }

      Get.snackbar('نجح', 'تم تحديث نوع العلاج');
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحديث نوع العلاج');
    } finally {
      isLoading.value = false;
    }
  }

  PatientModel? getPatientById(String patientId) {
    try {
      return patients.firstWhere((p) => p.id == patientId);
    } catch (e) {
      return null;
    }
  }

  List<PatientModel> searchPatients(String query) {
    if (query.isEmpty) return patients;

    return patients.where((patient) {
      return patient.name.toLowerCase().contains(query.toLowerCase()) ||
          patient.phoneNumber.contains(query);
    }).toList();
  }

  void selectPatient(PatientModel? patient) {
    selectedPatient.value = patient;
  }
}
