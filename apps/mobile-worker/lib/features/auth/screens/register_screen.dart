import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// REGISTER SCREEN (Worker)
// Worker account creation. Collects:
// - Full name, email, phone (+94 format)
// - NIC number (required for verification)
// - Primary skill / service category
// - Service area (district)
// - Language preference
// - Password with confirmation
// - Terms agreement
// After registration → navigates to OTP verification
// ──────────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  String _selectedLanguage = 'English';
  String _selectedSkill = 'Plumbing';
  String _selectedDistrict = 'Colombo';

  static const List<String> _districts = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale',
    'Nuwara Eliya', 'Galle', 'Matara', 'Hambantota', 'Jaffna',
    'Kilinochchi', 'Mannar', 'Mullaitivu', 'Vavuniya', 'Trincomalee',
    'Batticaloa', 'Ampara', 'Kurunegala', 'Puttalam', 'Anuradhapura',
    'Polonnaruwa', 'Badulla', 'Monaragala', 'Ratnapura', 'Kegalle',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Create worker account', style: AppTypography.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Join Doer as a worker and start earning today.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Full Name
            _buildLabel('Full Name'),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.textTertiary, size: 20),
              ),
            ),

            const SizedBox(height: 20),

            // Email
            _buildLabel('Email'),
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

            const SizedBox(height: 20),

            // Phone
            _buildLabel('Phone Number'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                hintText: '+94 7X XXX XXXX',
                prefixIcon: Icon(Icons.phone_outlined,
                    color: AppColors.textTertiary, size: 20),
              ),
            ),

            const SizedBox(height: 20),

            // NIC Number
            _buildLabel('NIC Number'),
            TextField(
              controller: _nicController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'e.g. 912345678V or 199123456789',
                prefixIcon: Icon(Icons.badge_outlined,
                    color: AppColors.textTertiary, size: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Required for identity verification',
                style: AppTypography.labelSmall,
              ),
            ),

            const SizedBox(height: 20),

            // Primary Skill
            _buildLabel('Primary Service'),
            _buildDropdown<String>(
              value: _selectedSkill,
              items: AppCategories.all.map((c) => c.name).toList(),
              onChanged: (v) => setState(() => _selectedSkill = v!),
            ),

            const SizedBox(height: 20),

            // Service Area (District)
            _buildLabel('Service Area (District)'),
            _buildDropdown<String>(
              value: _selectedDistrict,
              items: _districts,
              onChanged: (v) => setState(() => _selectedDistrict = v!),
            ),

            const SizedBox(height: 20),

            // Language
            _buildLabel('Preferred Language'),
            _buildDropdown<String>(
              value: _selectedLanguage,
              items: ['English', 'Sinhala', 'Tamil'],
              onChanged: (v) => setState(() => _selectedLanguage = v!),
            ),

            const SizedBox(height: 20),

            // Password
            _buildLabel('Password'),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Min. 8 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textTertiary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Confirm Password
            _buildLabel('Confirm Password'),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textTertiary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Terms
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeTerms,
                    onChanged: (v) => setState(() => _agreeTerms = v!),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      style: AppTypography.bodySmall,
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            DoerButton(
              label: 'Create Account',
              isLoading: _isLoading,
              onPressed: _agreeTerms
                  ? () {
                      setState(() => _isLoading = true);
                      // TODO: Call Firebase Auth register
                      // On success → navigate to OTP screen
                      // Navigator.pushNamed(context, '/otp', arguments: _emailController.text);
                    }
                  : null,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ',
                    style: AppTypography.bodySmall),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Sign In',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTypography.labelMedium),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString(), style: AppTypography.bodyMedium),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
