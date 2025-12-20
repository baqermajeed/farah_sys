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

  @override
  void onInit() {
    super.onInit();
  }

  // جلب قائمة المرضى (للطبيب أو موظف الاستقبال)
  Future<void> loadPatients({int skip = 0, int limit = 50}) async {
    if (AuthController.demoMode) {
      // بيانات تجريبية
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 500));
      
      patients.value = [
        PatientModel(
          id: '1',
          name: 'أحمد محمد',
          phoneNumber: '07901234572',
          gender: 'male',
          age: 30,
          city: 'بغداد',
        ),
        PatientModel(
          id: '2',
          name: 'فاطمة علي',
          phoneNumber: '07901234573',
          gender: 'female',
          age: 25,
          city: 'البصرة',
        ),
        PatientModel(
          id: '3',
          name: 'حسين عبدالله',
          phoneNumber: '07901234574',
          gender: 'male',
          age: 35,
          city: 'الموصل',
        ),
        PatientModel(
          id: '4',
          name: 'زينب أحمد',
          phoneNumber: '07901234575',
          gender: 'female',
          age: 28,
          city: 'أربيل',
        ),
        PatientModel(
          id: '5',
          name: 'محمد كريم',
          phoneNumber: '07901234576',
          gender: 'male',
          age: 40,
          city: 'كربلاء',
        ),
      ];
      
      isLoading.value = false;
      return;
    }
    try {
      isLoading.value = true;

      // تحديد نوع المستخدم الحالي
      final authController = Get.find<AuthController>();
      final userType = authController.currentUser.value?.userType;

      if (userType == 'receptionist') {
        // موظف الاستقبال: يجلب جميع المرضى من /reception/patients
        final patientsList = await _patientService.getAllPatients(
          skip: skip,
          limit: limit,
        );
        patients.value = patientsList;
      } else {
        // الطبيب (أو أي نوع آخر): يجلب مرضاه فقط من /doctor/patients
        final patientsList = await _doctorService.getMyPatients(
          skip: skip,
          limit: limit,
        );
        patients.value = patientsList;
      }
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل المرضى');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب بيانات المريض الحالي (للمريض)
  Future<void> loadMyProfile() async {
    if (AuthController.demoMode) {
      // بيانات تجريبية
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 500));
      
      myProfile.value = PatientModel(
        id: 'demo_patient_1',
        name: 'مريض تجريبي',
        phoneNumber: '07901234572',
        gender: 'male',
        age: 30,
        city: 'بغداد',
      );
      
      isLoading.value = false;
      return;
    }
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
