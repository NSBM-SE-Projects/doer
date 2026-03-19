import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// OTP VERIFICATION SCREEN
// Shows 6 individual input boxes for the verification code.
// As user types a digit, focus auto-moves to next box.
// Backspace moves focus back to previous box.
// Has a countdown timer for resend (30 seconds).
// ──────────────────────────────────────────────────────────────
class OtpVerificationScreen extends StatefulWidget {
  final String contact; // email or phone that code was sent to
  const OtpVerificationScreen({super.key, required this.contact});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // 6 controllers, one per digit box
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  // 6 focus nodes to control which box is active
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // Countdown timer for resend button
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
        return true; // keep counting
      }
      return false; // stop when 0
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // Combine all 6 digits into one string
  String get _otp => _controllers.map((c) => c.text).join();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Verify your account', style: AppTypography.displayMedium),
            const SizedBox(height: 12),
            // Show which email/phone the code was sent to
            Text.rich(
              TextSpan(
                text: 'We sent a verification code to ',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: widget.contact,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // 6 digit input boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: AppTypography.headlineLarge.copyWith(fontSize: 20),
                    // Only allow digits
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '', // hide the "0/1" counter
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _controllers[i].text.isNotEmpty
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      // Auto-move to next box when digit entered
                      if (value.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      // Move back on delete
                      if (value.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Verify button (only enabled when all 6 digits entered)
            DoerButton(
              label: 'Verify',
              isLoading: _isLoading,
              onPressed: _otp.length == 6
                  ? () {
                      setState(() => _isLoading = true);
                      // TODO: Verify OTP with Firebase
                      // On success → Navigator.pushReplacementNamed(context, '/');
                    }
                  : null,
            ),

            const SizedBox(height: 24),

            // Resend timer / button
            Center(
              child: _resendTimer > 0
                  ? Text(
                      'Resend code in ${_resendTimer}s',
                      style: AppTypography.bodySmall,
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() => _resendTimer = 30);
                        _startTimer();
                        // TODO: Resend OTP
                      },
                      child: Text(
                        'Resend Code',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
