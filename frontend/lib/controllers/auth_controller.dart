import 'package:get/get.dart';
import 'package:farah_sys_final/models/user_model.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/services/auth_service.dart';

class AuthController extends GetxController {
  final _authService = AuthService();
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString otpCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // تحميل التوكن والمستخدم المحفوظين عند بدء التطبيق
    _loadPersistedSession();
  }

  // تحميل التوكن والمستخدم من الـ storage
  Future<void> _loadPersistedSession() async {
    try {
      print('🔍 [AuthController] Loading persisted session...');
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        print('✅ [AuthController] Token found, loading user info...');
        final res = await _authService.getCurrentUser();
        if (res['ok'] == true) {
          final userData = res['data'] as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);
          currentUser.value = user;
          print(
            '✅ [AuthController] User loaded from session: ${user.name} (${user.userType})',
          );
        } else {
          print(
            '⚠️ [AuthController] Failed to load user info, clearing session',
          );
          await _authService.logout();
          currentUser.value = null;
        }
      } else {
        print('ℹ️ [AuthController] No saved session found');
      }
    } catch (e) {
      print('❌ [AuthController] Error loading persisted session: $e');
      currentUser.value = null;
    }
  }

  Future<void> checkLoggedInUser() async {
    try {
      print('🔍 [AuthController] Checking logged in user...');
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        print('✅ [AuthController] User is logged in, fetching user info...');
        final res = await _authService.getCurrentUser();
        if (res['ok'] == true) {
          final userData = res['data'] as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);
          currentUser.value = user;
          print(
            '✅ [AuthController] User loaded: ${user.name} (${user.userType})',
          );

          if (user.userType == 'patient') {
            Get.offAllNamed(AppRoutes.patientHome);
          } else if (user.userType == 'doctor') {
            Get.offAllNamed(AppRoutes.doctorPatientsList);
          } else {
            Get.offAllNamed(AppRoutes.userSelection);
          }
        }
      } else {
        print('ℹ️ [AuthController] User is not logged in');
      }
    } catch (e) {
      print('❌ [AuthController] Error checking logged in user: $e');
      currentUser.value = null;
    }
  }

  // طلب إرسال OTP
  Future<void> requestOtp(String phoneNumber) async {
    print('🎯 [AuthController] requestOtp called');
    print('   📱 Phone: $phoneNumber');

    if (phoneNumber.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال رقم الهاتف');
      return;
    }

    try {
      print('⏳ [AuthController] Setting loading to true');
      isLoading.value = true;
      print('📞 [AuthController] Calling authService.requestOtp...');

      final res = await _authService.requestOtp(phoneNumber.trim());

      if (res['ok'] == true) {
        print('✅ [AuthController] OTP request completed successfully');
        Get.snackbar('نجح', 'تم إرسال رمز التحقق');
      } else {
        print('❌ [AuthController] OTP request failed: ${res['error']}');
        Get.snackbar('خطأ', res['error']?.toString() ?? 'فشل إرسال رمز التحقق');
      }
    } catch (e) {
      print('❌ [AuthController] General error: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال رمز التحقق');
    } finally {
      print('🏁 [AuthController] Setting loading to false');
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
    print('🎯 [AuthController] verifyOtpAndLogin called');
    print('   📱 Phone: $phoneNumber');
    print('   🔑 Code: $code');
    print('   👤 Name: $name');
    print('   Return to reception: $returnToReception');

    if (phoneNumber.trim().isEmpty || code.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال رقم الهاتف والرمز');
      return;
    }

    try {
      print('⏳ [AuthController] Setting loading to true');
      isLoading.value = true;
      print('🔐 [AuthController] Calling authService.verifyOtp...');

      final res = await _authService.verifyOtp(
        phone: phoneNumber.trim(),
        code: code.trim(),
        name: name,
        gender: gender,
        age: age,
        city: city,
      );

      if (res['ok'] == true) {
        print('✅ [AuthController] OTP verified successfully');

        // جلب معلومات المستخدم بعد التحقق من OTP
        final userRes = await _authService.getCurrentUser();
        if (userRes['ok'] == true) {
          final userData = userRes['data'] as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);

          print(
            '✅ [AuthController] User loaded: ${user.name} (${user.userType})',
          );
          currentUser.value = user;
          print('💾 [AuthController] Current user updated in controller');

          if (returnToReception) {
            print('🔀 [AuthController] Navigating to reception home');
            Get.offAllNamed(AppRoutes.receptionHome);
            Get.snackbar('نجح', 'تم إضافة المريض بنجاح');
          } else {
            print('🔀 [AuthController] Navigating to patient home');
            Get.offAllNamed(AppRoutes.patientHome);
            Get.snackbar('نجح', 'تم تسجيل الدخول بنجاح');
          }
        } else {
          print(
            '❌ [AuthController] Failed to get user info: ${userRes['error']}',
          );
          Get.snackbar(
            'خطأ',
            userRes['error']?.toString() ?? 'فشل جلب معلومات المستخدم',
          );
        }
      } else {
        print('❌ [AuthController] OTP verification failed: ${res['error']}');
        Get.snackbar(
          'خطأ',
          res['error']?.toString() ?? 'فشل التحقق من رمز OTP',
        );
      }
    } catch (e) {
      print('❌ [AuthController] General error: $e');
      Get.snackbar('خطأ', 'فشل التحقق من رمز OTP');
    } finally {
      print('🏁 [AuthController] Setting loading to false');
      isLoading.value = false;
    }
  }

  // تسجيل دخول المريض (مع OTP)
  Future<void> loginPatient(String phoneNumber) async {
    await requestOtp(phoneNumber);
  }

  // تسجيل دخول الطاقم (username/password)
  Future<void> loginDoctor({
    required String username,
    required String password,
  }) async {
    print('🎯 [AuthController] loginDoctor called');
    print('   👤 Username: $username');
    print('   🔑 Password: ${'*' * password.length}');

    if (username.trim().isEmpty || password.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    try {
      print('⏳ [AuthController] Setting loading to true');
      isLoading.value = true;
      print('🔐 [AuthController] Calling authService.staffLogin...');

      final res = await _authService.staffLogin(
        username: username.trim(),
        password: password,
      );

      if (res['ok'] == true) {
        print('✅ [AuthController] Login successful');

        // جلب معلومات المستخدم بعد تسجيل الدخول
        final userRes = await _authService.getCurrentUser();
        if (userRes['ok'] == true) {
          final userData = userRes['data'] as Map<String, dynamic>;

          // Log raw data from backend
          print('📋 [AuthController] Raw user data from backend:');
          print('   Role: ${userData['role']}');
          print('   UserType: ${userData['userType']}');
          print('   Full data: $userData');

          final user = UserModel.fromJson(userData);

          print(
            '✅ [AuthController] User loaded: ${user.name} (${user.userType})',
          );
          print('   🔍 Mapped userType: ${user.userType}');
          currentUser.value = user;
          print('💾 [AuthController] Current user updated in controller');

          // توجيه حسب نوع المستخدم القادم من الـ Backend
          String targetRoute;
          switch (user.userType.toLowerCase()) {
            case 'doctor':
              targetRoute = AppRoutes.doctorHome;
              break;
            case 'receptionist':
              targetRoute = AppRoutes.receptionHome;
              break;
            case 'photographer':
              targetRoute =
                  AppRoutes.receptionHome; // أو صفحة خاصة بالـ photographer
              break;
            case 'admin':
              targetRoute = AppRoutes.userSelection;
              break;
            default:
              print(
                '⚠️ [AuthController] Unknown userType: ${user.userType}, defaulting to userSelection',
              );
              targetRoute = AppRoutes.userSelection;
          }

          print(
            '🔀 [AuthController] Navigating to: $targetRoute (userType: ${user.userType})',
          );
          Get.offAllNamed(targetRoute);
          Get.snackbar('نجح', 'تم تسجيل الدخول بنجاح');
        } else {
          print(
            '❌ [AuthController] Failed to get user info: ${userRes['error']}',
          );
          Get.snackbar(
            'خطأ',
            userRes['error']?.toString() ?? 'فشل جلب معلومات المستخدم',
          );
        }
      } else {
        print('❌ [AuthController] Login failed: ${res['error']}');
        Get.snackbar('خطأ', res['error']?.toString() ?? 'فشل تسجيل الدخول');
      }
    } catch (e) {
      print('❌ [AuthController] General error: $e');
      Get.snackbar('خطأ', 'فشل تسجيل الدخول');
    } finally {
      print('🏁 [AuthController] Setting loading to false');
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
    print('🎯 [AuthController] registerPatient called');
    print('   📱 Phone: $phoneNumber');
    print('   👤 Name: $name');

    try {
      isLoading.value = true;
      // أولاً طلب OTP
      final res = await _authService.requestOtp(phoneNumber.trim());

      if (res['ok'] == true) {
        Get.snackbar(
          'نجح',
          'تم إرسال رمز التحقق. يرجى إدخال الرمز لإكمال التسجيل',
        );
      } else {
        Get.snackbar('خطأ', res['error']?.toString() ?? 'فشل إرسال رمز التحقق');
      }
    } catch (e) {
      print('❌ [AuthController] Error in registerPatient: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء التسجيل');
    } finally {
      isLoading.value = false;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    print('🎯 [AuthController] logout called');
    try {
      await _authService.logout();
      currentUser.value = null;
      print('✅ [AuthController] Logged out successfully');
      Get.offAllNamed(AppRoutes.userSelection);
    } catch (e) {
      print('❌ [AuthController] Error during logout: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء تسجيل الخروج');
    }
  }
}
