import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';

// ──────────────────────────────────────────────────────────────
// SPLASH SCREEN (with Firebase Auth check)
// Shows logo for 2 seconds, then:
//   - If user is logged in → go to home
//   - If not → go to onboarding
// ──────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // After 2 seconds, check auth state and navigate
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final user = _authService.currentUser;
      if (user != null) {
        // Ensure user is registered with backend
        await _ensureBackendAuth(user);
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  Future<void> _ensureBackendAuth(User user) async {
    final uid = user.uid;
    final email = user.email ?? '';
    final name = user.displayName ?? email.split('@').first;

    // Try login first
    try {
      await ApiService().login(firebaseToken: uid, firebaseUid: uid);
      print('Backend login OK');
      return;
    } catch (e) {
      print('Backend login failed: ${e is DioException ? '${e.response?.statusCode} ${e.response?.data}' : e}');
    }

    // Login failed — try register
    try {
      await ApiService().register(
        firebaseToken: uid,
        firebaseUid: uid,
        email: email,
        name: name,
      );
      print('Backend register OK');
    } catch (e) {
      print('Backend register failed: ${e is DioException ? '${e.response?.statusCode} ${e.response?.data}' : e}');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/doer_logo.png',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 8),
                Text(
                  'Home services, done right.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}