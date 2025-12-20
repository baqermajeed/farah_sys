import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';
import 'package:farah_sys_final/core/widgets/custom_text_field.dart';
import 'package:farah_sys_final/core/widgets/gender_selector.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final AuthController _authController = Get.find<AuthController>();
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
        child: Column(
          children: [
            Container(
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    CircleAvatar(
                      radius: 60.r,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                      child: Icon(
                        Icons.person,
                        size: 60.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      AppStrings.login,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 32.h),
                    CustomTextField(
                      labelText: AppStrings.patientName,
                      hintText: AppStrings.enterYourName,
                      controller: _nameController,
                    ),
                    SizedBox(height: 24.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                    SizedBox(height: 48.h),
                    Obx(() => CustomButton(
                          text: AppStrings.addButton,
                          onPressed: _authController.isLoading.value
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

                                  final age = int.tryParse(_ageController.text);
                                  if (age == null || age < 1 || age > 120) {
                                    Get.snackbar(
                                      'خطأ',
                                      'يرجى إدخال عمر صحيح',
                                      snackPosition: SnackPosition.TOP,
                                    );
                                    return;
                                  }

                                  // Request OTP first
                                  await _authController.registerPatient(
                                    name: _nameController.text.trim(),
                                    phoneNumber: _phoneController.text.trim(),
                                    gender: selectedGender!,
                                    age: age,
                                    city: selectedCity!,
                                  );

                                  // Navigate to OTP verification
                                  Get.toNamed(
                                    AppRoutes.otpVerification,
                                    arguments: {
                                      'phoneNumber': _phoneController.text.trim(),
                                      'name': _nameController.text.trim(),
                                      'gender': selectedGender,
                                      'age': age,
                                      'city': selectedCity,
                                      'isRegistration': true,
                                    },
                                  );
                                },
                          width: double.infinity,
                          isLoading: _authController.isLoading.value,
                        )),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
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
