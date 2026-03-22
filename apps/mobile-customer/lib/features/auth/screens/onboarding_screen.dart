import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// ONBOARDING SCREEN
// 3 swipeable pages introducing the app:
//   1. "Find trusted workers" - verification/safety
//   2. "Fair pricing" - workers keep 100% earnings
//   3. "Secure payments" - escrow protection
// PageView handles the swiping. Dots show which page you're on.
// ──────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // PageController lets us control which page is shown
  final _controller = PageController();
  int _currentPage = 0;

  // The 3 onboarding pages data
  final _pages = const [
    _OnboardingPage(
      icon: '🔍',
      title: 'Find trusted workers\nnear you',
      subtitle:
          'Every worker on Doer is verified with background checks and skill validation. Your safety is our priority.',
      color: AppColors.categoryPlumbing,
    ),
    _OnboardingPage(
      icon: '💰',
      title: 'Fair pricing,\nno hidden fees',
      subtitle:
          'Workers keep 100% of their earnings. Get transparent quotes with photo and video inspections before you book.',
      color: AppColors.categoryElectrical,
    ),
    _OnboardingPage(
      icon: '🛡️',
      title: 'Secure payments\nwith escrow',
      subtitle:
          'Your money is held safely until the job is done to your satisfaction. Protected transactions every time.',
      color: AppColors.categoryCleaning,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Skip button top-right
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Skip',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),

              // Swipeable pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) => _pages[index],
                ),
              ),

              // Page indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Continue / Get Started button
              DoerButton(
                label: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Continue',
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    // Go to next page
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    // Last page → go to login
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),

              const SizedBox(height: 16),

              // Show "Already have account?" on last page only
              if (_currentPage == _pages.length - 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.bodySmall,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Single onboarding page widget (used inside PageView)
// ──────────────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Big colored rounded square with emoji
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 56)),
          ),
        ),
        const SizedBox(height: 40),
        // Title in serif font
        Text(
          title,
          style: AppTypography.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Description
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
