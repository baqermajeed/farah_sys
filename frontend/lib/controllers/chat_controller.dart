import 'dart:io';
import 'package:get/get.dart';
import 'package:farah_sys_final/models/message_model.dart';
import 'package:farah_sys_final/services/chat_service.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/controllers/auth_controller.dart';

class ChatController extends GetxController {
  final _chatService = ChatService();
  final _authController = Get.find<AuthController>();

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isConnected = false.obs;
  String? currentPatientId;
  String? currentRoomId;
  
  // Track temporary message IDs to replace them with server messages
  final Set<String> _tempMessageIds = {};
  bool _isConnecting = false;

  @override
  void onClose() {
    // Clear temporary messages
    _tempMessageIds.clear();
    // Remove event listeners
    final socketService = _chatService.socketService;
    socketService.off('message_received');
    socketService.off('message_sent');
    socketService.off('joined_conversation');
    socketService.off('error');
    _chatService.disconnect();
    super.onClose();
  }

  // جلب الرسائل من API
  Future<void> loadMessages({
    required String patientId,
    int limit = 50,
    String? before,
  }) async {
    try {
      isLoading.value = true;
      currentPatientId = patientId;
      print('📨 [ChatController] Loading messages for patient: $patientId');

      final messagesList = await _chatService.getMessages(
        patientId: patientId,
        limit: limit,
        before: before,
      );

      print('✅ [ChatController] Loaded ${messagesList.length} messages');
      
      // Clear temporary messages when loading fresh messages
      _tempMessageIds.clear();
      
      messages.value = messagesList;
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } on ApiException catch (e) {
      print('❌ [ChatController] API Error: ${e.message}');
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      print('❌ [ChatController] Error loading messages: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل الرسائل: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // الاتصال بـ Socket.IO
  Future<void> connectSocket(String patientId) async {
    if (_isConnecting) {
      print('⚠️ [ChatController] Already connecting, skipping...');
      return;
    }
    
    try {
      _isConnecting = true;
      currentPatientId = patientId;
      print('🔌 [ChatController] Connecting socket for patient: $patientId');
      
      final socketService = _chatService.socketService;
      
      // Remove old event listeners to prevent duplicates
      socketService.off('message_received');
      socketService.off('message_sent');
      socketService.off('joined_conversation');
      socketService.off('error');
      
      // Setup connection status callback
      socketService.onConnectionStatusChanged = (connected) {
        print('🔌 [ChatController] Connection status changed: $connected');
        isConnected.value = connected;
        if (!connected) {
          _isConnecting = false;
        }
      };
      
      // Connect to Socket.IO
      final connected = await socketService.connect();
      print('🔌 [ChatController] Socket connection result: $connected');
      
      if (!connected) {
        print('⚠️ [ChatController] Socket connection failed, will retry...');
        _isConnecting = false;
        // Retry after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (currentPatientId == patientId && !_isConnecting) {
            connectSocket(patientId);
          }
        });
        return;
      }
      
      // Join conversation
      print('👤 [ChatController] Joining conversation for patient: $patientId');
      socketService.joinConversation(patientId);
      
      // Listen for messages (only once)
      socketService.on('message_received', (data) {
        try {
          print('📩 [ChatController] Received message via Socket.IO: $data');
          final messageData = data['message'] as Map<String, dynamic>? ?? data;
          final message = MessageModel.fromJson(messageData);
          
          print('📩 [ChatController] Parsed message: id=${message.id}, imageUrl=${message.imageUrl}, content=${message.message}');
          
          _addOrUpdateMessage(message);
        } catch (e) {
          print('❌ [ChatController] Error parsing message: $e');
          print('❌ [ChatController] Data: $data');
        }
      });
      
      // Listen for sent confirmation (only once)
      socketService.on('message_sent', (data) {
        try {
          print('✅ [ChatController] Message sent confirmation: $data');
          final messageData = data['message'] as Map<String, dynamic>? ?? data;
          final message = MessageModel.fromJson(messageData);
          
          print('✅ [ChatController] Replacing temp message with server message: id=${message.id}');
          
          // Replace temporary message with server message
          _addOrUpdateMessage(message, removeTemp: true);
        } catch (e) {
          print('❌ [ChatController] Error parsing sent message: $e');
          print('❌ [ChatController] Data: $data');
        }
      });
      
      // Listen for joined conversation
      socketService.on('joined_conversation', (data) {
        currentRoomId = data['room_id']?.toString();
        print('✅ Joined conversation: $currentRoomId');
      });
      
      // Listen for errors
      socketService.on('error', (data) {
        final errorMessage = data['message'] ?? 'حدث خطأ';
        Get.snackbar('خطأ', errorMessage);
      });
      
      isConnected.value = socketService.isConnected;
      _isConnecting = false;
    } catch (e) {
      print('❌ [ChatController] Error connecting socket: $e');
      Get.snackbar('خطأ', 'فشل الاتصال');
      _isConnecting = false;
    }
  }
  
