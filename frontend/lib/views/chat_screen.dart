import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/constants/app_strings.dart';
import 'package:farah_sys_final/controllers/chat_controller.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';
import 'package:farah_sys_final/controllers/patient_controller.dart';
import 'package:farah_sys_final/core/widgets/loading_widget.dart';
import 'package:farah_sys_final/core/widgets/back_button_widget.dart';
import 'package:farah_sys_final/core/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farah_sys_final/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final PatientController _patientController = Get.find<PatientController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  String? patientId;
  bool _isEverRegistered = false;

  @override
  void initState() {
    super.initState();
    // Get patientId from arguments or from current user
    final args = Get.arguments as Map<String, dynamic>?;
    patientId = args?['patientId'];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (patientId != null) {
        try {
          // Clear any existing messages first to prevent duplicates
          _chatController.messages.clear();

          // Load messages first
          await _chatController.loadMessages(patientId: patientId!);

          // Wait a bit before connecting socket to ensure messages are loaded
          await Future.delayed(const Duration(milliseconds: 200));

          // Then connect to socket
          await _chatController.connectSocket(patientId!);

          // Auto-scroll when new messages arrive (only register once)
          if (!_isEverRegistered) {
            _isEverRegistered = true;
            ever(_chatController.messages, (_) {
              if (_scrollController.hasClients) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            });
          }

          // Initial scroll to bottom
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } catch (e) {
          print('❌ Error initializing chat: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatController.disconnect();
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
                  SizedBox(width: 48.w),
                  Expanded(
                    child: Center(
                      child: Obx(() {
                        String displayName = 'محادثة';
                        if (patientId != null) {
                          final patient = _patientController.getPatientById(
                            patientId!,
                          );
                          if (patient != null) {
                            displayName = patient.name;
                          } else {
                            final currentUser =
                                _authController.currentUser.value;
                            if (currentUser?.userType == 'patient') {
                              // إذا كان المستخدم مريض، اعرض اسم الطبيب
                              displayName = 'طبيب';
                            } else {
                              displayName = 'مريض';
                            }
                          }
                        }
                        return Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const BackButtonWidget(),
                ],
              ),
            ),
            Divider(height: 1.h, color: AppColors.divider),
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'اليوم , 6:36 مساءً',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_chatController.isLoading.value &&
                    _chatController.messages.isEmpty) {
                  return const LoadingWidget(message: 'جاري تحميل الرسائل...');
                }

                if (_chatController.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'لا توجد رسائل بعد',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  reverse: true,
                  itemCount: _chatController.messages.length,
                  itemBuilder: (context, index) {
                    final message = _chatController
                        .messages[_chatController.messages.length - 1 - index];
                    final currentUserId =
                        _authController.currentUser.value?.id ?? '';
                    final isSent = message.senderId == currentUserId;
                    // Format time without locale
                    final hour = message.timestamp.hour;
                    final minute = message.timestamp.minute.toString().padLeft(
                      2,
                      '0',
                    );
                    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
                    final displayHour = hour > 12
                        ? hour - 12
                        : (hour == 0 ? 12 : hour);
                    final time = '$displayHour:$minute $period';

                    return _buildMessageBubble(
                      message: message,
                      isSent: isSent,
                      time: time,
                    );
                  },
                );
              }),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Send button
                  GestureDetector(
                    onTap: () async {
                      if (_messageController.text.trim().isNotEmpty &&
                          patientId != null) {
                        await _chatController.sendMessage(
                          _messageController.text.trim(),
                        );
                        _messageController.clear();
                        // Scroll to bottom
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.send,
                        color: AppColors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.writeMessage,
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textHint,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Image picker button
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.image,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && patientId != null) {
        await _chatController.sendMessageWithImage(
          image: File(image.path),
          content: _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null,
        );
        _messageController.clear();

        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل اختيار الصورة');
    }
  }

  Widget _buildMessageBubble({
    required MessageModel message,
    required bool isSent,
    required String time,
  }) {
    final imageUrl = message.imageUrl;
    final validImageUrl = imageUrl != null && imageUrl.isNotEmpty
        ? ImageUtils.convertToValidUrl(imageUrl)
        : null;
    final hasImage =
        validImageUrl != null && ImageUtils.isValidImageUrl(validImageUrl);
    final hasText = message.message.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: isSent
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 280.w),
            padding: EdgeInsets.all(hasImage ? 0 : 16.w),
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.transparent
                  : (isSent ? AppColors.primary : AppColors.white),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: CachedNetworkImage(
                      imageUrl: validImageUrl,
                      width: 280.w,
                      height: 200.h,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      memCacheWidth: 560,
                      memCacheHeight: 400,
                      placeholder: (context, url) => Container(
                        width: 280.w,
                        height: 200.h,
                        color: AppColors.background,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 280.w,
                        height: 200.h,
                        color: AppColors.background,
                        child: Icon(Icons.error, color: AppColors.error),
                      ),
                    ),
                  ),
                if (hasImage && hasText) SizedBox(height: 8.h),
                if (hasText)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hasImage ? 12.w : 0,
                      vertical: hasImage ? 12.h : 0,
                    ),
                    child: Text(
                      message.message,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isSent ? AppColors.white : AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isSent && message.isRead) ...[
                  SizedBox(width: 4.w),
                  Icon(Icons.done_all, size: 14.sp, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
