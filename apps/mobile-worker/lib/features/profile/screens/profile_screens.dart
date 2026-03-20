import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/router/app_router.dart';

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
  double _rating = 0;
  int _totalJobs = 0;
  int _completedJobs = 0;
  int _cancelledJobs = 0;
  String _verificationStatus = 'PENDING';
  String _bio = '';
  List<String> _services = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final results = await Future.wait([
        ApiService().getMe(),
        ApiService().getMyJobs(),
      ]);
      final data = results[0];
      final user = data['user'];
      final wp = user['workerProfile'];
      final jobsData = results[1];
      final jobList = jobsData['jobs'] as List? ?? [];
      final completed = jobList.where((j) => j['status'] == 'COMPLETED').length;
      final cancelled = jobList.where((j) => j['status'] == 'CANCELLED').length;
      setState(() {
        _name = user['name'] ?? '';
        _email = user['email'] ?? '';
        _phone = user['phone'] ?? '';
        _rating = (wp?['rating'] ?? 0).toDouble();
        _totalJobs = wp?['totalJobs'] ?? 0;
        _completedJobs = completed;
        _cancelledJobs = cancelled;
        _verificationStatus = wp?['verificationStatus'] ?? 'PENDING';
        _bio = wp?['bio'] ?? '';
        final cats = wp?['categories'] as List? ?? [];
        _services = cats.map<String>((c) => c['category']?['name'] ?? '').where((s) => s.isNotEmpty).toList();
        _isLoading = false;
      });
    } catch (_) {
      _name = AuthService().currentUser?.displayName ?? '';
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile', style: AppTypography.displaySmall),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: AppColors.textSecondary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Profile card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight
                            .withValues(alpha: 0.3),
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(_name, style: AppTypography.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        _services.isNotEmpty ? _services.join(' & ') : _bio.isNotEmpty ? _bio : 'Worker',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      BadgePill(badge: _verificationStatus == 'VERIFIED'
                          ? BadgeLevel.bronze : BadgeLevel.trainee),
                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Rating', value: _rating.toStringAsFixed(1)),
                          Container(
                              width: 1, height: 32, color: AppColors.border),
                          _StatItem(label: 'Jobs Done', value: '$_totalJobs'),
                          Container(
                              width: 1, height: 32, color: AppColors.border),
                          _StatItem(label: 'Completion', value: '${(_completedJobs + _cancelledJobs) > 0 ? ((_completedJobs / (_completedJobs + _cancelledJobs)) * 100).round() : 0}%'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Edit profile button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DoerButton(
                  label: 'Edit Profile',
                  isOutlined: true,
                  icon: Icons.edit_outlined,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Skills & services
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Services Offered', style: AppTypography.headlineLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_services.isEmpty ? ['No services added'] : _services)
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(s,
                                    style: AppTypography.labelMedium
                                        .copyWith(color: AppColors.textPrimary)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Service area & rate
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Service Area',
                      value: 'Not set',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.attach_money_rounded,
                      label: 'Hourly Rate',
                      value: 'Not set',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.language_outlined,
                      label: 'Languages',
                      value: 'Not set',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: _phone.isNotEmpty ? _phone : 'Not set',
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Quick links
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.verified_user_outlined,
                      label: 'Verification Status',
                      onTap: () =>
                          Navigator.pushNamed(context, '/verification'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Earnings & Payouts',
                      onTap: () =>
                          Navigator.pushNamed(context, '/earnings'),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.star_outline_rounded,
                      label: 'Reviews & Ratings',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                    ),
                    _ProfileMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        );
                      },
                    ),
                    _ProfileMenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      isDestructive: true,
                      onTap: _signOut,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.headlineLarge),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall),
              Text(value, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDestructive ? AppColors.error : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyMedium.copyWith(color: color)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EDIT PROFILE SCREEN
// ──────────────────────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService().getMe();
      final user = data['user'];
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
    } catch (_) {}
    setState(() => _isFetching = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar change
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor:
                        AppColors.primaryLight.withValues(alpha: 0.3),
                    child: Text(
                      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _buildLabel('Full Name'),
            TextField(
              controller: _nameController,
              style: AppTypography.bodyMedium,
            ),

            const SizedBox(height: 20),

            _buildLabel('Phone Number'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: AppTypography.bodyMedium,
            ),

            const SizedBox(height: 20),

            _buildLabel('Hourly Rate (Rs.)'),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                prefixText: 'Rs. ',
              ),
            ),

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ApiService.errorMessage(e))));
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTypography.labelMedium),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// SETTINGS SCREEN
// ──────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsGroup(
            title: 'Notifications',
            items: [
              _SettingsToggleItem(
                icon: Icons.notifications_outlined,
                label: 'Job Alerts',
                value: true,
                onChanged: (_) {},
              ),
              _SettingsToggleItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'New Messages',
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Account',
            items: [
              _SettingsLinkItem(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: () {},
              ),
              _SettingsLinkItem(
                icon: Icons.language_outlined,
                label: 'Language',
                trailing: 'Sinhala',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'About',
            items: [
              _SettingsLinkItem(
                icon: Icons.info_outline_rounded,
                label: 'App Version',
                trailing: '1.0.0',
                onTap: () {},
              ),
              _SettingsLinkItem(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: AppTypography.labelMedium),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsLinkItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsLinkItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            if (trailing != null)
              Text(trailing!, style: AppTypography.labelMedium),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
