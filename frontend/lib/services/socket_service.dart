import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

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

    _socket = IO.io('https://learno-school-production-2b55.up.railway.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket connected ✅');
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected ❌');
    });

    _socket!.onError((data) {
      print('Socket error: $data');
    });
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void sendMessage({
    required String roomId,
    required String content,
    String type = 'text',
  }) {
    _socket?.emit('send_message', {
      'roomId': roomId,
      'content': content,
      'type': type,
    });
  }

  void onMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('new_message', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onRoomHistory(Function(List<dynamic>) callback) {
    _socket?.on('room_history', (data) {
      callback(List<dynamic>.from(data));
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}