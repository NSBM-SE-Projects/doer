import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);

    _messaging.onTokenRefresh.listen(_registerToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessageTap(initial);
  }

  Future<void> _registerToken(String token) async {
    try { await ApiService().registerFcmToken(token); } catch (_) {}
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground: ${message.notification?.title}');
  }

  void _handleMessageTap(RemoteMessage message) {
    print('Tapped: ${message.data}');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background: ${message.notification?.title}');
}
