import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';
import 'package:farah_sys_final/controllers/appointment_controller.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final patientController = Get.find<PatientController>();
    final appointmentController = Get.find<AppointmentController>();
    
    // Load data on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      patientController.loadMyProfile();
      appointmentController.loadPatientAppointments();
    });
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.notifications);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.homePage,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.patientProfile);
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
              // Welcome Card with gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
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
                    Obx(() {
                      final user = authController.currentUser.value;
                      final profile = patientController.myProfile.value;
                      return Text(
                        user?.name ?? profile?.name ?? 'مريض',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      );
                    }),
                    SizedBox(height: 8.h),
                    Text(
                      AppStrings.welcomeToClinic,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                AppStrings.yourDoctor,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              // Doctor Card with enhanced design
              Container(
                width: double.infinity,
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
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final profile = patientController.myProfile.value;
                        if (profile != null) {
                          Get.toNamed(AppRoutes.chat, arguments: {'patientId': profile.id});
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'د. سجاد الساعاتي',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.medical_services,
                                size: 16.sp,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                AppStrings.specialist,
                                style: TextStyle(
                                  fontSize: 14.sp,
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
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 30.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              // Dental Implant Timeline Card (if patient has implant treatment)
              Obx(() {
                final profile = patientController.myProfile.value;
                final hasImplant = profile?.treatmentHistory?.contains(AppStrings.implant) ?? false;
                
                if (hasImplant) {
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.dentalImplantTimeline);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
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
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.medical_services,
                                  color: AppColors.white,
                                  size: 28.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'مواعيد زراعة اسنانك',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'تابع مراحل زراعة الأسنان',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.white,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
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
                    AppStrings.appointments,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Obx(() {
                final upcoming = appointmentController.getUpcomingAppointments();
                final past = appointmentController.getPastAppointments();
                
                if (upcoming.isEmpty && past.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(24.w),
                    child: Center(
                      child: Text(
                        'لا توجد مواعيد',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: [
                    if (upcoming.isNotEmpty)
                      ...upcoming.take(2).map((appointment) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _buildAppointmentCard(
                              status: AppStrings.nextAppointment,
                              date: '${appointment.date.day}-${appointment.date.month}-${appointment.date.year}',
                              time: appointment.time,
                              isPast: false,
                            ),
                          )),
                    if (past.isNotEmpty)
                      ...past.take(1).map((appointment) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _buildAppointmentCard(
                              status: AppStrings.previousAppointment,
                              date: '${appointment.date.day}-${appointment.date.month}-${appointment.date.year}',
                              time: appointment.time,
                              isPast: true,
                            ),
                          )),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String status,
    required String date,
    required String time,
    required bool isPast,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isPast ? AppColors.divider : AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isPast ? AppColors.divider : AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: isPast
            ? []
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isPast
                      ? AppColors.textSecondary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isPast ? 'منتهي' : 'قادم',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isPast ? AppColors.textSecondary : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                isPast ? Icons.check_circle_outline : Icons.access_time,
                size: 20.sp,
                color: isPast ? AppColors.textSecondary : AppColors.primary,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'موعدك ${isPast ? 'السابق' : 'القادم'} مع الدكتور',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'د. سجاد الساعاتي',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPast
                          ? [AppColors.textSecondary, AppColors.textSecondary]
                          : [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16.sp,
                        color: AppColors.white,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isPast) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    AppStrings.arriveBeforeTime,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