  // Helper method to add or update message, removing temporary messages
  void _addOrUpdateMessage(MessageModel message, {bool removeTemp = false}) {
    // First, check if message already exists by ID (most reliable)
    final existingIndex = messages.indexWhere((m) => m.id == message.id);
    
    if (existingIndex >= 0) {
      // Message already exists, just update it
      print('🔄 [ChatController] Updating existing message at index $existingIndex: id=${message.id}');
      messages[existingIndex] = message;
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return;
    }
    
    // Remove temporary messages if this is a server message
    if (removeTemp && _tempMessageIds.isNotEmpty) {
      final removedCount = messages.length;
      // Find and remove matching temporary message by content and timestamp
      final tempIndex = messages.indexWhere((m) => 
        _tempMessageIds.contains(m.id) && 
        m.message == message.message &&
        m.senderId == message.senderId &&
        (m.timestamp.difference(message.timestamp).inSeconds.abs() < 10)
      );
      
      if (tempIndex >= 0) {
        print('🔄 [ChatController] Found matching temp message at index $tempIndex, replacing...');
        _tempMessageIds.remove(messages[tempIndex].id);
        messages[tempIndex] = message;
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return;
      }
      
      // If no matching temp found, remove all temp messages
      messages.removeWhere((m) => _tempMessageIds.contains(m.id));
      final afterRemovedCount = messages.length;
      print('🗑️ [ChatController] Removed ${removedCount - afterRemovedCount} temporary messages');
      _tempMessageIds.clear();
    }
    
    // Check again if message exists (might have been added by another handler)
    final finalIndex = messages.indexWhere((m) => m.id == message.id);
    if (finalIndex >= 0) {
      print('🔄 [ChatController] Message already exists after cleanup, updating at index $finalIndex');
      messages[finalIndex] = message;
    } else {
      // Add new message
      print('➕ [ChatController] Adding new message: id=${message.id}, content=${message.message}');
      messages.add(message);
    }
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // إرسال رسالة نصية
  Future<void> sendMessage(String content) async {
    try {
      if (currentPatientId == null) {
        throw ApiException('لا يوجد مريض محدد');
      }
      
      if (content.trim().isEmpty) {
        return;
      }
      
      // Ensure socket is connected
      if (!_chatService.socketService.isConnected) {
        await connectSocket(currentPatientId!);
        // Wait a bit for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 300));
        if (!_chatService.socketService.isConnected) {
          throw ApiException('فشل الاتصال بالدردشة');
        }
      }
      
      // Add temporary message (will be replaced by server response)
      final currentUser = _authController.currentUser.value;
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${messages.length}';
      final tempMessage = MessageModel(
        id: tempId,
        senderId: currentUser?.id ?? '',
        receiverId: '',
        message: content,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      _tempMessageIds.add(tempId);
      messages.add(tempMessage);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Send via Socket.IO
      _chatService.socketService.sendMessage(
        patientId: currentPatientId!,
        content: content,
      );
      
      print('📤 [ChatController] Sent message: $content (tempId: $tempId)');
      
      // Remove temporary message after timeout if not replaced (fallback)
      Future.delayed(const Duration(seconds: 10), () {
        if (_tempMessageIds.contains(tempId)) {
          print('⚠️ [ChatController] Temp message not replaced, removing: $tempId');
          messages.removeWhere((m) => m.id == tempId);
          _tempMessageIds.remove(tempId);
        }
      });
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      print('❌ [ChatController] Error sending message: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال الرسالة: ${e.toString()}');
    }
  }

  // إرسال رسالة مع صورة
  Future<void> sendMessageWithImage({
    String? content,
    required File image,
  }) async {
    try {
      if (currentPatientId == null) {
        throw ApiException('لا يوجد مريض محدد');
      }
      
      isLoading.value = true;
      
      // Upload image and send message via REST API
      // The REST API will automatically broadcast via Socket.IO
      final message = await _chatService.sendMessageWithImage(
        patientId: currentPatientId!,
        content: content,
        image: image,
      );
      
      // Add message to list (will also be updated via Socket.IO)
      // Check if message already exists (from Socket.IO)
      final exists = messages.any((m) => m.id == message.id);
      if (!exists) {
        messages.add(message);
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      
      print('✅ [ChatController] Image message sent: ${message.id}, imageUrl: ${message.imageUrl}');
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      print('❌ [ChatController] Error sending image: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال الصورة: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // تعليم الرسائل كمقروءة
  Future<void> markAsRead(String messageId) async {
    try {
      if (currentPatientId == null) {
        return;
      }
      
      await _chatService.markAsRead(
        patientId: currentPatientId!,
        messageId: messageId,
      );
      
      // Update local message
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        messages[index] = MessageModel(
          id: messages[index].id,
          senderId: messages[index].senderId,
          receiverId: messages[index].receiverId,
          message: messages[index].message,
          timestamp: messages[index].timestamp,
          isRead: true,
          imageUrl: messages[index].imageUrl,
        );
      }
      
      // Also mark via Socket.IO
      if (currentRoomId != null && _chatService.socketService.isConnected) {
        _chatService.socketService.markAsRead(currentRoomId!);
      }
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  // قطع الاتصال
  void disconnect() {
    if (currentRoomId != null) {
      _chatService.socketService.leaveConversation(currentRoomId!);
    }
    _chatService.disconnect();
    isConnected.value = false;
    currentPatientId = null;
    currentRoomId = null;
  }

  List<MessageModel> getUnreadMessages(String userId) {
    return messages.where((message) {
      return message.receiverId == userId && !message.isRead;
    }).toList();
  }
}
