import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/core/widgets/empty_state_widget.dart';
import 'package:farah_sys_final/core/widgets/loading_widget.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';

class DoctorChatsScreen extends StatelessWidget {
  const DoctorChatsScreen({super.key});

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
                        'المحادثات',
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
                      // Search
                    },
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.search,
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
                  return const LoadingWidget(message: 'جاري تحميل المحادثات...');
                }

                if (patientController.patients.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.chat_bubble_outline,
                    title: 'لا توجد محادثات',
                    subtitle: 'لم يتم بدء أي محادثات بعد',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  itemCount: patientController.patients.length,
                  itemBuilder: (context, index) {
                    final patient = patientController.patients[index];
                    return _buildChatItem(patient.id, patient.name, patient.phoneNumber);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(String patientId, String patientName, String phoneNumber) {
    // TODO: Get last message and unread count from chat service
    final lastMessage = 'آخر رسالة...';
    final lastMessageTime = '10:30 صباحاً';
    final unreadCount = 0; // TODO: Get from chat controller

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.chat,
          arguments: {'patientId': patientId},
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
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
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
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
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (unreadCount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        lastMessageTime,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    patientName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    phoneNumber,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

