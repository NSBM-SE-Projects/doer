import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';

// ──────────────────────────────────────────────────────────────
// SPLASH SCREEN
// First screen shown when the worker app opens.
// Animated Doer logo for 2 seconds, then navigate to onboarding.
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

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final user = _authService.currentUser;
      if (user != null) {
        await _ensureBackendAuth(user);
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  Future<void> _ensureBackendAuth(WorkerUser user) async {
    try {
      try {
        await ApiService().login(firebaseToken: user.idToken, firebaseUid: user.uid);
      } catch (_) {
        await ApiService().register(
          firebaseToken: user.idToken,
          firebaseUid: user.uid,
          email: user.email,
          name: user.displayName ?? user.email.split('@').first,
        );
      }
    } catch (e) {
      print('Backend sync failed: $e');
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
                // Doer logo
                Image.asset(
                  'assets/images/doer_logo.png',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 8),
                Text(
                  'For Workers',
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
