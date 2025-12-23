import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/widgets/empty_state_widget.dart';
import 'package:farah_sys_final/core/widgets/loading_widget.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';

class DoctorPatientsListScreen extends StatelessWidget {
  const DoctorPatientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientController = Get.find<PatientController>();
    
    // Load patients on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      patientController.loadPatients();
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate back to doctor home
                      Get.offAllNamed(AppRoutes.doctorHome);
                    },
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.home,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                  Text(
                    'قائمة المرضى',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.addPatient);
                    },
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (patientController.isLoading.value) {
                  return const LoadingWidget(message: 'جاري تحميل المرضى...');
                }

                if (patientController.patients.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'لا يوجد مرضى',
                    subtitle: 'لم يتم إضافة أي مريض بعد',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  itemCount: patientController.patients.length,
                  itemBuilder: (context, index) {
                    final patient = patientController.patients[index];
                    return GestureDetector(
                      onTap: () {
                        patientController.selectPatient(patient);
                        Get.toNamed(
                          AppRoutes.patientDetails,
                          arguments: {'patientId': patient.id},
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1,
                          ),
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
                            // Phone Icon
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.phone,
                                color: AppColors.primary,
                                size: 18.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // Phone Number
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'رقم الهاتف',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  patient.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Patient Info
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    patient.name,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Wrap(
                                    spacing: 6.w,
                                    runSpacing: 6.h,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          '${patient.age} سنة',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          patient.gender == 'male' ? 'ذكر' : 'أنثى',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // Avatar
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
}
