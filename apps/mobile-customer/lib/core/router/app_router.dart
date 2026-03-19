import 'package:flutter/material.dart';
import '../../app/main_shell.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/search_screen.dart';
import '../../features/jobs/screens/post_job_screen.dart';
import '../../features/workers/screens/worker_screens.dart';
import '../../features/payments/screens/payment_screens.dart';
import '../../features/reviews/screens/review_notification_screens.dart';
import '../../features/profile/screens/profile_screens.dart';

// ──────────────────────────────────────────────────────────────
// APP ROUTER
// Central place for all route names and navigation logic.
// Uses Navigator 1.0 (onGenerateRoute) — simple and works everywhere.
// Each route name maps to a screen widget.
// ──────────────────────────────────────────────────────────────

// Route name constants — use these instead of hardcoded strings
class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/';
  static const String search = '/search';
  static const String postJob = '/post-job';
  static const String browseWorkers = '/browse-workers';
  static const String notifications = '/notifications';
  static const String payment = '/payment';
  static const String paymentHistory = '/payment-history';
  static const String settings = '/settings';
  static const String review = '/review';
}

// Route generator — MaterialApp calls this for every Navigator.pushNamed()
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
    case AppRoutes.search:
      return _buildRoute(const SearchScreen());
    case AppRoutes.postJob:
      return _buildRoute(const PostJobScreen());
    case AppRoutes.browseWorkers:
      return _buildRoute(const BrowseWorkersScreen());
    case AppRoutes.notifications:
      return _buildRoute(const NotificationsScreen());
    case AppRoutes.payment:
      return _buildRoute(const PaymentScreen());
    case AppRoutes.paymentHistory:
      return _buildRoute(const PaymentHistoryScreen());
    case AppRoutes.settings:
      return _buildRoute(const SettingsScreen());
    case AppRoutes.review:
      return _buildRoute(const RateReviewScreen());
    default:
      return _buildRoute(const MainShell());
  }
}

// Helper to create MaterialPageRoute
MaterialPageRoute _buildRoute(Widget page) {
  return MaterialPageRoute(builder: (_) => page);
}