import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/home/screens/home_screen.dart';
import '../features/jobs/screens/my_jobs_screen.dart';
import '../features/jobs/screens/post_job_screen.dart';
import '../features/messaging/screens/messaging_screens.dart';
import '../features/profile/screens/profile_screens.dart';

// ──────────────────────────────────────────────────────────────
// MAIN SHELL
// The root widget after login. Contains:
//   - Bottom navigation bar with 5 items
//   - IndexedStack to keep screen state when switching tabs
//   - Center FAB (gold +) for posting a new job
// Tabs: Home, My Jobs, [Post Job FAB], Messages, Profile
// ──────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _messagesRefreshKey = 0;

  List<Widget> get _screens => [
    const HomeScreen(),
    const MyJobsScreen(),
    const SizedBox(), // placeholder — FAB opens PostJobScreen
    ConversationsScreen(key: ValueKey('msgs_$_messagesRefreshKey')),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all screens alive (preserves scroll position etc.)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border:
              Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.work_outline_rounded,
                  activeIcon: Icons.work_rounded,
                  label: 'My Jobs',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                // Center FAB — opens Post Job screen
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PostJobScreen()),
                    );
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() {
                    _currentIndex = 3;
                    _messagesRefreshKey++;
                  }),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Single nav bar item with optional badge count
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 24,
                  color:
                      isActive ? AppColors.primary : AppColors.textTertiary,
                ),
                // Unread badge (red circle with count)
                if (badge != null && badge! > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color:
                    isActive ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}