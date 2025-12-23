import 'package:get/get.dart';
import 'package:farah_sys_final/models/message_model.dart';
import 'package:farah_sys_final/services/chat_service.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';

class ChatController extends GetxController {
  final _chatService = ChatService();

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isConnected = false.obs;
  String? currentPatientId;

  @override
  void onClose() {
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

      final messagesList = await _chatService.getMessages(
        patientId: patientId,
        limit: limit,
        before: before,
      );

      messages.value = messagesList;
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحميل الرسائل');
    } finally {
      isLoading.value = false;
    }
  }

  // الاتصال بـ WebSocket
  Future<void> connectWebSocket(String patientId) async {
    try {
      currentPatientId = patientId;

      await _chatService.connectWebSocket(
        patientId: patientId,
        onMessage: (message) {
          messages.add(message);
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        },
        onConnected: () {
          isConnected.value = true;
        },
        onError: (error) {
          isConnected.value = false;
          Get.snackbar('خطأ', 'انقطع الاتصال');
        },
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل الاتصال');
    }
  }

  // إرسال رسالة
  Future<void> sendMessage(String content) async {
    try {
      if (!_chatService.isConnected) {
        if (currentPatientId != null) {
          await connectWebSocket(currentPatientId!);
        } else {
          throw ApiException('غير متصل');
        }
      }

      _chatService.sendMessage(content);

      // إضافة الرسالة محلياً (سيتم استبدالها بالرسالة من السيرفر)
      final tempMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: '', // سيتم ملؤه من السيرفر
        receiverId: '',
        message: content,
        timestamp: DateTime.now(),
        isRead: false,
      );
      messages.add(tempMessage);
    } on ApiException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال الرسالة');
    }
  }

  // قطع الاتصال
  void disconnect() {
    _chatService.disconnect();
    isConnected.value = false;
  }

  List<MessageModel> getUnreadMessages(String userId) {
    return messages.where((message) {
      return message.receiverId == userId && !message.isRead;
    }).toList();
  }
}
