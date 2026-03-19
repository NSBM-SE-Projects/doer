import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

/// Handles Firebase Cloud Messaging (FCM) push notifications.
/// Registers the device token with the backend so it can send pushes.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;

  /// Initialize: request permission, get token, register with backend
  Future<void> init() async {
    // Request permission (iOS needs this, Android auto-grants)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('Push notification permission denied');
      return;
    }

    // Get FCM token and register with backend
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_registerToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      // Call backend endpoint to store this device's FCM token
      final dio = ApiService();
      await dio.registerFcmToken(token);
    } catch (e) {
      print('Failed to register FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground notification: ${message.notification?.title}');
    // The app is open — Socket.IO will handle real-time updates.
    // We could show an in-app snackbar here if needed.
  }

  void _handleMessageTap(RemoteMessage message) {
    // User tapped the notification — navigate to the relevant screen
    print('Notification tapped: ${message.data}');
    // TODO: Navigate based on message.data['type']
  }
}

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}
