import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/widgets/empty_state_widget.dart';
import 'package:farah_sys_final/core/widgets/loading_widget.dart';
import 'package:farah_sys_final/core/widgets/back_button_widget.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/models/patient_model.dart';
import 'package:farah_sys_final/core/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DoctorPatientsListScreen extends StatefulWidget {
  const DoctorPatientsListScreen({super.key});

  @override
  State<DoctorPatientsListScreen> createState() =>
      _DoctorPatientsListScreenState();
}

class _DoctorPatientsListScreenState extends State<DoctorPatientsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientController = Get.find<PatientController>();

    // Load patients on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      patientController.loadPatients();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add patient button on the left (in RTL)
                  GestureDetector(
                    onTap: () async {
                      final result = await Get.toNamed(AppRoutes.addPatient);
                      // Reload patients when returning from add patient screen
                      patientController.loadPatients();
                      // عرض dialog النجاح أو الفشل
                      if (result != null) {
                        _showResultDialog(result as bool);
                      }
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
                  // Title in center
                  Expanded(
                    child: Center(
                      child: Text(
                        'جميع المرضى',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Back button on the right (in RTL)
                  const BackButtonWidget(),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مريض...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14.sp,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 24.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Patients List
            Expanded(
              child: Obx(() {
                if (patientController.isLoading.value) {
                  return const LoadingWidget(message: 'جاري تحميل المرضى...');
                }

                final filteredPatients = _searchQuery.value.isEmpty
                    ? patientController.patients
                    : patientController.searchPatients(_searchQuery.value);

                if (filteredPatients.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'لا يوجد مرضى',
                    subtitle: _searchQuery.value.isEmpty
                        ? 'لم يتم إضافة أي مريض بعد'
                        : 'لم يتم العثور على نتائج',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = filteredPatients[index];
                    return _buildPatientCard(patient);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return GestureDetector(
      onTap: () {
        final patientController = Get.find<PatientController>();
        patientController.selectPatient(patient);
        Get.toNamed(
          AppRoutes.patientDetails,
          arguments: {'patientId': patient.id},
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            // Patient Image (on the right in RTL)
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: patient.imageUrl != null &&
                        ImageUtils.isValidImageUrl(patient.imageUrl)
                    ? CachedNetworkImage(
                        imageUrl:
                            ImageUtils.convertToValidUrl(patient.imageUrl) ?? '',
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (context, url, progress) =>
                            Container(
                          color: AppColors.divider,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.progress,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.divider,
                          child: Icon(
                            Icons.person,
                            color: AppColors.textSecondary,
                            size: 30.sp,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.divider,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 30.sp,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 16.w),
            // Patient Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  // Name
                  Text(
                    'الاسم : ${patient.name}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Age
                  Text(
                    'العمر : ${patient.age} سنة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Treatment Type
                  Text(
                    'نوع العلاج : ${patient.treatmentHistory != null && patient.treatmentHistory!.isNotEmpty ? patient.treatmentHistory!.last : 'لا يوجد'}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
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

  void _showResultDialog(bool success) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                  size: 64.sp,
                ),
                SizedBox(height: 16.h),
                // Title
                Text(
                  success ? 'نجح' : 'فشل',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                // Message
                Text(
                  success
                      ? 'تم إضافة المريض بنجاح'
                      : 'حدث خطأ أثناء إضافة المريض',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'موافق',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
