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

  Future<void> connect() async {
    final token = await _apiService.getToken();
    if (token == null) return;

    _socket = IO.io('https://learno-school.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket connected ✅');
      joinDirect(); // انضم لغرفتك الخاصة تلقائياً
    });
    _socket!.onDisconnect((_) => print('Socket disconnected ❌'));
    _socket!.onError((data) => print('Socket error: $data'));
  }

  // ════════ الغرف العامة ════════

  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void sendMessage({required String roomId, required String content, String type = 'text'}) {
    _socket?.emit('send_message', {'roomId': roomId, 'content': content, 'type': type});
  }

  void onMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('new_message', (data) => callback(Map<String, dynamic>.from(data)));
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
    _socket?.off('new_direct_message'); // إزالة المستمعين القديمين
    _socket?.on('new_direct_message', (data) {
      final msg = Map<String, dynamic>.from(data);
      // Show Push Notification
      NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'رسالة جديدة',
          body: msg['content'] ?? 'لديك رسالة جديدة',
      );
      callback(msg);
    });
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
  }
}
