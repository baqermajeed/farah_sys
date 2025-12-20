import 'package:get/get.dart';
import 'package:farah_sys_final/models/user_model.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/services/auth_service.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';

class AuthController extends GetxController {
  final _authService = AuthService();
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString otpCode = ''.obs;

  // وضع العرض فقط (بدون Backend)
  // غيّر القيمة إلى false لاستخدام الـ Backend الحقيقي
  static const bool demoMode = false;

  @override
  void onInit() {
    super.onInit();
    // تم إيقاف التحقق التلقائي من تسجيل الدخول عند بدء التطبيق
    // حتى يبدأ المستخدم دائمًا من واجهة تسجيل الدخول.
  }

  Future<void> checkLoggedInUser() async {
    if (demoMode) return;
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _authService.getCurrentUser();
        currentUser.value = user;
        if (user.userType == 'patient') {
          Get.offAllNamed(AppRoutes.patientHome);
        } else if (user.userType == 'doctor') {
          Get.offAllNamed(AppRoutes.doctorPatientsList);
        } else {
          Get.offAllNamed(AppRoutes.userSelection);
        }
      }
    } catch (e) {
      // المستخدم غير مسجل دخول
      currentUser.value = null;
    }
  }

  // طلب إرسال OTP
  Future<void> requestOtp(String phoneNumber) async {
    if (demoMode) {
      // في وضع العرض، فقط ننتظر قليلاً ثم ننتقل
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1));
      isLoading.value = false;
      Get.snackbar('نجح', 'تم إرسال رمز التحقق (وضع العرض)');
      return;
    }
    try {
      isLoading.value = true;
      await _authService.requestOtp(phoneNumber);
      Get.snackbar('نجح', 'تم إرسال رمز التحقق');
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال رمز التحقق');
    } finally {
      isLoading.value = false;
    }
  }

  // التحقق من OTP وتسجيل الدخول
  Future<void> verifyOtpAndLogin({
    required String phoneNumber,
    required String code,
    String? name,
    String? gender,
    int? age,
    String? city,
    bool returnToReception = false,
  }) async {
    if (demoMode) {
      // في وضع العرض، ننشئ مستخدم تجريبي
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1));
      
      currentUser.value = UserModel(
        id: 'demo_patient_1',
        name: name ?? 'مريض تجريبي',
        phoneNumber: phoneNumber,
        userType: 'patient',
        gender: gender,
        age: age,
        city: city,
      );
      
      isLoading.value = false;
      if (returnToReception) {
        Get.offAllNamed(AppRoutes.receptionHome);
        Get.snackbar('نجح', 'تم إضافة المريض بنجاح (وضع العرض)');
      } else {
        Get.offAllNamed(AppRoutes.patientHome);
        Get.snackbar('نجح', 'تم تسجيل الدخول بنجاح (وضع العرض)');
      }
      return;
    }
    try {
      isLoading.value = true;
      final user = await _authService.verifyOtp(
        phone: phoneNumber,
        code: code,
        name: name,
        gender: gender,
        age: age,
        city: city,
      );
      
      currentUser.value = user;
      if (returnToReception) {
        Get.offAllNamed(AppRoutes.receptionHome);
        Get.snackbar('نجح', 'تم إضافة المريض بنجاح');
      } else {
        Get.offAllNamed(AppRoutes.patientHome);
        Get.snackbar('نجح', 'تم تسجيل الدخول بنجاح');
      }
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل التحقق من رمز OTP');
    } finally {
      isLoading.value = false;
    }
  }

  // تسجيل دخول المريض (مع OTP)
  Future<void> loginPatient(String phoneNumber) async {
    await requestOtp(phoneNumber);
  }

  // تسجيل دخول الطبيب (username/password)
  Future<void> loginDoctor({
    required String username,
    required String password,
  }) async {
    if (demoMode) {
      // في وضع العرض، ننشئ طبيب تجريبي
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1));
      
      currentUser.value = UserModel(
        id: 'demo_doctor_1',
        name: 'د. سجاد الساعاتي',
        phoneNumber: '07901234567',
        userType: 'doctor',
        gender: 'male',
        age: 35,
        city: 'بغداد',
      );
      
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.doctorPatientsList);
      Get.snackbar('نجح', 'تم تسجيل الدخول بنجاح (وضع العرض)');
      return;
    }
    try {
      isLoading.value = true;
      final user = await _authService.staffLogin(
        username: username,
        password: password,
      );

      currentUser.value = user;

      // توجيه حسب نوع المستخدم القادم من الـ Backend
      String targetRoute;
      switch (user.userType) {
        case 'doctor':
          targetRoute = AppRoutes.doctorPatientsList;
          break;
        case 'receptionist':
          targetRoute = AppRoutes.receptionHome;
          break;
        case 'admin':
          // لا توجد واجهة خاصة للمدير حالياً؛ نعيده لواجهة اختيار المستخدم
          targetRoute = AppRoutes.userSelection;
          break;
        default:
          targetRoute = AppRoutes.userSelection;
      }

      Get.offAllNamed(targetRoute);
      Get.snackbar('نجح', 'تم تسجيل الدخول كـ ${user.userType}');
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تسجيل الدخول');
    } finally {
      isLoading.value = false;
    }
  }

  // تسجيل مريض جديد (مع OTP)
  Future<void> registerPatient({
    required String name,
    required String phoneNumber,
    required String gender,
    required int age,
    required String city,
  }) async {
    try {
      isLoading.value = true;
      // أولاً طلب OTP
      await _authService.requestOtp(phoneNumber);
      Get.snackbar('نجح', 'تم إرسال رمز التحقق. يرجى إدخال الرمز لإكمال التسجيل');
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء التسجيل');
    } finally {
      isLoading.value = false;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    if (demoMode) {
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.userSelection);
      return;
    }
    try {
      await _authService.logout();
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.userSelection);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تسجيل الخروج');
    }
  }
}
