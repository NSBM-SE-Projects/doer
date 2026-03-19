import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Socket.IO connection for real-time messaging and notifications.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  static const _serverUrl = 'http://10.0.2.2:3000';

  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  void Function(dynamic)? onNewMessage;
  void Function(dynamic)? onNewNotification;
  void Function(dynamic)? onUserTyping;

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('c_backend_jwt');
    if (jwt == null) return;

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': jwt})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) => print('Socket connected: ${_socket!.id}'));

    _socket!.on('new_message', (data) => onNewMessage?.call(data));
    _socket!.on('new_notification', (data) => onNewNotification?.call(data));
    _socket!.on('user_typing', (data) => onUserTyping?.call(data));

    _socket!.onDisconnect((_) => print('Socket disconnected'));
    _socket!.onConnectError((err) => print('Socket error: $err'));
  }

  void joinJob(String jobId) => _socket?.emit('join_job', jobId);
  void leaveJob(String jobId) => _socket?.emit('leave_job', jobId);
  void emitTyping(String jobId) => _socket?.emit('typing', {'jobId': jobId});

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
