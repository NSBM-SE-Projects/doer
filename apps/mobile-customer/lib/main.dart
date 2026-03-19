import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

// ──────────────────────────────────────────────────────────────
// MAIN ENTRY POINT
// This is where the app starts. It:
//   1. Sets status bar to dark icons (for light background)
//   2. Applies our warm gold theme
//   3. Sets splash screen as the first route
//   4. Uses our custom route generator for all navigation
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
