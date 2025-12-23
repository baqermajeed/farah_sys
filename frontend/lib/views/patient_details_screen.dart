import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/core/utils/image_utils.dart';
import 'package:farah_sys_final/core/widgets/back_button_widget.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';
import 'package:farah_sys_final/controllers/appointment_controller.dart';
import 'package:farah_sys_final/controllers/gallery_controller.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final PatientController _patientController = Get.find<PatientController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  late final GalleryController _galleryController;
  final ImagePicker _imagePicker = ImagePicker();
  String? patientId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener for immediate tab change updates
    _tabController.addListener(() {
      setState(() {});
    });

    // Initialize GalleryController
    _galleryController = Get.put(GalleryController());

    // Get patientId from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    patientId = args?['patientId'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (patientId != null) {
        _appointmentController.loadDoctorAppointments();
        // Load patient gallery
        _galleryController.loadGallery(patientId!);
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
      backgroundColor: const Color(0xFFF4FEFF),
      body: SafeArea(
        child: Column(
          children: [
            // Header with light blue background
            Container(
              color: const Color(0xFFF4FEFF),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Row(
                children: [
                  // Chat icon on the right (in RTL) with notification dot
                  GestureDetector(
                    onTap: () {
                      if (patientId != null) {
                        Get.toNamed(
                          AppRoutes.chat,
                          arguments: {'patientId': patientId},
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/images/message.png',
                            width: 24.sp,
                            height: 24.sp,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10.w,
                            height: 10.h,
                            decoration: BoxDecoration(
                              color: Colors.pink,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  // Back button on the left (in RTL)
                  const BackButtonWidget(),
                ],
              ),
            ),

            // Patient Information Card
            Obx(() {
              final patient = patientId != null
                  ? _patientController.getPatientById(patientId!)
                  : null;

              if (patient == null) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: EdgeInsets.only(
                  left: 0.w,
                  top: 16.w,
                  bottom: 16.w,
                  right: 0,
                ),
                margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    // Patient Image on the right (in RTL) - first element (no margin/padding on right)
                    Container(
                      width: 105.w,
                      height: 150.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          bottomLeft: Radius.circular(16.r),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          bottomLeft: Radius.circular(16.r),
                        ),
                        child: _buildPatientImage(patient),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Container that includes Name at top and Row with details + QR code below
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 0.w,
                          top: 16.w,
                          bottom: 16.w,
                        ),
                        child: Column(
                          // crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Name at the top
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'الاسم : ${patient.name}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(height: 12.h),

                            // Row containing details column and QR code column
                            Row(
                              children: [
                                // Patient Details column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'العمر : ${patient.age} سنة',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'الجنس: ${patient.gender == 'male'
                                              ? 'ذكر'
                                              : patient.gender == 'female'
                                              ? 'أنثى'
                                              : patient.gender}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'رقم الهاتف : ${patient.phoneNumber}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'المدينة : ${patient.city}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'نوع العلاج : ${patient.treatmentHistory != null && patient.treatmentHistory!.isNotEmpty ? patient.treatmentHistory!.last : 'لا يوجد'}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 0.w),

                                // QR Code column on the left (in RTL)
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _showQrCodeDialog(context, patient.id);
                                      },
                                      child: Container(
                                        width: 70.w,
                                        height: 70.w,
                                        padding: EdgeInsets.all(0.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: QrImageView(
                                          data: patient.id,
                                          version: QrVersions.auto,
                                          size: 54.w,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    GestureDetector(
                                      onTap: () {
                                        _showTreatmentTypeDialog(
                                          context,
                                          patient,
                                        );
                                      },
                                      child: Container(
                                        width: 40.w,
                                        height: 40.w,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          color: AppColors.primary,
                                          size: 20.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Tabs
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 221, 221),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'السجلات'),
                  Tab(text: 'المواعيد'),
                  Tab(text: 'المعرض'),
                ],
              ),
            ),

            // Tab Content
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

            // Dynamic Button at the bottom based on selected tab
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Builder(
                builder: (context) {
                  final tabIndex = _tabController.index;
                  return Container(
                    width: double.infinity,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _onButtonPressed(tabIndex);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        _getButtonText(tabIndex),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsTab() {
    return Container(
      color: AppColors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.divider,
              ),
              child: Icon(Icons.block, size: 50.sp, color: AppColors.textHint),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا يوجد سجلات',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    // في وضع العرض، نستخدم Obx فقط عند الحاجة
    final appointments = _appointmentController.appointments
        .where((apt) => apt.patientId == patientId)
        .toList();

    if (appointments.isEmpty) {
      return Container(
        color: AppColors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.divider,
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 50.sp,
                  color: AppColors.textHint,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'لا يوجد مواعيد',
                style: TextStyle(fontSize: 16.sp, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      );
    }

    return Obx(() {
      final updatedAppointments = _appointmentController.appointments
          .where((apt) => apt.patientId == patientId)
          .toList();

      if (updatedAppointments.isEmpty) {
        return Container(
          color: AppColors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.divider,
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 50.sp,
                    color: AppColors.textHint,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'لا يوجد مواعيد',
                  style: TextStyle(fontSize: 16.sp, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        color: AppColors.white,
        child: ListView.builder(
          padding: EdgeInsets.all(24.w),
          itemCount: updatedAppointments.length,
          itemBuilder: (context, index) {
            final appointment = updatedAppointments[index];
            final date =
                '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}';

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
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
        ),
      );
    });
  }

  Widget _buildGalleryTab() {
    return Obx(() {
      if (_galleryController.isLoading.value) {
        return Container(
          color: AppColors.white,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      if (_galleryController.galleryImages.isEmpty) {
        return Container(
          color: AppColors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.divider,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 50.sp,
                    color: AppColors.textHint,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد صور',
                  style: TextStyle(fontSize: 16.sp, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        color: AppColors.white,
        padding: EdgeInsets.all(16.w),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 1.0,
          ),
          itemCount: _galleryController.galleryImages.length,
          itemBuilder: (context, index) {
            final image = _galleryController.galleryImages[index];
            return GestureDetector(
              onTap: () {
                _showImageDetailsDialog(context, image);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: ImageUtils.isValidImageUrl(image.imagePath)
                    ? Image.network(
                        image.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.divider,
                            child: Icon(
                              Icons.broken_image,
                              color: AppColors.textHint,
                              size: 30.sp,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppColors.divider,
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.textHint,
                          size: 30.sp,
                        ),
                      ),
              ),
            );
          },
        ),
      );
    });
  }

  String _getButtonText(int tabIndex) {
    switch (tabIndex) {
      case 0: // السجلات (Records)
        return 'اضافة سجل';
      case 1: // المواعيد (Appointments)
        return 'حجز موعد';
      case 2: // المعرض (Gallery)
        return 'اضافة صورة';
      default:
        return 'اضافة سجل';
    }
  }

  void _onButtonPressed(int tabIndex) {
    switch (tabIndex) {
      case 0: // السجلات (Records)
        // TODO: Navigate to add record screen
        break;
      case 1: // المواعيد (Appointments)
        // TODO: Navigate to book appointment screen
        break;
      case 2: // المعرض (Gallery)
        if (patientId != null) {
          _showAddImageDialog(context);
        }
        break;
    }
  }

  void _showAddImageDialog(BuildContext context) {
    File? selectedImage;
    final TextEditingController noteController = TextEditingController();
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'اضافة صورة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),

                    // Image picker button
                    GestureDetector(
                      onTap: () async {
                        if (isUploading) return;

                        try {
                          final XFile? image = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );

                          if (image != null) {
                            setDialogState(() {
                              selectedImage = File(image.path);
                            });
                          }
                        } catch (e) {
                          print(
                            '❌ [PatientDetailsScreen] Error picking image: $e',
                          );
                          if (context.mounted) {
                            Get.snackbar(
                              'خطأ',
                              'فشل اختيار الصورة. تأكد من إعطاء الأذونات المطلوبة.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: AppColors.white,
                            );
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 200.h,
                        decoration: BoxDecoration(
                          color: AppColors.divider.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1.5,
                          ),
                        ),
                        child: selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'اختر صورة',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200.h,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Note text field
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'الشرح (اختياري)',
                        labelStyle: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      maxLines: 3,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 32.h),

                    // Buttons
                    Row(
                      children: [
                        // Back button (left)
                        Expanded(
                          child: GestureDetector(
                            onTap: isUploading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Container(
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Text(
                                  'عودة',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Add button (right)
                        Expanded(
                          child: GestureDetector(
                            onTap: isUploading || selectedImage == null
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isUploading = true;
                                    });

                                    final success = await _galleryController
                                        .uploadImage(
                                          patientId!,
                                          selectedImage!,
                                          noteController.text.trim().isEmpty
                                              ? null
                                              : noteController.text.trim(),
                                        );

                                    if (context.mounted) {
                                      if (success) {
                                        Navigator.of(context).pop();
                                        Get.snackbar(
                                          'نجح',
                                          'تم رفع الصورة بنجاح',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppColors.primary,
                                          colorText: AppColors.white,
                                        );
                                      } else {
                                        Get.snackbar(
                                          'خطأ',
                                          _galleryController.errorMessage.value,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.red,
                                          colorText: AppColors.white,
                                        );
                                        setDialogState(() {
                                          isUploading = false;
                                        });
                                      }
                                    }
                                  },
                            child: Container(
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: (isUploading || selectedImage == null)
                                    ? AppColors.divider
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: isUploading
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'اضافة',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.white,
                                        ),
                                      ),
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
        );
      },
    ).then((_) {
      noteController.dispose();
    });
  }

  void _showImageDetailsDialog(BuildContext context, dynamic galleryImage) {
    // Parse date
    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(galleryImage.createdAt);
      formattedDate = DateFormat('yyyy-MM-dd HH:mm', 'ar').format(dateTime);
    } catch (e) {
      formattedDate = galleryImage.createdAt;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppColors.textPrimary,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: ImageUtils.isValidImageUrl(galleryImage.imagePath)
                      ? Image.network(
                          galleryImage.imagePath,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 300.h,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 300.h,
                              color: AppColors.divider,
                              child: Icon(
                                Icons.broken_image,
                                color: AppColors.textHint,
                                size: 50.sp,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: double.infinity,
                          height: 300.h,
                          color: AppColors.divider,
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.textHint,
                            size: 50.sp,
                          ),
                        ),
                ),
                SizedBox(height: 16.h),

                // Note (if exists)
                if (galleryImage.note != null &&
                    galleryImage.note!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.divider.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الشرح:',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          galleryImage.note!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Date
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.calendar_today,
                        size: 18.sp,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatientImage(dynamic patient) {
    // Check if imageUrl is valid (starts with http:// or https://)
    // Reject invalid schemes like 'r2-disabled://'
    final imageUrl = patient.imageUrl;

    if (ImageUtils.isValidImageUrl(imageUrl)) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPatientImage();
        },
      );
    } else {
      return _buildDefaultPatientImage();
    }
  }

  Widget _buildDefaultPatientImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          bottomLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Icon(Icons.person, color: AppColors.white, size: 50.sp),
    );
  }

  void _showQrCodeDialog(BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppColors.textPrimary,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // QR Code
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: QrImageView(
                    data: patientId,
                    version: QrVersions.auto,
                    size: 250.w,
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTreatmentTypeDialog(BuildContext context, dynamic patient) {
    // Left column treatment types
    final List<String> leftColumnTypes = ['حشوات', 'تبييض', 'قلع', 'ابتسامة'];

    // Right column treatment types
    final List<String> rightColumnTypes = ['حشوات', 'تنضيف', 'زراعة', 'تقويم'];

    // Get current selected treatments
    final Set<String> selectedTreatments = patient.treatmentHistory != null
        ? Set<String>.from(patient.treatmentHistory!)
        : <String>{};

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'قم بتحديد نوع علاج المريض',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),

                    // Treatment options in two columns
                    Row(
                      children: [
                        // Left column
                        Expanded(
                          child: Column(
                            children: leftColumnTypes
                                .map(
                                  (treatment) => _buildTreatmentOption(
                                    treatment,
                                    selectedTreatments.contains(treatment),
                                    () {
                                      setDialogState(() {
                                        if (selectedTreatments.contains(
                                          treatment,
                                        )) {
                                          selectedTreatments.remove(treatment);
                                        } else {
                                          selectedTreatments.add(treatment);
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Right column
                        Expanded(
                          child: Column(
                            children: rightColumnTypes
                                .map(
                                  (treatment) => _buildTreatmentOption(
                                    treatment,
                                    selectedTreatments.contains(treatment),
                                    () {
                                      setDialogState(() {
                                        if (selectedTreatments.contains(
                                          treatment,
                                        )) {
                                          selectedTreatments.remove(treatment);
                                        } else {
                                          selectedTreatments.add(treatment);
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),

                    // Buttons
                    Row(
                      children: [
                        // Back button (left)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Text(
                                  'عودة',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Add button (right)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Save selected treatments to patient
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Center(
                                child: Text(
                                  'اضافة',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
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
        );
      },
    );
  }

  Widget _buildTreatmentOption(
    String treatment,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14.sp, color: AppColors.white)
                  : null,
            ),
            SizedBox(width: 12.w),
            // Treatment text
            Expanded(
              child: Text(
                treatment,
                style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
