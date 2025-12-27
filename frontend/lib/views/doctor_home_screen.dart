import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/core/utils/image_utils.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';
import 'package:farah_sys_final/models/patient_model.dart';
import 'package:farah_sys_final/services/chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final ChatService _chatService = ChatService();
  final RxMap<String, int> _unreadCounts = <String, int>{}.obs;

  @override
  void initState() {
    super.initState();
    _loadUnreadCounts();
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final chatList = await _chatService.getChatList();
      final unreadMap = <String, int>{};
      for (var chat in chatList) {
        final patientId = chat['patient_id']?.toString();
        final unreadCount = chat['unread_count'] as int? ?? 0;
        if (patientId != null) {
          unreadMap[patientId] = unreadCount;
        }
      }
      _unreadCounts.value = unreadMap;
    } catch (e) {
      print('❌ Error loading unread counts: $e');
    }
  }

  int get _totalUnreadCount {
    return _unreadCounts.values.fold(0, (sum, count) => sum + count);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final patientController = Get.find<PatientController>();

    // Load patients on first build - فقط المرضى المرتبطين بالطبيب الحالي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // التأكد من أن نوع المستخدم هو doctor
      final userType = authController.currentUser.value?.userType;
      if (userType == 'doctor') {
        print('🏥 [DoctorHomeScreen] Loading patients for doctor...');
        patientController.loadPatients();
      } else {
        print('⚠️ [DoctorHomeScreen] User is not a doctor: $userType');
      }
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
                  // Right Profile Avatar (على اليمين في RTL)
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.doctorProfile);
                    },
                    child: Obx(() {
                      final user = authController.currentUser.value;
                      final imageUrl = user?.imageUrl;
                      final validImageUrl = ImageUtils.convertToValidUrl(
                        imageUrl,
                      );

                      return CircleAvatar(
                        radius: 20.r,
                        backgroundColor: AppColors.primary,
                        child:
                            (validImageUrl != null &&
                                ImageUtils.isValidImageUrl(validImageUrl))
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: validImageUrl,
                                  fit: BoxFit.contain,
                                  width: 40.w,
                                  height: 40.w,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                  placeholder: (context, url) =>
                                      Container(color: AppColors.primary),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    color: AppColors.white,
                                    size: 20.sp,
                                  ),
                                  memCacheWidth: 80,
                                  memCacheHeight: 80,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: AppColors.white,
                                size: 20.sp,
                              ),
                      );
                    }),
                  ),
                  // Center Title
                  Text(
                    'الصفحة الرئيسية',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Left Icons (على اليسار في RTL)
                  Row(
                    children: [
                      // Barcode Icon
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.appointments);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Image.asset(
                            'assets/images/barcode.png',
                            width: 24.sp,
                            height: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Chat Icon with notification dot
                      GestureDetector(
                        onTap: () async {
                          await Get.toNamed(AppRoutes.doctorChats);
                          // Reload unread counts when returning from chats screen
                          _loadUnreadCounts();
                        },
                        child: Obx(() {
                          final hasUnread = _totalUnreadCount > 0;
                          return Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.w),
                                child: Image.asset(
                                  'assets/images/message.png',
                                  width: 24.sp,
                                  height: 24.sp,
                                  // color: AppColors.primary,
                                ),
                              ),
                              if (hasUnread)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10.w,
                                    height: 10.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Search Bar with Calendar Icon
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.divider.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          _searchQuery.value = value;
                        },
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن مريض...',
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 24.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Calendar Icon (على اليمين في RTL)
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.appointments);
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.divider.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primary,
                            size: 24.sp,
                          ),
                        ),
                        Positioned(
                          right: 8.w,
                          top: 8.h,
                          child: Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Recent Patients Section
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'اخر المرضى',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          // Scroll arrow (optional) - على اليسار في RTL
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    // Recent Patients Horizontal List
                    // يعرض فقط المرضى المرتبطين بالطبيب الحالي (من patientController.patients)
                    Obx(() {
                      // patientController.patients يحتوي فقط على المرضى المرتبطين بالطبيب
                      // (يتم جلبهم من /doctor/patients في loadPatients())
                      final allPatients = _searchQuery.value.isEmpty
                          ? patientController.patients
                          : patientController.searchPatients(
                              _searchQuery.value,
                            );
                      final recentPatients = allPatients.take(5).toList();

                      if (recentPatients.isEmpty) {
                        return Container(
                          height: 150.h,
                          alignment: Alignment.center,
                          child: Text(
                            'لا يوجد مرضى حديثين',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 155.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          reverse:
                              false, // RTL - لا نحتاج reverse لأن العناصر تبدأ من اليمين تلقائياً
                          itemCount: recentPatients.length,
                          itemBuilder: (context, index) {
                            final patient = recentPatients[index];
                            return Padding(
                              padding: EdgeInsets.only(right: 12.w),
                              child: _buildRecentPatientCard(patient),
                            );
                          },
                        ),
                      );
                    }),
                    SizedBox(height: 32.h),
                    // All Patients Section
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.doctorPatientsList);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'جميع المرضى',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            // Scroll arrow (optional) - على اليسار في RTL
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // All Patients Vertical List
                    // يعرض فقط المرضى المرتبطين بالطبيب الحالي (من patientController.patients)
                    Obx(() {
                      // patientController.patients يحتوي فقط على المرضى المرتبطين بالطبيب
                      // (يتم جلبهم من /doctor/patients في loadPatients())
                      final allPatients = _searchQuery.value.isEmpty
                          ? patientController.patients
                          : patientController.searchPatients(
                              _searchQuery.value,
                            );

                      if (patientController.isLoading.value) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.h),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      if (allPatients.isEmpty) {
                        return Container(
                          padding: EdgeInsets.all(32.h),
                          alignment: Alignment.center,
                          child: Text(
                            'لا يوجد مرضى',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allPatients.length,
                        itemBuilder: (context, index) {
                          final patient = allPatients[index];
                          return _buildAllPatientCard(patient);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPatientCard(PatientModel patient) {
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
        width: 100.w,
        padding: EdgeInsets.only(top: 6.w, bottom: 6.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.divider.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Patient Image
            Container(
              width: 85.w,
              height: 90.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child:
                    (patient.imageUrl != null &&
                        ImageUtils.isValidImageUrl(patient.imageUrl))
                    ? Image.network(
                        patient.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
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
                              size: 24.sp,
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppColors.white,
                          size: 24.sp,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 8.w),
            // Patient Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  // Patient Name
                  Text(
                    patient.name.split(' ').first, // First name only
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6.h),
                  // Treatment Type
                  Text(
                    patient.treatmentHistory != null &&
                            patient.treatmentHistory!.isNotEmpty
                        ? patient.treatmentHistory!.last
                        : 'لا يوجد',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPatientCard(PatientModel patient) {
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
        padding: EdgeInsets.only(left: 20.w, right: 0.w, top: 2.h, bottom: 2.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            // Patient Image (على اليمين في RTL - أول عنصر)
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
                  child:
                      (patient.imageUrl != null &&
                          ImageUtils.isValidImageUrl(patient.imageUrl))
                      ? Image.network(
                          patient.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppColors.white,
                            size: 30.sp,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Patient Details and Chat Icon in a Row with padding
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  children: [
                    // Patient Details (في المنتصف)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          // الاسم مع تلوين مختلف
                          RichText(
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
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
                                  text: patient.name,
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
                            'العمر : ${patient.age} سنة',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'نوع العلاج : ${patient.treatmentHistory != null && patient.treatmentHistory!.isNotEmpty ? patient.treatmentHistory!.last : 'لا يوجد'}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // Chat Icon with notification dot (على اليسار في RTL - آخر عنصر)
                    GestureDetector(
                      onTap: () async {
                        await Get.toNamed(
                          AppRoutes.chat,
                          arguments: {'patientId': patient.id},
                        );
                        // Reload unread counts when returning from chat
                        _loadUnreadCounts();
                      },
                      child: Obx(() {
                        final unreadCount = _unreadCounts[patient.id] ?? 0;
                        return Stack(
                          children: [
                            Image.asset(
                              'assets/images/message.png',
                              width: 24.sp,
                              height: 24.sp,
                              //  color: AppColors.primary,
                            ),
                            if (unreadCount > 0)
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
                                      color: AppColors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
