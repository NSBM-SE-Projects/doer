import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/api_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Restore API session and connect real-time services
  await ApiService().init();
  await SocketService().connect();
  await NotificationService().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
    ),
  );

  runApp(const DoerCustomerApp());
}

class DoerCustomerApp extends StatelessWidget {
  const DoerCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: generateRoute,
    );
  }
}
