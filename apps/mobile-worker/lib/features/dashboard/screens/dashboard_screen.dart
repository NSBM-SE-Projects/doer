import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/router/app_router.dart';
import '../../jobs/screens/job_detail_screen.dart';

// ──────────────────────────────────────────────────────────────
// DASHBOARD SCREEN
// Worker's main home tab. Shows:
//   - Greeting + badge level
//   - Availability toggle (online/offline)
//   - Earnings summary card
//   - Nearby jobs (quick preview)
//   - Active job (if any)
//   - Verification status nudge
// ──────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning,',
                            style: AppTypography.bodySmall,
                          ),
                          Text(
                            'Kasun Perera',
                            style: AppTypography.displaySmall,
                          ),
                        ],
                      ),
                    ),
                    // Badge pill
                    const BadgePill(badge: BadgeLevel.silver),
                    const SizedBox(width: 10),
                    // Notification bell
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.notifications),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Availability toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isAvailable
                        ? AppColors.successLight
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isAvailable
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isAvailable
                              ? AppColors.success
                              : AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isAvailable ? 'You\'re Online' : 'You\'re Offline',
                              style: AppTypography.headlineSmall.copyWith(
                                color: _isAvailable
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _isAvailable
                                  ? 'Clients can see you in job matches'
                                  : 'You\'re hidden from job matches',
                              style: AppTypography.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: (v) => setState(() => _isAvailable = v),
                        activeColor: AppColors.success,
                        activeTrackColor: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Earnings summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const EarningsSummaryCard(
                  totalEarnings: 'Rs. 48,500',
                  pendingPayout: 'Rs. 6,200',
                  thisMonth: 'Rs. 12,800',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Verification nudge (if not fully verified)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          color: AppColors.warning, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete your verification',
                              style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.warning),
                            ),
                            Text(
                              'Upload NIC to unlock Bronze badge',
                              style: AppTypography.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/verification');
                        },
                        child: Text(
                          'Go',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Active job section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SectionHeader(
                      title: 'Active Job',
                      actionText: 'My Jobs',
                      onAction: () {},
                    ),
                    ActiveJobCard(
                      title: 'Fix kitchen plumbing leak',
                      categoryIcon: '🔧',
                      status: JobStatus.inProgress,
                      clientName: 'Nimal Jayawardena',
                      scheduledDate: 'Today, 2:00 PM',
                      budget: 'Rs. 3,500',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Nearby jobs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: 'Nearby Jobs',
                  actionText: 'Browse all',
                  onAction: () {},
                ),
              ),
            ),

            // Job listing cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  JobListingCard(
                    title: kSampleJobs[1].title,
                    category: kSampleJobs[1].category,
                    categoryIcon: kSampleJobs[1].categoryIcon,
                    budget: kSampleJobs[1].budget,
                    location: kSampleJobs[1].address,
                    distance: kSampleJobs[1].distanceKm,
                    postedAt: kSampleJobs[1].postedAt,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.jobDetail,
                      arguments: kSampleJobs[1],
                    ),
                  ),
                  const SizedBox(height: 12),
                  JobListingCard(
                    title: kSampleJobs[2].title,
                    category: kSampleJobs[2].category,
                    categoryIcon: kSampleJobs[2].categoryIcon,
                    budget: kSampleJobs[2].budget,
                    location: kSampleJobs[2].address,
                    distance: kSampleJobs[2].distanceKm,
                    postedAt: kSampleJobs[2].postedAt,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.jobDetail,
                      arguments: kSampleJobs[2],
                    ),
                  ),
                  const SizedBox(height: 12),
                  JobListingCard(
                    title: kSampleJobs[0].title,
                    category: kSampleJobs[0].category,
                    categoryIcon: kSampleJobs[0].categoryIcon,
                    budget: kSampleJobs[0].budget,
                    location: kSampleJobs[0].address,
                    distance: kSampleJobs[0].distanceKm,
                    postedAt: kSampleJobs[0].postedAt,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.jobDetail,
                      arguments: kSampleJobs[0],
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
