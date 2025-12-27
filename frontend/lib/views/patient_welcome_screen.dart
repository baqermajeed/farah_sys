import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';

class PatientWelcomeScreen extends StatefulWidget {
  const PatientWelcomeScreen({super.key});

  @override
  State<PatientWelcomeScreen> createState() => _PatientWelcomeScreenState();
}

class _PatientWelcomeScreenState extends State<PatientWelcomeScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final PatientController _patientController = Get.find<PatientController>();
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // التحقق من حالة المريض كل 5 ثوانٍ
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkDoctorAssignment();
    });
    // التحقق فوراً عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDoctorAssignment();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkDoctorAssignment() async {
    try {
      final hasDoctor = await _patientController.checkDoctorAssignment();
      if (hasDoctor && mounted) {
        // إذا تم ربط المريض بطبيب، الانتقال إلى الصفحة الرئيسية
        _checkTimer?.cancel();
        Get.offAllNamed(AppRoutes.patientHome);
      }
    } catch (e) {
      print('❌ [PatientWelcomeScreen] Error checking doctor assignment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _authController.currentUser.value?.name ?? 'المريض';

    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 40.h),
                    // Title
                    Text(
                      'الصفحة الرئيسية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 60.h),
                    // Tooth icon with sparkles
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Sparkles
                        Positioned(
                          right: 40.w,
                          top: 20.h,
                          child: Icon(
                            Icons.star,
                            size: 30.sp,
                            color: Colors.amber,
                          ),
                        ),
                        Positioned(
                          right: 60.w,
                          top: 50.h,
                          child: Icon(
                            Icons.star,
                            size: 24.sp,
                            color: Colors.amber,
                          ),
                        ),
                        // Tooth icon
                        Container(
                          width: 150.w,
                          height: 150.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.medical_services,
                            size: 80.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 60.h),
                    // Welcome message
                    Text(
                      'مرحبا عزيزي "$userName" انتظر',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'حتى يتم تحويلك من قبل موظف',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'الاستقبال الى طبيب معين لتبدا رحلتك',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'العلاجية معنا',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 60.h),
                    // Logout button
                    Obx(
                      () => Container(
                        width: double.infinity,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: _authController.isLoading.value
                              ? AppColors.textHint
                              : AppColors.error,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _authController.isLoading.value
                                ? null
                                : () async {
                                    // تأكيد تسجيل الخروج
                                    final shouldLogout = await Get.dialog<bool>(
                                      AlertDialog(
                                        title: Text(
                                          'تسجيل الخروج',
                                          textAlign: TextAlign.right,
                                        ),
                                        content: Text(
                                          'هل أنت متأكد من تسجيل الخروج؟',
                                          textAlign: TextAlign.right,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Get.back(result: false),
                                            child: Text('إلغاء'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Get.back(result: true),
                                            child: Text(
                                              'تسجيل الخروج',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldLogout == true) {
                                      await _authController.logout();
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16.r),
                            child: Center(
                              child: _authController.isLoading.value
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.logout,
                                          color: AppColors.white,
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'تسجيل الخروج',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
