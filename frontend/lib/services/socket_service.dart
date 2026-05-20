import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
import 'notification_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final ApiService _apiService = ApiService();

  IO.Socket? get socket => _socket;

  // Active tracking for in-app push notification filtering
  static String? activeRoomId;
  static String? activeConversationId;
  String? _currentUserId;

  // Single dispatched listeners to prevent duplicate listener accumulation
  Function(Map<String, dynamic>)? _onMessageScreenCallback;
  Function(Map<String, dynamic>)? _onDirectMessageScreenCallback;

  Future<void> connect() async {
    final token = await _apiService.getToken();
    if (token == null) return;

    try {
      final profile = await _apiService.getUserProfile();
      _currentUserId = profile['id'];
    } catch (e) {
      debugPrint('SocketService profile load error: $e');
    }

    _socket = IO.io('https://learno-school.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Socket connected ✅');
      joinDirect(); // انضم لغرفتك الخاصة تلقائياً
      _setupGlobalListeners();
    });
    _socket!.onDisconnect((_) => debugPrint('Socket disconnected ❌'));
    _socket!.onError((data) => debugPrint('Socket error: $data'));
  }

  void _setupGlobalListeners() {
    // 1. Listen for new community room messages globally
    _socket?.off('new_message');
    _socket?.on('new_message', (data) {
      final msg = Map<String, dynamic>.from(data);
      final roomId = msg['roomId']?.toString();
      final senderId = msg['userId']?.toString();
      final senderName = msg['fullName'] ?? 'عضو في المجتمع';
      final content = msg['content'] ?? '';

      // Trigger notification if not in this active room and not the sender
      if (roomId != activeRoomId && senderId != _currentUserId && _currentUserId != null) {
        NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'المجتمع 👥 - $senderName',
          body: content,
        );
      }

      // Dispatch to screen if registered
      if (_onMessageScreenCallback != null) {
        _onMessageScreenCallback!(msg);
      }
    });

    // 2. Listen for new direct messages globally
    _socket?.off('new_direct_message');
    _socket?.on('new_direct_message', (data) {
      final msg = Map<String, dynamic>.from(data);
      final conversationId = msg['conversationId']?.toString();
      final senderId = msg['senderId']?.toString();
      final senderName = msg['sender']?['fullName'] ?? 'رسالة خاصة';
      final content = msg['content'] ?? '';

      // Trigger notification if not in this active conversation and not the sender
      if (conversationId != activeConversationId && senderId != _currentUserId && _currentUserId != null) {
        NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'رسالة خاصة 💬 - $senderName',
          body: content,
        );
      }

      // Dispatch to screen if registered
      if (_onDirectMessageScreenCallback != null) {
        _onDirectMessageScreenCallback!(msg);
      }
    });
  }

  // ════════ الغرف العامة ════════

  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void sendMessage({required String roomId, required String content, String type = 'text'}) {
    _socket?.emit('send_message', {'roomId': roomId, 'content': content, 'type': type});
  }

  void onMessage(Function(Map<String, dynamic>) callback) {
    _onMessageScreenCallback = callback;
  }

  void removeMessageScreenCallback() {
    _onMessageScreenCallback = null;
  }

  void deleteMessage(String roomId, String messageId) {
    _socket?.emit('delete_message', {'roomId': roomId, 'messageId': messageId});
  }

  void onMessageDeleted(Function(String) callback) {
    _socket?.on('message_deleted', (data) => callback(data['messageId']));
  }

  void onRoomHistory(Function(List<dynamic>) callback) {
    _socket?.on('room_history', (data) => callback(List<dynamic>.from(data)));
  }

  // ════════ الرسائل الخاصة ════════

  void joinDirect() {
    _socket?.emit('join_direct');
  }

  void sendDirectMessage({required String conversationId, required String content}) {
    _socket?.emit('send_direct_message', {
      'conversationId': conversationId,
      'content': content,
    });
  }

  void onDirectMessage(Function(Map<String, dynamic>) callback) {
    _onDirectMessageScreenCallback = callback;
  }

  void removeDirectMessageScreenCallback() {
    _onDirectMessageScreenCallback = null;
  }

  void notifyDmRequest(String receiverId) {
    _socket?.emit('notify_dm_request', {'receiverId': receiverId});
  }

  void onNewDmRequest(Function() callback) {
    _socket?.on('new_dm_request', (_) => callback());
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _currentUserId = null;
    _onMessageScreenCallback = null;
    _onDirectMessageScreenCallback = null;
  }
}
