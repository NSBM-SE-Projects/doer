import 'package:flutter/material.dart';
import '../../app/main_shell.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/verification/screens/verification_screens.dart';
import '../../features/earnings/screens/earnings_screen.dart';

// ──────────────────────────────────────────────────────────────
// APP ROUTER
// Worker app routes. Uses Navigator 1.0 onGenerateRoute.
// ──────────────────────────────────────────────────────────────

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/';
  static const String verification = '/verification';
  static const String earnings = '/earnings';
  static const String settings = '/settings';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return _buildRoute(const SplashScreen());
    case AppRoutes.onboarding:
      return _buildRoute(const OnboardingScreen());
    case AppRoutes.login:
      return _buildRoute(const LoginScreen());
    case AppRoutes.register:
      return _buildRoute(const RegisterScreen());
    case AppRoutes.otp:
      final contact = settings.arguments as String? ?? '';
      return _buildRoute(OtpVerificationScreen(contact: contact));
    case AppRoutes.forgotPassword:
      return _buildRoute(const ForgotPasswordScreen());
    case AppRoutes.home:
      return _buildRoute(const MainShell());
    case AppRoutes.verification:
      return _buildRoute(const VerificationScreen());
    case AppRoutes.earnings:
      return _buildRoute(const EarningsScreen());
    default:
      return _buildRoute(const MainShell());
  }
}

MaterialPageRoute _buildRoute(Widget page) {
  return MaterialPageRoute(builder: (_) => page);
}
