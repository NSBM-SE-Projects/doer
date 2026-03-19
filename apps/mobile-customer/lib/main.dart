import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

// ──────────────────────────────────────────────────────────────
// MAIN ENTRY POINT
// Now with Firebase initialization.
// Firebase.initializeApp() MUST run before the app starts
// so auth, messaging, etc. are ready to use.
// ──────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before anything else
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

// Removes the stretchy overscroll effect globally
class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // no glow or stretch effect
  }
}
