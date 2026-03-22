import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/api_service.dart';
import 'core/services/socket_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'features/video/incoming_call_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Restore sessions and connect real-time services
  await ApiService().init();
  await AuthService().init();
  await SocketService().connect();
  await NotificationService().init();

  // Listen for incoming video calls globally
  SocketService().onIncomingCall = (data) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callerName: data['callerName'] ?? 'Unknown',
          callerId: data['callerId'] ?? '',
          channelName: data['channelName'] ?? '',
        ),
      ));
    }
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
    ),
  );
  runApp(const DoerWorkerApp());
}

class DoerWorkerApp extends StatelessWidget {
  const DoerWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doer Worker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const _NoOverscrollBehavior(),
          child: child!,
        );
      },
      initialRoute: AppRoutes.splash,
      onGenerateRoute: generateRoute,
    );
  }
}

class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
