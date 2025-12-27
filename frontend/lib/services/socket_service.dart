import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/network/api_constants.dart';
import '../services/auth_service.dart';

/// Socket.IO Service for real-time chat communication
class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  
  final AuthService _authService = AuthService();

  /// Callback for connection status changes
  Function(bool)? onConnectionStatusChanged;

  /// Get socket instance
  IO.Socket? get socket => _socket;
  
  /// Check if socket is connected
  bool get isConnected => _isConnected;

  /// Initialize and connect socket
  Future<bool> connect() async {
    if (_isConnected || _isConnecting) {
      return _isConnected;
    }

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      print('❌ SocketService: No token available for connection');
      return false;
    }

    try {
      _isConnecting = true;
      print('🔄 SocketService: Connecting to Socket.IO server...');

      // Connect to socket.io
      _socket = IO.io(
        ApiConstants.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .setTimeout(20000)
            .build(),
      );

      _setupEventHandlers();

      // Wait for connection
      await Future.delayed(const Duration(milliseconds: 500));

      return _isConnected;
    } catch (e) {
      print('❌ SocketService: Connection error: $e');
      _isConnecting = false;
      return false;
    }
  }

  /// Setup event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('✅ SocketService: Connected to Socket.IO server');
      _isConnected = true;
      _isConnecting = false;
      onConnectionStatusChanged?.call(true);
    });

    _socket!.onDisconnect((reason) {
      print('❌ SocketService: Disconnected: $reason');
      _isConnected = false;
      _isConnecting = false;
      onConnectionStatusChanged?.call(false);
    });

    _socket!.onConnectError((error) {
      print('❌ SocketService: Connection error: $error');
      _isConnected = false;
      _isConnecting = false;
      onConnectionStatusChanged?.call(false);
    });

    _socket!.onError((error) {
      print('❌ SocketService: Error: $error');
    });

    // Listen for reconnection events
    _socket!.onReconnect((attemptNumber) {
      print('🔄 SocketService: Reconnecting (attempt $attemptNumber)...');
    });

    _socket!.onReconnectAttempt((attemptNumber) {
      print('🔄 SocketService: Reconnection attempt $attemptNumber');
    });

    _socket!.onReconnectError((error) {
      print('❌ SocketService: Reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      print('❌ SocketService: Reconnection failed');
      _isConnected = false;
      _isConnecting = false;
      onConnectionStatusChanged?.call(false);
    });
  }

  /// Disconnect socket
  void disconnect() {
    if (_socket != null) {
      print('🔌 SocketService: Disconnecting...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      onConnectionStatusChanged?.call(false);
    }
  }

  /// Join a conversation room
  void joinConversation(String patientId) {
    if (_socket == null || !_isConnected) {
      print('⚠️ SocketService: Socket not connected, cannot join conversation');
      return;
    }

    print('👤 SocketService: Joining conversation for patient: $patientId');
    _socket!.emit('join_conversation', {'patient_id': patientId});
  }

  /// Leave a conversation room
  void leaveConversation(String roomId) {
    if (_socket == null || !_isConnected) {
      return;
    }

    print('👋 SocketService: Leaving conversation: $roomId');
    _socket!.emit('leave_conversation', {'room_id': roomId});
  }

  /// Send a message
  void sendMessage({
    required String patientId,
    String? content,
    String? imageUrl,
  }) {
    if (_socket == null || !_isConnected) {
      print('⚠️ SocketService: Socket not connected, cannot send message');
      return;
    }

    final data = {
      'patient_id': patientId,
      if (content != null && content.isNotEmpty) 'content': content,
      if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
    };

    print('📨 SocketService: Sending message to patient: $patientId');
    _socket!.emit('send_message', data);
  }

  /// Mark messages as read
  void markAsRead(String roomId) {
    if (_socket == null || !_isConnected) {
      return;
    }

    _socket!.emit('mark_read', {'room_id': roomId});
  }

  /// Listen to an event
  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      print('⚠️ SocketService: Socket not initialized, cannot listen to event: $event');
      return;
    }

    _socket!.on(event, callback);
  }

  /// Remove listener for an event
  void off(String event, [Function(dynamic)? callback]) {
    if (_socket == null) {
      return;
    }

    if (callback != null) {
      _socket!.off(event, callback);
    } else {
      _socket!.off(event);
    }
  }

  /// Reconnect socket (useful after token refresh)
  Future<bool> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    return await connect();
  }
}

