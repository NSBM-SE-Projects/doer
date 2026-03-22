import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    // Set up local notifications (for showing foreground push)
    if (!_initialized) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );

      // Create Android notification channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'doer_notifications',
            'Doer Notifications',
            description: 'Notifications from Doer',
            importance: Importance.high,
          ));
      _initialized = true;
    }

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
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Doer',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'doer_notifications',
          'Doer Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    // Navigation can be handled here based on message.data['type']
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the system tray automatically
}
