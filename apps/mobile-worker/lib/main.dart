import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

// ──────────────────────────────────────────────────────────────
// MAIN ENTRY POINT (Worker App)
// Starts at SplashScreen, uses onGenerateRoute for navigation.
// Same warm gold theme as the customer app for brand consistency.
// ──────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: AppRoutes.splash,
      onGenerateRoute: generateRoute,
    );
  }
}
