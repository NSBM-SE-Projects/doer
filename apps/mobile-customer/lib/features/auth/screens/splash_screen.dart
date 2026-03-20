import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';

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
      final user = AuthService().currentUser;
      if (user != null) {
        // Verify the user has a CUSTOMER role
        final allowed = await _verifyCustomerRole();
        if (!allowed && mounted) {
          await AuthService().signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This app is for customers only. Please use the Worker app.')),
            );
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
          return;
        }
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  Future<bool> _verifyCustomerRole() async {
    try {
      final data = await ApiService().getMe();
      final role = data['user']?['role'];
      return role == 'CUSTOMER' || role == 'ADMIN';
    } catch (_) {
      return true;
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
