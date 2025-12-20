import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/controllers/appointment_controller.dart';
import 'package:farah_sys_final/models/appointment_model.dart';
import 'package:farah_sys_final/core/widgets/loading_widget.dart';
import 'package:farah_sys_final/core/widgets/empty_state_widget.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String selectedFilter = 'اليوم'; // اليوم، المتأخرين، هذا الشهر

  @override
  Widget build(BuildContext context) {
    final appointmentController = Get.find<AppointmentController>();
    
    // Load appointments on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appointmentController.loadPatientAppointments();
    });
    
    return Scaffold(
      body: SafeArea(
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
                        AppStrings.appointments,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Filter Tabs
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab(
                      label: 'اليوم',
                      isSelected: selectedFilter == 'اليوم',
                      onTap: () => setState(() => selectedFilter = 'اليوم'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildFilterTab(
                      label: 'المتأخرين',
                      isSelected: selectedFilter == 'المتأخرين',
                      onTap: () => setState(() => selectedFilter = 'المتأخرين'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildFilterTab(
                      label: 'هذا الشهر',
                      isSelected: selectedFilter == 'هذا الشهر',
                      onTap: () => setState(() => selectedFilter = 'هذا الشهر'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: Obx(() {
                if (appointmentController.isLoading.value) {
                  return const LoadingWidget(message: 'جاري تحميل المواعيد...');
                }
                
                List<AppointmentModel> filteredAppointments = [];
                String emptyMessage = '';
                
                switch (selectedFilter) {
                  case 'اليوم':
                    filteredAppointments = appointmentController.getTodayAppointments();
                    emptyMessage = 'لا توجد مواعيد اليوم';
                    break;
                  case 'المتأخرين':
                    filteredAppointments = appointmentController.getLateAppointments();
                    emptyMessage = 'لا توجد مواعيد متأخرة';
                    break;
                  case 'هذا الشهر':
                    filteredAppointments = appointmentController.getThisMonthAppointments();
                    emptyMessage = 'لا توجد مواعيد هذا الشهر';
                    break;
                }
                
                if (filteredAppointments.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.calendar_today_outlined,
                    title: emptyMessage,
                    subtitle: 'لم يتم العثور على مواعيد',
                  );
                }
                
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = filteredAppointments[index];
                    final isPast = appointment.date.isBefore(DateTime.now()) ||
                        appointment.status == 'completed' ||
                        appointment.status == 'cancelled';
                    final isLate = selectedFilter == 'المتأخرين';
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _buildAppointmentCard(
                        appointment: appointment,
                        status: isLate ? 'متأخر' : (isPast ? 'سابق' : 'قادم'),
                        date: '${appointment.date.day}-${appointment.date.month}-${appointment.date.year}',
                        time: appointment.time,
                        isPast: isPast,
                        isLate: isLate,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard({
    required AppointmentModel appointment,
    required String status,
    required String date,
    required String time,
    required bool isPast,
    bool isLate = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isLate 
            ? AppColors.error.withValues(alpha: 0.1)
            : (isPast ? AppColors.divider : AppColors.white),
        borderRadius: BorderRadius.circular(16.r),
        border: isLate 
            ? Border.all(color: AppColors.error, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isLate)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'متأخر',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  '${appointment.patientName} - ${appointment.doctorName}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isLate)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: AppColors.white, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'متأخر',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isLate 
                          ? AppColors.error
                          : (isPast ? AppColors.textSecondary : AppColors.primary),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '$time ${AppStrings.afternoon}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: 8.w),
              Text(
                'في تمام الساعة',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.calendar_today,
                size: 18.sp,
                color: AppColors.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                'يوم الثلاثاء المصادف',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (!isPast) ...[
            SizedBox(height: 12.h),
            Text(
              AppStrings.arriveBeforeTime,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
