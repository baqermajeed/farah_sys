import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/core/utils/image_utils.dart';
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
      backgroundColor: const Color(0xFFF4FEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4FEFF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'المحادثات',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
        ),
      ),
      body: Obx(() {
        final list = patientController.patients;
        final isLoading = patientController.isLoading.value;

        // Show loading widget when loading and list is empty
        if (isLoading && list.isEmpty) {
          return const LoadingWidget(message: 'جاري تحميل المحادثات...');
        }

        if (list.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.chat_bubble_outline,
            title: 'لا توجد محادثات',
            subtitle: 'لم يتم بدء أي محادثات بعد',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemBuilder: (_, i) {
            final patient = list[i];

            // Get patient name
            String name = patient.name;

            // Get last message (placeholder for now)
            String last = 'آخر رسالة...';

            // Get unread count (placeholder for now)
            int unread = 0;

            // Get patient image
            String? userImageUrl = patient.imageUrl;

            return InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () {
                Get.toNamed(
                  AppRoutes.chat,
                  arguments: {'patientId': patient.id},
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // image at the right (في RTL)
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: (userImageUrl != null &&
                                userImageUrl.isNotEmpty &&
                                ImageUtils.isValidImageUrl(userImageUrl))
                            ? Image.network(
                                userImageUrl,
                                width: 56.w,
                                height: 56.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 56.w,
                                    height: 56.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.secondary,
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.white,
                                      size: 28.sp,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 56.w,
                                height: 56.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.white,
                                  size: 28.sp,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // name + last message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            last,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // arrow + unread badge at the end (left in RTL)
                    Column(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_left,
                          color: AppColors.textSecondary,
                        ),
                        if (unread > 0)
                          Container(
                            width: 30.w,
                            height: 30.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7CC7D0),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$unread',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) =>
              Divider(color: AppColors.divider, height: 1),
          itemCount: list.length,
        );
      }),
    );
  }
}
