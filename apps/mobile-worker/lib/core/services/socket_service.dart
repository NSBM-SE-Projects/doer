import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Socket.IO connection for real-time messaging and notifications.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  static const _serverUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  io.Socket? _socket;
  Timer? _locationTimer;
  bool get isConnected => _socket?.connected ?? false;

  // Callbacks
  void Function(dynamic)? onNewMessage;
  void Function(dynamic)? onNewNotification;
  void Function(dynamic)? onUserTyping;
  void Function(dynamic)? onIncomingCall;
  void Function(dynamic)? onCallEnded;
  void Function(dynamic)? onCallDeclined;

  /// Connect to Socket.IO server with JWT auth
  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('w_backend_jwt');
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

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');
      // Send location immediately on connect, then every 5 minutes
      _sendLocation();
      _startLocationUpdates();
    });

    _socket!.on('new_message', (data) => onNewMessage?.call(data));
    _socket!.on('new_notification', (data) => onNewNotification?.call(data));
    _socket!.on('user_typing', (data) => onUserTyping?.call(data));
    _socket!.on('incoming_call', (data) => onIncomingCall?.call(data));
    _socket!.on('call_ended', (data) => onCallEnded?.call(data));
    _socket!.on('call_declined', (data) => onCallDeclined?.call(data));

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _stopLocationUpdates();
    });
    _socket!.onConnectError((err) => print('Socket connection error: $err'));
  }

  void joinJob(String jobId) => _socket?.emit('join_job', jobId);
  void leaveJob(String jobId) => _socket?.emit('leave_job', jobId);
  void emitTyping(String jobId) => _socket?.emit('typing', {'jobId': jobId});

  void callUser({required String targetUserId, required String channelName, required String callerName}) {
    _socket?.emit('call_user', {
      'targetUserId': targetUserId,
      'channelName': channelName,
      'callerName': callerName,
    });
  }

  void endCall({required String targetUserId}) {
    _socket?.emit('call_end', {'targetUserId': targetUserId});
  }

  void declineCall({required String targetUserId}) {
    _socket?.emit('call_decline', {'targetUserId': targetUserId});
  }

  // --- Location updates for matching algorithm ---

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _sendLocation(),
    );
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _sendLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // Check / request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _socket?.emit('location_update', {
        'lat': position.latitude,
        'lng': position.longitude,
      });
      print('Location sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Location update failed: $e');
    }
  }

  void disconnect() {
    _stopLocationUpdates();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
