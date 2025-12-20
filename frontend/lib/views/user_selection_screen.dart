import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  String? selectedUserType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo or Clinic Image
                    Image.asset(
                      'assets/images/logo.png',
                      width: 200.w,
                      height: 200.h,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200.w,
                          height: 200.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          child: Icon(
                            Icons.local_hospital,
                            size: 100.sp,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 48.h),
                    Text(
                      AppStrings.selectUserType,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'اختر نوع المستخدم للمتابعة',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    _buildUserTypeButton(
                      label: AppStrings.patient,
                      icon: Icons.person_outline,
                      isSelected: selectedUserType == 'patient',
                      onTap: () {
                        setState(() {
                          selectedUserType = 'patient';
                        });
                      },
                    ),
                    SizedBox(height: 20.h),
                    _buildUserTypeButton(
                      label: AppStrings.doctor,
                      icon: Icons.medical_services_outlined,
                      isSelected: selectedUserType == 'doctor',
                      onTap: () {
                        setState(() {
                          selectedUserType = 'doctor';
                        });
                      },
                    ),
                    SizedBox(height: 20.h),
                    _buildUserTypeButton(
                      label: 'موظف',
                      icon: Icons.receipt_long,
                      isSelected: selectedUserType == 'receptionist',
                      onTap: () {
                        setState(() {
                          selectedUserType = 'receptionist';
                        });
                      },
                    ),
                  ],
                ),
              ),
              CustomButton(
                text: AppStrings.next,
                onPressed: selectedUserType == null
                    ? () {}
                    : () {
                        if (selectedUserType == 'patient') {
                          Get.toNamed(AppRoutes.patientLogin);
                        } else if (selectedUserType == 'doctor') {
                          Get.toNamed(AppRoutes.doctorLogin);
                        } else if (selectedUserType == 'receptionist') {
                          Get.toNamed(AppRoutes.receptionLogin);
                        }
                      },
                icon: Icon(
                  Icons.arrow_forward,
                  color: AppColors.white,
                  size: 20.sp,
                ),
                backgroundColor: selectedUserType == null
                    ? AppColors.textSecondary
                    : AppColors.primary,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton({
    required String label,
    required IconData icon,

    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image or Icon
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_circle, color: AppColors.primary, size: 24.sp),
            ],
          ],
        ),
      ),
    );
  }
}
