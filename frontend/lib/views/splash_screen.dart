import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/routes/app_routes.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authController = Get.find<AuthController>();
    
    // التحقق من وجود توكن محفوظ أولاً
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    
    if (isLoggedIn) {
      // إذا كان هناك توكن، انتظر تحميل معلومات المستخدم
      // (قد يكون التحميل قيد التنفيذ في onInit)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final user = authController.currentUser.value;
      
      if (user != null) {
        // User is logged in, navigate to appropriate home
        print('🔀 [SplashScreen] Navigating to home for ${user.userType}');
        if (user.userType == 'patient') {
          Get.offAllNamed(AppRoutes.patientHome);
        } else if (user.userType == 'doctor') {
          Get.offAllNamed(AppRoutes.doctorHome);
        } else if (user.userType == 'receptionist') {
          Get.offAllNamed(AppRoutes.receptionHome);
        } else {
          Get.offAllNamed(AppRoutes.userSelection);
        }
        return;
      } else {
        // إذا كان هناك توكن لكن لم يتم تحميل المستخدم بعد، حاول مرة أخرى
        print('⏳ [SplashScreen] Token exists but user not loaded yet, waiting...');
        await Future.delayed(const Duration(milliseconds: 1000));
        final userRetry = authController.currentUser.value;
        if (userRetry != null) {
          if (userRetry.userType == 'patient') {
            Get.offAllNamed(AppRoutes.patientHome);
          } else if (userRetry.userType == 'doctor') {
            Get.offAllNamed(AppRoutes.doctorHome);
          } else if (userRetry.userType == 'receptionist') {
            Get.offAllNamed(AppRoutes.receptionHome);
          } else {
            Get.offAllNamed(AppRoutes.userSelection);
          }
          return;
        }
      }
    }
    
    // No user logged in, go to onboarding
    print('ℹ️ [SplashScreen] No logged in user, going to onboarding');
    Get.offAllNamed(AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 150.w,
                          height: 150.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.white.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 80.sp,
                          ),
                        ),
                        SizedBox(height: 32.h),
                        // App Name
                        Text(
                          'عيادة فرح',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'لطب الأسنان',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: AppColors.white.withValues(alpha: 0.9),
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 48.h),
                        // Loading Indicator
                        SizedBox(
                          width: 30.w,
                          height: 30.h,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
