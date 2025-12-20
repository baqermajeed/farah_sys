import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:farah_sys_final/core/constants/app_colors.dart';
import 'package:farah_sys_final/core/widgets/empty_state_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Load notifications from controller/service
    final notifications = <NotificationItem>[
      NotificationItem(
        id: '1',
        title: 'موعد جديد',
        body: 'لديك موعد جديد مع المريض أحمد محمد',
        time: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
        type: NotificationType.appointment,
      ),
      NotificationItem(
        id: '2',
        title: 'رسالة جديدة',
        body: 'رسالة جديدة من المريض فاطمة علي',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        type: NotificationType.message,
      ),
      NotificationItem(
        id: '3',
        title: 'تذكير بالموعد',
        body: 'موعدك مع المريض محمد حسن بعد ساعة',
        time: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        type: NotificationType.reminder,
      ),
      NotificationItem(
        id: '4',
        title: 'مريض جديد',
        body: 'تم إضافة مريض جديد: علي حسين',
        time: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        type: NotificationType.patient,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                  Expanded(
                    child: Center(
                      child: Text(
                        'الإشعارات',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Mark all as read
                      Get.snackbar(
                        'نجح',
                        'تم تحديد جميع الإشعارات كمقروءة',
                        snackPosition: SnackPosition.TOP,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.done_all,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.notifications_none,
                      title: 'لا توجد إشعارات',
                      subtitle: 'لم يتم استلام أي إشعارات بعد',
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final timeAgo = _getTimeAgo(notification.time);
    final icon = _getNotificationIcon(notification.type);
    final iconColor = _getNotificationColor(notification.type);

    return GestureDetector(
      onTap: () {
        // Handle notification tap
        _handleNotificationTap(notification);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.white
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: notification.isRead
                ? AppColors.divider
                : AppColors.primary.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.divider,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return Icons.calendar_today;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.patient:
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return AppColors.primary;
      case NotificationType.message:
        return AppColors.secondary;
      case NotificationType.reminder:
        return AppColors.warning;
      case NotificationType.patient:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('yyyy/MM/dd', 'ar').format(time);
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.appointment:
        Get.toNamed('/appointments');
        break;
      case NotificationType.message:
        // Navigate to chat
        break;
      case NotificationType.reminder:
        Get.toNamed('/appointments');
        break;
      case NotificationType.patient:
        Get.toNamed('/doctor-patients-list');
        break;
      default:
        break;
    }
  }
}

enum NotificationType {
  appointment,
  message,
  reminder,
  patient,
  other,
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.type,
  });
}

