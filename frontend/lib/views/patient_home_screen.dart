import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';
import 'package:farah_sys_final/controllers/appointment_controller.dart';
import 'package:farah_sys_final/models/appointment_model.dart';
import 'package:farah_sys_final/core/utils/image_utils.dart';
import 'package:farah_sys_final/services/chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final ChatService _chatService = ChatService();
  final RxInt _unreadCount = 0.obs;

  @override
  void initState() {
    super.initState();
    // تأجيل تحميل البيانات حتى بعد اكتمال بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnreadCount();
      _loadData();
    });
  }

  void _loadData() {
    final patientController = Get.find<PatientController>();
    final appointmentController = Get.find<AppointmentController>();

    // تحميل البيانات فقط بدون أي تحقق أو إعادة توجيه
    print('🏠 [PatientHomeScreen] Loading data...');
    patientController.loadMyProfile().catchError((e) {
      print('❌ [PatientHomeScreen] Error loading profile: $e');
    });
    // تحميل المواعيد بشكل مستقل
    print('🏠 [PatientHomeScreen] Calling loadPatientAppointments...');
    appointmentController.loadPatientAppointments().catchError((e) {
      print('❌ [PatientHomeScreen] Error loading appointments: $e');
    });
    // تحميل معلومات الطبيب (يتم بشكل مستقل)
    patientController.loadMyDoctor().catchError((e) {
      print('❌ [PatientHomeScreen] Error loading doctor: $e');
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final chatList = await _chatService.getChatList();
      if (chatList.isNotEmpty) {
        // Patient has only one chat (with their doctor)
        final unreadCount = chatList[0]['unread_count'] as int? ?? 0;
        _unreadCount.value = unreadCount;
      } else {
        _unreadCount.value = 0;
      }
    } catch (e) {
      print('❌ Error loading unread count: $e');
      _unreadCount.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final patientController = Get.find<PatientController>();
    final appointmentController = Get.find<AppointmentController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header with icons and title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bell icon with notification badge (left side)
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.notifications);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                        // Notification badge
                        Positioned(
                          right: -4.w,
                          top: -4.h,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Title in center
                  Text(
                    AppStrings.homePage,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Profile icon (right side)
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.patientProfile);
                    },
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Welcome messages (centered)
              Column(
                children: [
                  Obx(() {
                    final user = authController.currentUser.value;
                    final profile = patientController.myProfile.value;
                    final patientName = user?.name ?? profile?.name ?? 'مريض';
                    return Text(
                      'مرحباً "$patientName"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }),
                  SizedBox(height: 4.h),
                  Text(
                    AppStrings.welcomeToClinic,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'طبيبك هو',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Doctor Card matching patient card design
              Obx(() {
                final doctor = patientController.myDoctor.value;
                final doctorName = doctor != null && doctor['name'] != null
                    ? doctor['name']!
                    : 'طبيبك';
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 0.w,
                    top: 2.h,
                    bottom: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      // Doctor Image (على اليمين في RTL - أول عنصر)
                      Transform.translate(
                        offset: Offset(-8.w, 0),
                        child: Container(
                          width: 80.w,
                          height: 85.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Builder(
                              builder: (context) {
                                final doctorImageUrl = doctor?['imageUrl'];
                                final validImageUrl =
                                    ImageUtils.convertToValidUrl(
                                      doctorImageUrl,
                                    );

                                if (validImageUrl != null &&
                                    ImageUtils.isValidImageUrl(validImageUrl)) {
                                  return CachedNetworkImage(
                                    imageUrl: validImageUrl,
                                    width: 80.w,
                                    height: 85.h,
                                    fit: BoxFit.cover,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    memCacheWidth: 160,
                                    memCacheHeight: 170,
                                    placeholder: (context, url) => Container(
                                      width: 80.w,
                                      height: 85.h,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
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
                                        size: 30.sp,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: 80.w,
                                          height: 85.h,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
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
                                            size: 30.sp,
                                          ),
                                        ),
                                  );
                                } else {
                                  return Container(
                                    width: 80.w,
                                    height: 85.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16.r),
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
                                      size: 30.sp,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // Doctor Details and Chat Icon
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            children: [
                              // Doctor Details (في المنتصف)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // الاسم مع تلوين مختلف
                                    RichText(
                                      textAlign: TextAlign.right,
                                      //  textDirection: TextDirection.rtl,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'الاسم : ',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'د. $doctorName',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      AppStrings.specialist,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.right,
                                      //   textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16.w),
                              // Chat Icon with notification dot (على اليسار في RTL - آخر عنصر)
                              GestureDetector(
                                onTap: () async {
                                  final profile =
                                      patientController.myProfile.value;
                                  if (profile != null) {
                                    await Get.toNamed(
                                      AppRoutes.chat,
                                      arguments: {'patientId': profile.id},
                                    );
                                    // Reload unread count when returning from chat
                                    // Add small delay to ensure messages are marked as read
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );
                                    _loadUnreadCount();
                                  }
                                },
                                child: Stack(
                                  children: [
                                    Image.asset(
                                      'assets/images/message.png',
                                      width: 24.sp,
                                      height: 24.sp,
                                    ),
                                    Obx(() {
                                      if (_unreadCount.value > 0) {
                                        return Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 10.w,
                                            height: 10.h,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 24.h),
              // Dental Implant Timeline Card (if patient has implant treatment)
              Obx(() {
                final profile = patientController.myProfile.value;
                final hasImplant =
                    profile?.treatmentHistory?.contains(AppStrings.implant) ??
                    false;

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
                                        color: AppColors.white.withValues(
                                          alpha: 0.9,
                                        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
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

                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.patientAppointments);
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
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Obx(() {
                final upcoming = appointmentController
                    .getUpcomingAppointments();
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

                // Get all appointments and sort them
                final allAppointments = appointmentController.appointments
                    .toList();

                // Sort appointments by date (newest first)
                allAppointments.sort((a, b) {
                  final aDate = DateTime(a.date.year, a.date.month, a.date.day);
                  final bDate = DateTime(b.date.year, b.date.month, b.date.day);
                  final aTime = _parseTime(a.time);
                  final bTime = _parseTime(b.time);
                  final aDateTime = aDate.add(
                    Duration(hours: aTime.hour, minutes: aTime.minute),
                  );
                  final bDateTime = bDate.add(
                    Duration(hours: bTime.hour, minutes: bTime.minute),
                  );
                  return bDateTime.compareTo(aDateTime);
                });

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                return Column(
                  children: [
                    if (allAppointments.isNotEmpty)
                      ...allAppointments.take(1).map((appointment) {
                        final appointmentDate = DateTime(
                          appointment.date.year,
                          appointment.date.month,
                          appointment.date.day,
                        );
                        final isPast = appointmentDate.isBefore(today);

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildAppointmentCard(
                            appointment: appointment,
                            isPast: isPast,
                          ),
                        );
                      }),
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
    required AppointmentModel appointment,
    required bool isPast,
  }) {
    final patientController = Get.find<PatientController>();
    final doctorName = appointment.doctorName.isNotEmpty
        ? appointment.doctorName
        : (patientController.myDoctor.value?['name'] ?? 'طبيبك');

    // تنسيق التاريخ
    final dateFormat = DateFormat('dd-MM-yyyy', 'ar');
    final formattedDate = dateFormat.format(appointment.date);

    // أسماء الأيام بالعربية
    final weekDays = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    final dayName = weekDays[appointment.date.weekday % 7];

    // تنسيق الوقت
    final timeParts = appointment.time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts.length > 1 ? timeParts[1] : '00';
    final isPM = hour >= 12;
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeText = '$displayHour:$minute';
    final periodText = isPM ? 'مساءاً' : 'صباحاً';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey[200] : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Spacing where image was (to prevent text from sticking to edge)
              SizedBox(width: 52.w),
              // Line 1: Doctor name text
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: isPast
                          ? 'موعدك السابق مع الدكتور "'
                          : 'موعدك القادم مع الدكتور "',
                    ),
                    TextSpan(
                      text: doctorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    TextSpan(text: '" هو'),
                  ],
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            // Appointment Details
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                // Line 2: Date row - "يوم الثلاثاء المصادف" + icon + date
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'يوم $dayName المصادف',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(width: 4.w),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.calendar_today,
                      size: 14.sp,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Line 3: Time row - "في تمام الساعة" + blue button with time + period
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'في تمام الساعة',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      periodText,
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

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
