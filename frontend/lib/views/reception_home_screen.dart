import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';

class ReceptionHomeScreen extends StatelessWidget {
  const ReceptionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Logout or settings
                      Get.back();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.logout,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.receptionHome,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.receptionProfile);
                    },
                    child: CircleAvatar(
                      radius: 20.r,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Welcome Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.welcome,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'قسم الاستقبال',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'إدارة المرضى والمواعيد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              // Quick Actions Grid
              Text(
                'الإجراءات السريعة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.1,
                children: [
                  _buildActionCard(
                    icon: Icons.person_add,
                    title: 'إضافة مريض',
                    color: AppColors.primary,
                    onTap: () {
                      Get.toNamed(AppRoutes.addPatient);
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.calendar_today,
                    title: 'المواعيد',
                    color: AppColors.secondary,
                    onTap: () {
                      Get.toNamed(AppRoutes.appointments);
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.people,
                    title: 'قائمة المرضى',
                    color: AppColors.success,
                    onTap: () {
                      Get.toNamed(AppRoutes.doctorPatientsList);
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.qr_code_scanner,
                    title: 'QR Code',
                    color: AppColors.warning,
                    onTap: () {
                      Get.toNamed(AppRoutes.qrScanner);
                    },
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              // Today's Appointments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.appointments);
                    },
                    child: Text(
                      AppStrings.viewAll,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    'مواعيد اليوم',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Today's appointments list
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.divider,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildAppointmentItem(
                      patientName: 'أحمد محمد',
                      time: '10:00 صباحاً',
                      status: 'قادم',
                      isActive: true,
                    ),
                    Divider(height: 24.h),
                    _buildAppointmentItem(
                      patientName: 'فاطمة علي',
                      time: '11:30 صباحاً',
                      status: 'قادم',
                      isActive: true,
                    ),
                    Divider(height: 24.h),
                    _buildAppointmentItem(
                      patientName: 'محمد حسن',
                      time: '02:00 مساءً',
                      status: 'قادم',
                      isActive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.divider,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem({
    required String patientName,
    required String time,
    required String status,
    required bool isActive,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.textSecondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11.sp,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                patientName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          child: Icon(Icons.person, color: AppColors.primary, size: 24.sp),
        ),
      ],
    );
  }
}
