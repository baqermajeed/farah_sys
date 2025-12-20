import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';
import 'package:farah_sys_final/core/widgets/custom_text_field.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Login Image
              Image.asset(
                'image_ui/تسجيل دخول.png',
                width: 250.w,
                height: 200.h,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200.w,
                    height: 200.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      size: 100.sp,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
              SizedBox(height: 32.h),
              Text(
                AppStrings.login,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'أدخل رقم هاتفك لتسجيل الدخول',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 48.h),
              CustomTextField(
                labelText: AppStrings.phoneNumber,
                hintText: '0000 000 0000',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 48.h),
              Obx(() => CustomButton(
                    text: AppStrings.login,
                    onPressed: _authController.isLoading.value
                        ? null
                        : () async {
                            if (_phoneController.text.isEmpty) {
                              Get.snackbar(
                                'خطأ',
                                'يرجى إدخال رقم الهاتف',
                                snackPosition: SnackPosition.TOP,
                              );
                              return;
                            }

                            await _authController.requestOtp(
                              _phoneController.text.trim(),
                            );

                            // Navigate to OTP verification
                            Get.toNamed(
                              AppRoutes.otpVerification,
                              arguments: {
                                'phoneNumber': _phoneController.text.trim(),
                                'isRegistration': false,
                              },
                            );
                          },
                    width: double.infinity,
                    isLoading: _authController.isLoading.value,
                  )),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.noAccount,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.addPatient);
                    },
                    child: Text(
                      AppStrings.createAccountNow,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
