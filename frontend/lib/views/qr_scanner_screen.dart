import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/widgets/custom_button.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isScanning = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodeCapture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _isScanning = false;
        });

        // Navigate to patient details or show result
        _processScannedCode(code);
      }
    }
  }

  void _processScannedCode(String code) {
    // TODO: Call API to get patient by QR code
    // For now, show a dialog with the scanned code
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'تم مسح الرمز بنجاح',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'رمز QR:',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'سيتم البحث عن بيانات المريض...',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              setState(() {
                _isScanning = true;
              });
            },
            child: Text(
              'إعادة المسح',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14.sp,
              ),
            ),
          ),
          CustomButton(
            text: 'عرض بيانات المريض',
            onPressed: () {
              Get.back();
              // TODO: Navigate to patient details screen with the scanned code
              // Get.toNamed(AppRoutes.patientDetails, arguments: {'qrCode': code});
              Get.snackbar(
                'قريباً',
                'سيتم عرض بيانات المريض قريباً',
                snackPosition: SnackPosition.TOP,
              );
            },
            backgroundColor: AppColors.primary,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Scanner View
            MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
            ),
            // Overlay with scanning area
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.9),
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
                          'مسح رمز QR',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),
            ),
            // Scanning area indicator
            Center(
              child: Container(
                width: 250.w,
                height: 250.h,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Stack(
                  children: [
                    // Corner indicators
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.primary, width: 4),
                            left: BorderSide(color: AppColors.primary, width: 4),
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.primary, width: 4),
                            right: BorderSide(color: AppColors.primary, width: 4),
                          ),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20.r),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.primary, width: 4),
                            left: BorderSide(color: AppColors.primary, width: 4),
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20.r),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.primary, width: 4),
                            right: BorderSide(color: AppColors.primary, width: 4),
                          ),
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(20.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Instructions
            Positioned(
              bottom: 100.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.primary,
                        size: 32.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'ضع رمز QR داخل الإطار',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'سيتم مسح الرمز تلقائياً',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Flashlight toggle
            Positioned(
              bottom: 40.h,
              right: 24.w,
              child: GestureDetector(
                onTap: () {
                  _controller.toggleTorch();
                },
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flashlight_on,
                    color: AppColors.primary,
                    size: 28.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

