import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/widgets/custom_text_field.dart';
import 'package:farah_sys_final/core/widgets/gender_selector.dart';
import 'package:farah_sys_final/core/widgets/back_button_widget.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/services/patient_service.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final PatientController _patientController = Get.find<PatientController>();
  final PatientService _patientService = PatientService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? selectedGender;
  String? selectedCity;
  bool _isLoading = false;

  final List<String> cities = [
    'بغداد',
    'البصرة',
    'النجف الاشرف',
    'كربلاء',
    'الموصل',
    'أربيل',
    'السليمانية',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with padding
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 56.h),
                    SizedBox(height: 12.h),
                    // Doctor Profile Picture
                    Obx(() {
                      final user = _authController.currentUser.value;
                      return CircleAvatar(
                        radius: 60.r,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: user?.imageUrl != null
                            ? NetworkImage(user!.imageUrl!)
                            : null,
                        child: user?.imageUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60.sp,
                                color: AppColors.primary,
                              )
                            : null,
                      );
                    }),
                    SizedBox(height: 16.h),
                    // Title
                    Text(
                      'اضافة مريض',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    CustomTextField(
                      labelText: AppStrings.name,
                      hintText: AppStrings.enterYourName,
                      controller: _nameController,
                    ),
                    SizedBox(height: 24.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.gender,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        GenderSelector(
                          selectedGender: selectedGender,
                          onGenderChanged: (gender) {
                            setState(() {
                              selectedGender = gender;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    CustomTextField(
                      labelText: AppStrings.phoneNumber,
                      hintText: '0000 000 0000',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            labelText: AppStrings.city,
                            hintText: AppStrings.selectCity,
                            readOnly: true,
                            onTap: () => _showCityPicker(),
                            controller: TextEditingController(
                              text: selectedCity ?? '',
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: CustomTextField(
                            labelText: AppStrings.age,
                            hintText: AppStrings.selectCity,
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    // Add button (without icon)
                    Obx(() {
                      final isLoading = _authController.isLoading.value || _isLoading;
                      
                      return Container(
                        width: double.infinity,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: isLoading
                              ? AppColors.textHint
                              : AppColors.secondary,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading
                                ? null
                                : () async {
                                    if (_nameController.text.isEmpty ||
                                        _phoneController.text.isEmpty ||
                                        selectedGender == null ||
                                        selectedCity == null ||
                                        _ageController.text.isEmpty) {
                                      Get.snackbar(
                                        'خطأ',
                                        'يرجى ملء جميع الحقول',
                                        snackPosition: SnackPosition.TOP,
                                      );
                                      return;
                                    }

                                    final age = int.tryParse(
                                      _ageController.text,
                                    );
                                    if (age == null || age < 1 || age > 120) {
                                      Get.snackbar(
                                        'خطأ',
                                        'يرجى إدخال عمر صحيح',
                                        snackPosition: SnackPosition.TOP,
                                      );
                                      return;
                                    }

                                    final currentUserType = _authController.currentUser.value?.userType;
                                    final isReceptionistAction = currentUserType != null && currentUserType.toLowerCase() == 'receptionist';
                                    
                                    if (isReceptionistAction) {
                                      // للرسبشن: إنشاء مريض بدون ربطه بطبيب
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      
                                      try {
                                        final createdPatient = await _patientService.createPatientForReception(
                                          name: _nameController.text.trim(),
                                          phoneNumber: _phoneController.text.trim(),
                                          gender: selectedGender!,
                                          age: age,
                                          city: selectedCity!,
                                        );
                                        
                                        // تحديث قائمة المرضى في الصفحة الرئيسية
                                        await _patientController.loadPatients();
                                        
                                        if (mounted) {
                                          // إظهار dialog النجاح
                                          await showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16.r),
                                              ),
                                              title: Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: AppColors.success,
                                                    size: 24.sp,
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Text(
                                                    'نجح',
                                                    style: TextStyle(
                                                      fontSize: 18.sp,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                'تم إضافة المريض بنجاح',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.of(context).pop(); // Close dialog
                                                    // الانتقال إلى صفحة ملف المريض
                                                    await Future.delayed(const Duration(milliseconds: 100));
                                                    Get.offNamed(
                                                      AppRoutes.patientDetails,
                                                      arguments: {'patientId': createdPatient.id},
                                                    );
                                                  },
                                                  child: Text(
                                                    'حسناً',
                                                    style: TextStyle(
                                                      fontSize: 16.sp,
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      } on ApiException catch (e) {
                                        Get.snackbar(
                                          'خطأ',
                                          e.message,
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor: AppColors.error,
                                          colorText: AppColors.white,
                                        );
                                      } catch (e) {
                                        Get.snackbar(
                                          'خطأ',
                                          'فشل إضافة المريض',
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor: AppColors.error,
                                          colorText: AppColors.white,
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      }
                                    } else {
                                      // للطبيب: إضافة المريض وربطه بالطبيب مباشرة
                                      final success = await _authController.registerPatient(
                                        name: _nameController.text.trim(),
                                        phoneNumber: _phoneController.text.trim(),
                                        gender: selectedGender!,
                                        age: age,
                                        city: selectedCity!,
                                      );

                                      // العودة إلى قائمة المرضى
                                      if (mounted) {
                                        Get.back(result: success);
                                      }
                                    }
                                  },
                            borderRadius: BorderRadius.circular(16.r),
                            child: Center(
                              child: isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppColors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      AppStrings.addButton,
                                      style: TextStyle(
                                        fontFamily: 'Expo Arabic',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            // Back button positioned at top left without padding
            Positioned(top: 16.h, left: 16, child: BackButtonWidget()),
          ],
        ),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              ...cities.map((city) {
                return ListTile(
                  title: Text(
                    city,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      selectedCity = city;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
