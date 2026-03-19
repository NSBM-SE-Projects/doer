import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// FORGOT PASSWORD SCREEN
// Two states:
//   1. Form state: user enters email, clicks "Send Reset Link"
//   2. Success state: shows confirmation with "Open Email App" button
// Uses setState to toggle between the two states without navigating.
// ──────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false; // toggles between form and success state

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        // Show form or success based on _sent flag
        child: _sent ? _buildSuccessState() : _buildFormState(),
      ),
    );
  }

  // ── State 1: Email input form ──
  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Lock icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: AppColors.primary, size: 26),
        ),
        const SizedBox(height: 24),
        Text('Forgot password?', style: AppTypography.displayMedium),
        const SizedBox(height: 8),
        Text(
          'No worries. Enter the email associated with your account and we\'ll send you a reset link.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        Text('Email Address', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTypography.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined,
                color: AppColors.textTertiary, size: 20),
          ),
        ),
        const SizedBox(height: 28),
        DoerButton(
          label: 'Send Reset Link',
          isLoading: _isLoading,
          onPressed: () {
            setState(() => _isLoading = true);
            // Simulate API call (2 seconds)
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _sent = true; // switch to success state
                });
              }
            });
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Back to Sign In',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── State 2: Success confirmation ──
  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Green checkmark icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 28),
        Text('Check your email', style: AppTypography.displayMedium),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text}',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        DoerButton(
          label: 'Open Email App',
          onPressed: () {
            // TODO: Open email app using url_launcher
          },
        ),
        const SizedBox(height: 16),
        // Resend link
        GestureDetector(
          onTap: () {
            setState(() => _sent = false); // go back to form
          },
          child: Text(
            'Didn\'t receive it? Resend',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
