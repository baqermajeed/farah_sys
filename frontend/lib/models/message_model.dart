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

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // دعم كلا التنسيقين: Backend API و Hive
    final createdAt = json['created_at'] ?? json['timestamp'];
    final dateTime = createdAt is String 
        ? DateTime.parse(createdAt)
        : (createdAt is DateTime ? createdAt : DateTime.now());
    
    return MessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_user_id']?.toString() ?? json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: json['content'] ?? json['message'] ?? '',
      timestamp: dateTime,
      isRead: json['isRead'] ?? false,
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
    };
  }
}
