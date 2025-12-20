import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:farah_sys_final/services/api_service.dart';
import 'package:farah_sys_final/core/network/api_constants.dart';
import 'package:farah_sys_final/core/network/api_exception.dart';
import 'package:farah_sys_final/models/message_model.dart';

class ChatService {
  final _api = ApiService();
  WebSocketChannel? _channel;
  String? _currentPatientId;

  // جلب الرسائل من API
  Future<List<MessageModel>> getMessages({
    required String patientId,
    int limit = 50,
    String? before,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (before != null) queryParams['before'] = before;

      final response = await _api.get(
        ApiConstants.chatMessages(patientId),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map((json) => MessageModel.fromJson(json))
            .toList();
      } else {
        throw ApiException('فشل جلب الرسائل');
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('فشل جلب الرسائل: ${e.toString()}');
    }
  }

  // الاتصال بـ WebSocket
  Future<void> connectWebSocket({
    required String patientId,
    required Function(MessageModel) onMessage,
    Function()? onConnected,
    Function(dynamic)? onError,
  }) async {
    try {
      // إغلاق الاتصال السابق إن وجد
      disconnect();

      final token = await _api.getToken();
      if (token == null) {
        throw ApiException('غير مصرح به');
      }
      
      final wsUrl = '${ApiConstants.wsChat(patientId)}?token=$token';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _currentPatientId = patientId;

      _channel!.stream.listen(
        (message) {
          try {
            // Parse JSON message
            Map<String, dynamic> data = {};
            if (message is String) {
              if (message.startsWith('{')) {
                data = _parseJsonString(message);
              }
            } else if (message is Map) {
              data = Map<String, dynamic>.from(message);
            }
            
            if (data.isNotEmpty) {
              final messageModel = MessageModel.fromJson(data);
              onMessage(messageModel);
            }
          } catch (e) {
            if (onError != null) onError(e);
          }
        },
        onError: (error) {
          if (onError != null) onError(error);
        },
        onDone: () {
          _channel = null;
          _currentPatientId = null;
        },
        cancelOnError: false,
      );

      if (onConnected != null) onConnected();
    } catch (e) {
      if (onError != null) onError(e);
      throw ApiException('فشل الاتصال: ${e.toString()}');
    }
  }

  // إرسال رسالة عبر WebSocket
  void sendMessage(String content) {
    if (_channel == null) {
      throw ApiException('غير متصل بـ WebSocket');
    }

    try {
      final message = {
        'message': content,
      };
      _channel!.sink.add(message.toString().replaceAll("'", '"'));
    } catch (e) {
      throw ApiException('فشل إرسال الرسالة: ${e.toString()}');
    }
  }

  // قطع الاتصال
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _currentPatientId = null;
    }
  }

  // Parse JSON string helper
  Map<String, dynamic> _parseJsonString(String jsonString) {
    try {
      // Use dart:convert for proper JSON parsing
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // التحقق من حالة الاتصال
  bool get isConnected => _channel != null;
}

