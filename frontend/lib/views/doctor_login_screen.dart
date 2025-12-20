import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';
import 'package:farah_sys_final/core/widgets/custom_text_field.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
              Container(
                width: 200.w,
                height: 200.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 150.w,
                    height: 150.h,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.local_hospital,
                        size: 100.sp,
                        color: AppColors.primary,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                AppStrings.login,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 48.h),
              CustomTextField(
                labelText: AppStrings.doctorName,
                hintText: 'baqer121',
                controller: _usernameController,
              ),
              SizedBox(height: 24.h),
              CustomTextField(
                labelText: 'كلمة المرور',
                hintText: '••••••••',
                controller: _passwordController,
                obscureText: true,
              ),
              SizedBox(height: 48.h),
              Obx(() => CustomButton(
                    text: AppStrings.login,
                    onPressed: _authController.isLoading.value
                        ? null
                        : () async {
                            if (_usernameController.text.isEmpty ||
                                _passwordController.text.isEmpty) {
                              Get.snackbar(
                                'خطأ',
                                'يرجى إدخال اسم المستخدم وكلمة المرور',
                                snackPosition: SnackPosition.TOP,
                              );
                              return;
                            }

                            await _authController.loginDoctor(
                              username: _usernameController.text.trim(),
                              password: _passwordController.text,
                            );
                          },
                    width: double.infinity,
                    isLoading: _authController.isLoading.value,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
