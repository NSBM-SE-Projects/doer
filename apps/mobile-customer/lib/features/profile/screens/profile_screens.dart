import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';

// ──────────────────────────────────────────────────────────────
// PROFILE SCREEN
// Customer's profile page. Shows:
//   - Avatar with camera edit button
//   - Name, email, phone
//   - Stats (jobs posted, completed, total spent)
//   - Menu sections: Account, Preferences, Support
//   - Sign out button
// ──────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _phone = '';
  int _totalJobs = 0;
  int _completedJobs = 0;
  double _totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _showLanguagePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Language'),
        children: ['English', 'Sinhala', 'Tamil'].map((lang) =>
          SimpleDialogOption(
            child: Text(lang, style: AppTypography.bodyMedium),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('c_language', lang);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language set to $lang')),
                );
              }
            },
          ),
        ).toList(),
      ),
    );
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService().getMe();
      final user = data['user'];
      final jobs = await ApiService().getMyJobs();
      final jobList = jobs['jobs'] as List;
      final completedJobs = jobList.where((j) => j['status'] == 'COMPLETED').toList();
      final totalSpent = completedJobs.fold<double>(0, (sum, j) => sum + ((j['price'] ?? 0) as num).toDouble());
      setState(() {
        _name = user['name'] ?? AuthService().currentUser?.displayName ?? '';
        _email = user['email'] ?? '';
        _phone = user['phone'] ?? '';
        _totalJobs = jobList.length;
        _completedJobs = completedJobs.length;
        _totalSpent = totalSpent;
        _isLoading = false;
      });
    } catch (_) {
      _name = AuthService().currentUser?.displayName ?? '';
      _email = AuthService().currentUser?.email ?? '';
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + info
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.surfaceVariant,
                        child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : '?',
                            style: AppTypography.displayLarge
                                .copyWith(color: AppColors.primary)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.background, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_name,
                      style: AppTypography.displaySmall),
                  const SizedBox(height: 4),
                  Text(_email, style: AppTypography.bodySmall),
                  const SizedBox(height: 2),
                  Text(_phone.isNotEmpty ? _phone : 'Not set', style: AppTypography.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Stats card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _StatColumn(value: '$_totalJobs', label: 'Jobs Posted',
                      color: AppColors.primary),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _StatColumn(value: '$_completedJobs', label: 'Completed',
                      color: AppColors.success),
                  Container(width: 1, height: 36, color: AppColors.border),
                  _StatColumn(value: _totalSpent >= 1000 ? 'Rs. ${(_totalSpent / 1000).toStringAsFixed(1)}k' : 'Rs. ${_totalSpent.toStringAsFixed(0)}', label: 'Total Spent',
                      color: AppColors.textPrimary),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account menu
            _MenuSection(title: 'Account', items: [
              _MenuItem(icon: Icons.person_outline_rounded,
                  label: 'Edit Profile', onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const _EditProfileScreen()));
                    _fetch();
                  }),
              _MenuItem(icon: Icons.location_on_outlined,
                  label: 'Saved Addresses', onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const _SavedAddressesScreen()));
                  }),
              _MenuItem(icon: Icons.payment_outlined,
                  label: 'Payment Methods', onTap: () {
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text('Payment Methods'),
                      content: const Text('Payment methods are managed through PayHere during checkout.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                    ));
                  }),
              _MenuItem(icon: Icons.receipt_long_outlined,
                  label: 'Payment History', onTap: () {
                    Navigator.pushNamed(context, '/payment-history');
                  }),
            ]),

            const SizedBox(height: 16),

            _MenuSection(title: 'Preferences', items: [
              _MenuItem(icon: Icons.language_rounded,
                  label: 'Language', trailing: 'English', onTap: () {
                    _showLanguagePicker(context);
                  }),
              _MenuItem(icon: Icons.notifications_outlined,
                  label: 'Notifications', onTap: () {
                    Navigator.pushNamed(context, '/notifications');
                  }),
              _MenuItem(icon: Icons.dark_mode_outlined,
                  label: 'Appearance', trailing: 'Light', onTap: () {
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text('Appearance'),
                      content: const Text('Dark mode coming in a future update.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                    ));
                  }),
            ]),

            const SizedBox(height: 16),

            _MenuSection(title: 'Support', items: [
              _MenuItem(icon: Icons.help_outline_rounded,
                  label: 'Help Center', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const _HelpScreen()));
                  }),
              _MenuItem(icon: Icons.shield_outlined,
                  label: 'Privacy Policy', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const _LegalScreen(title: 'Privacy Policy')));
                  }),
              _MenuItem(icon: Icons.description_outlined,
                  label: 'Terms of Service', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const _LegalScreen(title: 'Terms of Service')));
                  }),
            ]),

            const SizedBox(height: 24),

            // Sign out
            SizedBox(
              width: double.infinity,
              height: AppSizing.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Sign Out',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/splash', (route) => false);
                    }
                  }
                },
                icon: const Icon(Icons.logout_rounded,
                    size: 18, color: AppColors.error),
                label: Text('Sign Out',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text('Doer v1.0.0', style: AppTypography.labelSmall),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatColumn(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTypography.headlineLarge.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(title, style: AppTypography.labelMedium),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              return Column(
                children: [
                  if (entry.key > 0)
                    const Divider(
                        indent: 52, height: 0, color: AppColors.borderLight),
                  entry.value,
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  const _MenuItem(
      {required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            if (trailing != null) ...[
              Text(trailing!, style: AppTypography.bodySmall),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// SETTINGS SCREEN
// App settings: change password, location, delete account.
// ──────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showChangePassword(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        String? error;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null) ...[
                  Text(error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_rounded, size: 20),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading ? null : () async {
                  if (newController.text.length < 6) {
                    setDialogState(() => error = 'Password must be at least 6 characters');
                    return;
                  }
                  if (newController.text != confirmController.text) {
                    setDialogState(() => error = 'Passwords do not match');
                    return;
                  }
                  setDialogState(() { isLoading = true; error = null; });
                  try {
                    await AuthService().changePassword(
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully')),
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      error = e.toString();
                      isLoading = false;
                    });
                  }
                },
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
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
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => _showChangePassword(context)),
          _SettingsTile(
              icon: Icons.location_on_outlined,
              title: 'Location Services',
              subtitle: 'Allow Doer to access your location',
              trailing: Switch(
                  value: true, onChanged: (v) {},
                  activeThumbColor: AppColors.primary)),
          _SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              isDestructive: true,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text('This will permanently delete your account and all data. This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  try {
                    await ApiService().deleteAccount();
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ApiService.errorMessage(e))),
                      );
                    }
                  }
                }
              }),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: isDestructive
                    ? AppColors.error
                    : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.headlineSmall.copyWith(
                          color: isDestructive
                              ? AppColors.error
                              : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Edit Profile Screen ──
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();
  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getMe();
      final user = data['user'];
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(controller: _nameController, style: AppTypography.bodyMedium),
            const SizedBox(height: 20),
            Text('Phone Number', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, style: AppTypography.bodyMedium),
            const SizedBox(height: 32),
            DoerButton(
              label: 'Save Changes',
              isLoading: _isLoading,
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await ApiService().updateProfile(
                    name: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                  );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiService.errorMessage(e))));
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved Addresses Screen ──
class _SavedAddressesScreen extends StatefulWidget {
  const _SavedAddressesScreen();
  @override
  State<_SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<_SavedAddressesScreen> {
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService().getMe();
      _addressController.text = data['user']?['customerProfile']?['address'] ?? '';
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Home Address', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              style: AppTypography.bodyMedium,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Enter your address'),
            ),
            const SizedBox(height: 24),
            DoerButton(
              label: 'Save Address',
              isLoading: _isLoading,
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await ApiService().updateCustomerProfile(address: _addressController.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved')));
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiService.errorMessage(e))));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Help Screen ──
class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _FaqItem(q: 'How do I post a job?', a: 'Tap the + button on the home screen, fill in the job details, and submit.'),
          _FaqItem(q: 'How do I pay a worker?', a: 'After the job is completed, you\'ll be prompted to make a payment through PayHere.'),
          _FaqItem(q: 'How do I cancel a job?', a: 'Go to My Jobs, open the job, and tap the menu button to cancel.'),
          _FaqItem(q: 'How do I contact support?', a: 'Email us at support@doer.lk for any issues.'),
          _FaqItem(q: 'Is my payment secure?', a: 'Yes, all payments are processed through PayHere\'s secure payment gateway.'),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(q, style: AppTypography.headlineSmall),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [Text(a, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary))],
    );
  }
}

