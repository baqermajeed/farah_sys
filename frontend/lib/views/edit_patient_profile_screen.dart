import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';
import 'package:farah_sys_final/core/widgets/custom_text_field.dart';
import 'package:farah_sys_final/core/widgets/gender_selector.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';

class EditPatientProfileScreen extends StatefulWidget {
  const EditPatientProfileScreen({super.key});

  @override
  State<EditPatientProfileScreen> createState() =>
      _EditPatientProfileScreenState();
}

class _EditPatientProfileScreenState extends State<EditPatientProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final PatientController _patientController = Get.find<PatientController>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? selectedGender;
  String? selectedCity;

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
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final user = _authController.currentUser.value;
    final profile = _patientController.myProfile.value;

    _nameController.text = user?.name ?? profile?.name ?? '';
    _phoneController.text = user?.phoneNumber ?? profile?.phoneNumber ?? '';
    _ageController.text = (user?.age ?? profile?.age ?? 0).toString();

    // تحويل الجنس من 'male'/'female' إلى 'ذكر'/'أنثى'
    final gender = user?.gender ?? profile?.gender;
    if (gender == 'male') {
      selectedGender = AppStrings.male;
    } else if (gender == 'female') {
      selectedGender = AppStrings.female;
    } else {
      selectedGender = gender;
    }

    selectedCity = user?.city ?? profile?.city;
  }

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            children: [
              Row(
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
                        'تعديل الملف الشخصي',
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
              SizedBox(height: 32.h),
              // Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60.r,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.person,
                      size: 60.sp,
                      color: AppColors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Add image picker
                        Get.snackbar('تنبيه', 'ميزة رفع الصورة قيد التطوير');
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              CustomTextField(
                labelText: AppStrings.name,
                hintText: 'أدخل الاسم',
                controller: _nameController,
              ),
              SizedBox(height: 24.h),
              CustomTextField(
                labelText: AppStrings.phoneNumber,
                hintText: '0000 000 0000',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                readOnly: true, // لا يمكن تعديل رقم الهاتف
              ),
              SizedBox(height: 24.h),
              CustomTextField(
                labelText: AppStrings.age,
                hintText: 'أدخل العمر',
                controller: _ageController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24.h),
              GenderSelector(
                selectedGender: selectedGender,
                onGenderChanged: (gender) {
                  setState(() {
                    selectedGender = gender;
                  });
                },
              ),
              SizedBox(height: 24.h),
              // City Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.governorate,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCity,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: Text(
                        'اختر المحافظة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                      items: cities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(
                            city,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCity = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 48.h),
              Obx(
                () => CustomButton(
                  text: 'حفظ التغييرات',
                  onPressed: _patientController.isLoading.value
                      ? null
                      : () async {
                          if (_nameController.text.isEmpty) {
                            _showResultDialog(
                              context,
                              isSuccess: false,
                              message: 'يرجى إدخال الاسم',
                            );
                            return;
                          }

                          try {
                            // تحويل الجنس من 'ذكر'/'أنثى' إلى 'male'/'female'
                            String? genderValue;
                            if (selectedGender == AppStrings.male) {
                              genderValue = 'male';
                            } else if (selectedGender == AppStrings.female) {
                              genderValue = 'female';
                            } else {
                              genderValue = selectedGender;
                            }

                            // تحديث البيانات عبر API
                            await _patientController.updateMyProfile(
                              name: _nameController.text,
                              gender: genderValue,
                              age: int.tryParse(_ageController.text),
                              city: selectedCity,
                            );

                            // العودة إلى الصفحة السابقة أولاً
                            Get.back();

                            // إظهار dialog النجاح بعد العودة
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                _showResultDialog(
                                  Get.context!,
                                  isSuccess: true,
                                  message: 'تم حفظ التغييرات بنجاح',
                                );
                              },
                            );
                          } catch (e) {
                            // العودة إلى الصفحة السابقة أولاً
                            Get.back();

                            // إظهار dialog الفشل بعد العودة
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                _showResultDialog(
                                  Get.context!,
                                  isSuccess: false,
                                  message: 'فشل حفظ التغييرات: ${e.toString()}',
                                );
                              },
                            );
                          }
                        },
                  width: double.infinity,
                  isLoading: _patientController.isLoading.value,
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog(
    BuildContext context, {
    required bool isSuccess,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                isSuccess ? 'نجح' : 'فشل',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
        );
      },
    );
  }
}
