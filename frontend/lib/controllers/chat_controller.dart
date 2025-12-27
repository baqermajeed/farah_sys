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
  
  // Track message IDs that are being sent (to show loading indicator)
  final RxList<String> sendingMessageIds = <String>[].obs;
  bool _isConnecting = false;

  @override
  void onClose() {
    // Clear sending message IDs
    sendingMessageIds.clear();
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
      
      // Clear sending message IDs when loading fresh messages
      sendingMessageIds.clear();
      
      messages.value = messagesList;
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Mark all unread messages as read when opening the chat
      final currentUser = _authController.currentUser.value;
      if (currentUser != null) {
        final unreadMessages = messagesList.where((m) => 
          !m.isRead && m.senderId != currentUser.id
        ).toList();
        
        if (unreadMessages.isNotEmpty) {
          print('📖 [ChatController] Marking ${unreadMessages.length} messages as read');
          // Mark all unread messages as read (do this in background to not block UI)
          Future.microtask(() async {
            for (final message in unreadMessages) {
              try {
                await markAsRead(message.id);
              } catch (e) {
                print('⚠️ [ChatController] Error marking message ${message.id} as read: $e');
              }
            }
          });
        }
      }
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
      print('🔌 [ChatController] Attempting to connect to Socket.IO...');
      print('🔌 [ChatController] Current patientId: $patientId');
      final connected = await socketService.connect();
      print('🔌 [ChatController] Socket connection result: $connected');
      print('🔌 [ChatController] Socket isConnected: ${socketService.isConnected}');
      
      if (!connected) {
        print('⚠️ [ChatController] Socket connection failed');
        print('⚠️ [ChatController] Attempting one more time...');
        // Try one more time with a delay
        await Future.delayed(const Duration(milliseconds: 1000));
        final retryConnected = await socketService.connect();
        print('🔌 [ChatController] Retry connection result: $retryConnected');
        
        if (!retryConnected) {
          _isConnecting = false;
          Get.snackbar(
            'تحذير',
            'فشل الاتصال بالدردشة. تأكد من اتصال الإنترنت وحاول مرة أخرى',
            duration: const Duration(seconds: 3),
          );
          return;
        }
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
          
          // Check if message already exists by ID (might have been added by message_sent)
          final existingIndex = messages.indexWhere((m) => m.id == message.id);
          if (existingIndex >= 0) {
            // Message already exists, just update it and remove from sending list
            print('🔄 [ChatController] Message already exists, updating at index $existingIndex');
            sendingMessageIds.remove(message.id);
            messages[existingIndex] = message;
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            return;
          }
          
          // Check if this is a message we sent (to avoid duplicates)
          final currentUser = _authController.currentUser.value;
          final isFromCurrentUser = currentUser != null && message.senderId == currentUser.id;
          
          if (isFromCurrentUser) {
            // This is our own message - check if we have a temp message to replace
            final tempIndex = messages.indexWhere((m) => 
              sendingMessageIds.contains(m.id) &&
              m.message == message.message &&
              m.senderId == message.senderId &&
              (m.timestamp.difference(message.timestamp).inSeconds.abs() < 10)
            );
            
            if (tempIndex >= 0) {
              // Replace temp message with server message
              print('🔄 [ChatController] Replacing temp message at index $tempIndex with server message');
              sendingMessageIds.remove(messages[tempIndex].id);
              messages[tempIndex] = message;
              messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              return; // Don't add again
            }
            // If no temp message found, message_sent will handle it
            // Don't add it here to avoid duplicates
            print('⚠️ [ChatController] Own message received but no temp message found, waiting for message_sent');
            return;
          }
          
          // For messages from others, add/update normally
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
          
          print('✅ [ChatController] Message sent successfully: id=${message.id}');
          
          // Check if message already exists (might have been added by message_received)
          final existingIndex = messages.indexWhere((m) => m.id == message.id);
          if (existingIndex >= 0) {
            // Message already exists, just remove from sending list and update
            print('🔄 [ChatController] Message already exists, updating and removing from sending list');
            sendingMessageIds.remove(message.id);
            messages[existingIndex] = message;
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            return;
          }
          
          // Find and replace temporary message with server message
          final tempIndex = messages.indexWhere((m) => 
            sendingMessageIds.contains(m.id) &&
            m.message == message.message &&
            m.senderId == message.senderId &&
            (m.timestamp.difference(message.timestamp).inSeconds.abs() < 10)
          );
          
          if (tempIndex >= 0) {
            // Remove temp ID and replace message
            print('🔄 [ChatController] Replacing temp message at index $tempIndex');
            sendingMessageIds.remove(messages[tempIndex].id);
            messages[tempIndex] = message;
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          } else {
            // If no matching temp found, just remove from sending list and add/update the message
            print('➕ [ChatController] No temp message found, adding server message');
            sendingMessageIds.remove(message.id);
            _addOrUpdateMessage(message);
          }
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
  
  // Helper method to add or update message
  void _addOrUpdateMessage(MessageModel message) {
    // Check if message already exists by ID
    final existingIndex = messages.indexWhere((m) => m.id == message.id);
    
    if (existingIndex >= 0) {
      // Message already exists, just update it
      print('🔄 [ChatController] Updating existing message at index $existingIndex: id=${message.id}');
      messages[existingIndex] = message;
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return;
    }
    
    // Add new message
    print('➕ [ChatController] Adding new message: id=${message.id}, content=${message.message}');
    messages.add(message);
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
        print('⚠️ [ChatController] Socket not connected, attempting to connect...');
        try {
          await connectSocket(currentPatientId!);
          // Wait a bit more for connection to stabilize
          await Future.delayed(const Duration(milliseconds: 1500)); // Increased delay
          if (!_chatService.socketService.isConnected) {
            print('❌ [ChatController] Socket connection failed after retry');
            // Try one more time
            print('🔄 [ChatController] Attempting final connection retry...');
            await connectSocket(currentPatientId!);
            await Future.delayed(const Duration(milliseconds: 1500));
            if (!_chatService.socketService.isConnected) {
              throw ApiException('فشل الاتصال بالدردشة. تأكد من اتصال الإنترنت وحاول مرة أخرى');
            }
          }
        } catch (e) {
          if (e is ApiException) {
            rethrow;
          }
          print('❌ [ChatController] Error connecting socket: $e');
          throw ApiException('فشل الاتصال بالدردشة. تأكد من اتصال الإنترنت وحاول مرة أخرى');
        }
      }
      
      // Create a temporary message to show with loading indicator
      final currentUser = _authController.currentUser.value;
      final tempId = 'sending_${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = MessageModel(
        id: tempId,
        senderId: currentUser?.id ?? '',
        receiverId: '',
        message: content,
        timestamp: DateTime.now().toLocal(),
        isRead: false,
      );
      
      // Add to sending list and add message to show loading indicator
      sendingMessageIds.add(tempId);
      messages.add(tempMessage);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Send via Socket.IO
      _chatService.socketService.sendMessage(
        patientId: currentPatientId!,
        content: content,
      );
      
      print('📤 [ChatController] Sent message: $content (tempId: $tempId)');
      
      // Remove from sending list and message after timeout if not confirmed (fallback)
      Future.delayed(const Duration(seconds: 10), () {
        if (sendingMessageIds.contains(tempId)) {
          print('⚠️ [ChatController] Message not confirmed, removing: $tempId');
          sendingMessageIds.remove(tempId);
          messages.removeWhere((m) => m.id == tempId);
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
      
      // Create a temporary message to show with loading indicator
      final currentUser = _authController.currentUser.value;
      final tempId = 'sending_image_${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = MessageModel(
        id: tempId,
        senderId: currentUser?.id ?? '',
        receiverId: '',
        message: content ?? '',
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: image.path, // Show local image path temporarily
      );
      
      // Add to sending list and add message to show loading indicator
      if (!sendingMessageIds.contains(tempId)) {
        sendingMessageIds.add(tempId);
      }
      messages.add(tempMessage);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      isLoading.value = true;
      
      // Upload image and send message via REST API
      // The REST API will automatically broadcast via Socket.IO
      final message = await _chatService.sendMessageWithImage(
        patientId: currentPatientId!,
        content: content,
        image: image,
      );
      
      // Find and replace temporary message with server message
      final tempIndex = messages.indexWhere((m) => m.id == tempId);
      if (tempIndex >= 0) {
        sendingMessageIds.remove(tempId);
        messages[tempIndex] = message;
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      } else {
        // If temp message was already replaced by Socket.IO, just remove from sending list
        sendingMessageIds.remove(tempId);
        // Check if message already exists (from Socket.IO)
        final exists = messages.any((m) => m.id == message.id);
        if (!exists) {
          messages.add(message);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
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