// ── Legal Screen (Privacy Policy / Terms of Service) ──
class _LegalScreen extends StatelessWidget {
  final String title;
  const _LegalScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = title.contains('Privacy');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          isPrivacy
              ? 'Privacy Policy\n\nLast updated: March 2026\n\nDoer ("we", "us", or "our") respects your privacy. This policy explains how we collect, use, and protect your personal information.\n\n1. Information We Collect\nWe collect your name, email, phone number, and location data to provide our services.\n\n2. How We Use Your Information\nYour information is used to connect you with service professionals, process payments, and improve our platform.\n\n3. Data Security\nWe use industry-standard encryption and security measures to protect your data.\n\n4. Third-Party Services\nWe use Firebase for authentication, PayHere for payments, and Google Maps for location services.\n\n5. Your Rights\nYou can request to view, update, or delete your personal data at any time through the app settings.\n\n6. Contact\nFor privacy concerns, email us at privacy@doer.lk'
              : 'Terms of Service\n\nLast updated: March 2026\n\nBy using Doer, you agree to these terms.\n\n1. Service Description\nDoer connects customers with verified home service professionals in Sri Lanka.\n\n2. User Accounts\nYou must provide accurate information when creating an account. You are responsible for maintaining your account security.\n\n3. Payments\nAll payments are processed through PayHere. Doer is not responsible for payment disputes between customers and workers.\n\n4. Worker Verification\nWorkers undergo identity verification. However, Doer does not guarantee the quality of work performed.\n\n5. Cancellation Policy\nJobs can be cancelled before a worker is assigned. Late cancellations may be subject to fees.\n\n6. Liability\nDoer acts as a platform connecting customers and workers. We are not liable for damages resulting from services provided.\n\n7. Contact\nFor questions about these terms, email legal@doer.lk',
          style: AppTypography.bodyMedium.copyWith(height: 1.8, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}