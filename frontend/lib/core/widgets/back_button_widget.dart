import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';

class BackButtonWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? size;

  const BackButtonWidget({
    super.key,
    this.onTap,
    this.backgroundColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.back(),
      child: Container(
        width: size?.w ?? 48.w,
        height: size?.w ?? 48.w,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.secondary,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/back.png',
            width: 20.w,
            height: 20.h,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image not found
              return Icon(
                Icons.arrow_back,
                color: backgroundColor ?? AppColors.secondary,
                size: 20.sp,
              );
            },
          ),
        ),
      ),
    );
  }
}
