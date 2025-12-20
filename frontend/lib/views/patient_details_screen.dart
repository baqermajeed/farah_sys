import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';
import 'package:farah_sys_final/controllers/appointment_controller.dart';
import 'package:farah_sys_final/core/widgets/empty_state_widget.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final PatientController _patientController = Get.find<PatientController>();
  final AppointmentController _appointmentController = Get.find<AppointmentController>();
  String? patientId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Get patientId from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    patientId = args?['patientId'];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (patientId != null) {
        _appointmentController.loadDoctorAppointments();
        // Load patient notes and gallery
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (patientId != null) {
                        Get.toNamed(AppRoutes.chat, arguments: {'patientId': patientId});
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'ملف المريض',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.qr_code,
                      color: AppColors.primary,
                      size: 40.sp,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Obx(() {
                        final patient = patientId != null
                            ? _patientController.getPatientById(patientId!)
                            : null;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'الاسم : ${patient?.name ?? 'غير محدد'}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'العمر : ${patient?.age ?? 0} سنة',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'الجنس: ${patient?.gender ?? 'غير محدد'}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'رقم الهاتف : ${patient?.phoneNumber ?? 'غير محدد'}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'المدينة : ${patient?.city ?? 'غير محدد'}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'نوع العلاج : ${patient?.treatmentHistory?.join(', ') ?? 'غير محدد'}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  CircleAvatar(
                    radius: 35.r,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.person,
                      color: AppColors.white,
                      size: 35.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'السجلات'),
                  Tab(text: 'المواعيد'),
                  Tab(text: 'المعرض'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecordsTab(),
                  _buildAppointmentsTab(),
                  _buildGalleryTab(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size(double.infinity, 56.h),
                ),
                child: Text(
                  'إضافة سجل',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsTab() {
    if (patientId == null) {
      return const EmptyStateWidget(
        icon: Icons.medical_services_outlined,
        title: 'لا توجد سجلات',
      );
    }
    
    // في وضع العرض، نعرض حالة فارغة مباشرة
    return const EmptyStateWidget(
      icon: Icons.medical_services_outlined,
      title: 'لا توجد سجلات',
      subtitle: 'لم يتم إضافة أي سجلات بعد',
    );
  }
  

  Widget _buildAppointmentsTab() {
    // في وضع العرض، نستخدم Obx فقط عند الحاجة
    final appointments = _appointmentController.appointments
        .where((apt) => apt.patientId == patientId)
        .toList();
    
    if (appointments.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.calendar_today_outlined,
        title: 'لا يوجد مواعيد',
        subtitle: 'لم يتم حجز أي مواعيد بعد',
      );
    }
    
    return Obx(() {
      final updatedAppointments = _appointmentController.appointments
          .where((apt) => apt.patientId == patientId)
          .toList();
      
      if (updatedAppointments.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.calendar_today_outlined,
          title: 'لا يوجد مواعيد',
          subtitle: 'لم يتم حجز أي مواعيد بعد',
        );
      }
      
      return ListView.builder(
        padding: EdgeInsets.all(24.w),
        itemCount: updatedAppointments.length,
        itemBuilder: (context, index) {
          final appointment = updatedAppointments[index];
          final date = '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}';
          
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'موعد في ${date}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'الوقت: ${appointment.time}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (appointment.notes != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    appointment.notes!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildGalleryTab() {
    if (patientId == null) {
      return const EmptyStateWidget(
        icon: Icons.photo_library_outlined,
        title: 'لا توجد صور',
      );
    }
    
    // TODO: Load gallery from API
    return const EmptyStateWidget(
      icon: Icons.photo_library_outlined,
      title: 'لا توجد صور',
      subtitle: 'لم يتم رفع أي صور بعد',
    );
  }
}
