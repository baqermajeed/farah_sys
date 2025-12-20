import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';
import 'package:farah_sys_final/core/widgets/custom_text_field.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? name;
  final String? gender;
  final int? age;
  final String? city;
  final bool isRegistration;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.name,
    this.gender,
    this.age,
    this.city,
    this.isRegistration = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
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
              SizedBox(height: 48.h),
              // Verification Image
              Image.asset(
                'image_ui/تحقق.png',
                width: 180.w,
                height: 180.h,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                    child: Icon(
                      Icons.sms_outlined,
                      size: 60.sp,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
              SizedBox(height: 32.h),
              Text(
                'التحقق من الرمز',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'أدخل رمز التحقق المرسل إلى',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                widget.phoneNumber,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 48.h),
              CustomTextField(
                labelText: 'رمز التحقق',
                hintText: '0000',
                controller: _otpController,
                keyboardType: TextInputType.number,
                focusNode: _otpFocusNode,
                maxLength: 6,
              ),
              SizedBox(height: 24.h),
              Obx(() => CustomButton(
                    text: 'تحقق',
                    onPressed: _authController.isLoading.value
                        ? null
                        : () async {
                            if (_otpController.text.length < 4) {
                              Get.snackbar(
                                'خطأ',
                                'يرجى إدخال رمز التحقق',
                                snackPosition: SnackPosition.TOP,
                              );
                              return;
                            }

                            await _authController.verifyOtpAndLogin(
                              phoneNumber: widget.phoneNumber,
                              code: _otpController.text,
                              name: widget.name,
                              gender: widget.gender,
                              age: widget.age,
                              city: widget.city,
                              returnToReception: widget.isRegistration,
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
                    'لم تستلم الرمز؟',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () async {
                      await _authController.requestOtp(widget.phoneNumber);
                    },
                    child: Text(
                      'إعادة الإرسال',
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

