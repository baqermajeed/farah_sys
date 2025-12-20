import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/controllers/appointment_controller.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final appointmentController = Get.find<AppointmentController>();
    final patientController = Get.find<PatientController>();

    // Load data on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appointmentController.loadDoctorAppointments();
      patientController.loadPatients();
    });

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
                    'الصفحة الرئيسية',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.doctorProfile);
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
                    Obx(() {
                      final user = authController.currentUser.value;
                      return Text(
                        '${AppStrings.welcome} ${user?.name ?? 'دكتور'}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      );
                    }),
                    SizedBox(height: 8.h),
                    Text(
                      'عيادة فرح لطب الأسنان',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              // Quick Stats
              Obx(() {
                final patientsCount = patientController.patients.length;
                final appointmentsCount =
                    appointmentController.appointments.length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        title: 'المرضى',
                        value: patientsCount.toString(),
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.calendar_today,
                        title: 'المواعيد',
                        value: appointmentsCount.toString(),
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                );
              }),
              SizedBox(height: 24.h),
              // Quick Actions
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
                    icon: Icons.people,
                    title: 'قائمة المرضى',
                    color: AppColors.primary,
                    onTap: () {
                      Get.toNamed(AppRoutes.doctorPatientsList);
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
                    icon: Icons.chat_bubble_outline,
                    title: 'المحادثات',
                    color: AppColors.success,
                    onTap: () {
                      Get.toNamed(AppRoutes.doctorChats);
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.medical_services,
                    title: 'السجلات الطبية',
                    color: AppColors.warning,
                    onTap: () {
                      Get.toNamed(AppRoutes.medicalRecords);
                    },
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              // Today's Appointments
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
              Obx(() {
                final todayAppointments = appointmentController
                    .getTodayAppointments();

                if (todayAppointments.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(24.w),
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
                    child: Center(
                      child: Text(
                        'لا توجد مواعيد اليوم',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: todayAppointments.take(3).map((appointment) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildAppointmentCard(
                        patientName: appointment.patientName,
                        time: appointment.time,
                        date:
                            '${appointment.date.day}-${appointment.date.month}-${appointment.date.year}',
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
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

  Widget _buildAppointmentCard({
    required String patientName,
    required String time,
    required String date,
  }) {
    return Container(
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
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.person, color: AppColors.primary, size: 24.sp),
          ),
          SizedBox(width: 16.w),
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
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.calendar_today,
                      size: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      date,
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
        ],
      ),
    );
  }
}
