import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 4)
class MessageModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderId;

  @HiveField(2)
  final String receiverId;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final bool isRead;

  @HiveField(6)
  final String? imageUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // دعم كلا التنسيقين: Backend API و Hive
    final createdAt = json['created_at'] ?? json['timestamp'];
    DateTime dateTime;
    
    if (createdAt is String) {
      try {
        // Parse the datetime string
        // Backend sends UTC time in format: "2025-12-27T19:01:04.103+00:00"
        String timeString = createdAt.trim();
        
        // Remove timezone offset and parse as UTC
        // Format: "2025-12-27T19:01:04.103+00:00" -> "2025-12-27T19:01:04.103Z"
        if (timeString.contains('+00:00')) {
          timeString = timeString.replaceAll('+00:00', 'Z');
        } else if (timeString.contains('-00:00')) {
          timeString = timeString.replaceAll('-00:00', 'Z');
        } else if (timeString.contains('+') && !timeString.endsWith('Z')) {
          // Handle other timezone offsets by removing them and treating as UTC
          // This is a workaround - ideally backend should send consistent format
          final timezoneIndex = timeString.indexOf('+');
          if (timezoneIndex == -1) {
            final minusIndex = timeString.indexOf('-', 10); // Skip date part
            if (minusIndex > 0) {
              timeString = '${timeString.substring(0, minusIndex)}Z';
            }
          } else {
            timeString = '${timeString.substring(0, timezoneIndex)}Z';
          }
        } else if (!timeString.endsWith('Z') && !timeString.contains('+') && !timeString.contains('-', 10)) {
          // No timezone info, assume UTC
          timeString = '${timeString}Z';
        }
        
        // Parse as UTC datetime
        final parsed = DateTime.parse(timeString);
        
        // Convert UTC to local time
        dateTime = parsed.toLocal();
      } catch (e) {
        // If parsing fails, use current local time
        print('⚠️ [MessageModel] Error parsing timestamp: $createdAt, error: $e');
        dateTime = DateTime.now().toLocal();
      }
    } else if (createdAt is DateTime) {
      // If already a DateTime, convert to local if it's UTC
      dateTime = createdAt.isUtc ? createdAt.toLocal() : createdAt;
    } else {
      // Default to current local time
      dateTime = DateTime.now().toLocal();
    }
    
    return MessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_user_id']?.toString() ?? json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: json['content'] ?? json['message'] ?? '',
      timestamp: dateTime,
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      imageUrl: json['imageUrl'] ?? json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }
}
