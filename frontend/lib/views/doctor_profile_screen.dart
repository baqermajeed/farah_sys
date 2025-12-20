import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Row(
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
                    Expanded(
                      child: Center(
                        child: Text(
                          'الملف الشخصي',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Settings
                        Get.snackbar(
                          'قريباً',
                          'صفحة الإعدادات قريباً',
                          snackPosition: SnackPosition.TOP,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              // Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60.r,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.person,
                      size: 60.sp,
                      color: AppColors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Change profile picture
                        Get.snackbar(
                          'قريباً',
                          'ميزة تغيير الصورة قريباً',
                          snackPosition: SnackPosition.TOP,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              Obx(() {
                final user = authController.currentUser.value;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppStrings.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.divider,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          user?.name ?? 'دكتور',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'اسم المستخدم',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.divider,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          user?.phoneNumber ?? 'doctor_user',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        AppStrings.phoneNumber,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.divider,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          user?.phoneNumber ?? 'غير محدد',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'المنصب',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.divider,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'طبيب أسنان',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'التخصص',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.divider,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'طبيب أسنان عام',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      CustomButton(
                        text: 'تعديل الملف الشخصي',
                        onPressed: () {
                          Get.snackbar(
                            'قريباً',
                            'ميزة تعديل الملف الشخصي قريباً',
                            snackPosition: SnackPosition.TOP,
                          );
                        },
                        backgroundColor: AppColors.primary,
                        width: double.infinity,
                        icon: Icon(
                          Icons.edit,
                          color: AppColors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      CustomButton(
                        text: AppStrings.logout,
                        onPressed: () async {
                          await authController.logout();
                        },
                        backgroundColor: AppColors.error,
                        width: double.infinity,
                        icon: Icon(
                          Icons.exit_to_app,
                          color: AppColors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

