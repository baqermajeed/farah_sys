import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';
import 'package:farah_sys_final/core/widgets/back_button_widget.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class ReceptionProfileScreen extends StatelessWidget {
  const ReceptionProfileScreen({super.key});

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
                    // Empty space on the right to balance the back button
                    SizedBox(width: 40.w),
                    Expanded(
                      child: Center(
                        child: Text(
                          AppStrings.receptionProfile,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    // Back button on the left (in RTL)
                    const BackButtonWidget(),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              // Profile Image
              CircleAvatar(
                radius: 60.r,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, size: 60.sp, color: AppColors.white),
              ),
              SizedBox(height: 32.h),
              Obx(() {
                final user = authController.currentUser.value;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
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
                          user?.name ?? 'موظف الاستقبال',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        AppStrings.receptionUsername,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
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
                          user?.phoneNumber ?? 'reception_user',
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
                        textAlign: TextAlign.right,
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
                        textAlign: TextAlign.right,
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
                          'موظف استقبال',
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
                          Get.toNamed(AppRoutes.editReceptionProfile);
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
