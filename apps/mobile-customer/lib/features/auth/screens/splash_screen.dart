import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────
// SPLASH SCREEN
// First screen shown when app opens. Shows animated Doer logo
// for 2 seconds, then navigates to onboarding (or home if logged in).
// Uses AnimationController for smooth fade + scale effect.
// ──────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller drives the animation over 1.2 seconds
  late AnimationController _controller;
  // Fade from invisible (0) to visible (1)
  late Animation<double> _fadeIn;
  // Scale from 80% to 100% size (with a slight bounce via easeOutBack)
  late Animation<double> _scale;

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
    // Start the animation immediately
    _controller.forward();

    // After 2 seconds, navigate away
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // TODO: Check if user is logged in
        // If yes → navigate to home
        // If no → navigate to onboarding
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
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
        // FadeTransition makes the child fade in
        child: FadeTransition(
          opacity: _fadeIn,
          // ScaleTransition makes the child grow from 80% to 100%
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon - gold rounded square with tool icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.home_repair_service_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // App name in serif font
                Text(
                  'Doer',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                // Tagline
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
