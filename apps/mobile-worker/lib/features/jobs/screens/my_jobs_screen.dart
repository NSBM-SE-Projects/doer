import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// MY JOBS SCREEN
// Worker's job history with tabs:
//   - Active: accepted + in_progress jobs
//   - Applied: pending applications
//   - Completed: done jobs
// ──────────────────────────────────────────────────────────────
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('My Jobs', style: AppTypography.displaySmall),
            ),

            const SizedBox(height: 12),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  unselectedLabelStyle: AppTypography.labelMedium,
                  unselectedLabelColor: AppColors.textTertiary,
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Applied'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ActiveJobsTab(),
                  _AppliedJobsTab(),
                  _CompletedJobsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active jobs tab ──
class _ActiveJobsTab extends StatelessWidget {
  const _ActiveJobsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ActiveJobCard(
          title: 'Fix kitchen plumbing leak',
          categoryIcon: '🔧',
          status: JobStatus.inProgress,
          clientName: 'Nimal Jayawardena',
          scheduledDate: 'Today, 2:00 PM',
          budget: 'Rs. 3,500',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        ActiveJobCard(
          title: 'Install ceiling fan in master bedroom',
          categoryIcon: '⚡',
          status: JobStatus.workerAccepted,
          clientName: 'Priya Fernando',
          scheduledDate: 'Tomorrow, 9:00 AM',
          budget: 'Rs. 2,000',
          onTap: () {},
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Applied jobs tab ──
class _AppliedJobsTab extends StatelessWidget {
  const _AppliedJobsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _ApplicationCard(
          title: 'Paint exterior walls',
          categoryIcon: '🎨',
          budget: 'Rs. 8,000',
          appliedAt: '2 hours ago',
          status: 'Pending',
        ),
        const SizedBox(height: 12),
        _ApplicationCard(
          title: 'Garden maintenance - weekly',
          categoryIcon: '🌿',
          budget: 'Rs. 1,800',
          appliedAt: 'Yesterday',
          status: 'Viewed',
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String title;
  final String categoryIcon;
  final String budget;
  final String appliedAt;
  final String status;

  const _ApplicationCard({
    required this.title,
    required this.categoryIcon,
    required this.budget,
    required this.appliedAt,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(categoryIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(budget,
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Text('• $appliedAt', style: AppTypography.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completed jobs tab ──
class _CompletedJobsTab extends StatelessWidget {
  const _CompletedJobsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _CompletedJobCard(
          title: 'Fix bathroom pipe leak',
          categoryIcon: '🔧',
          clientName: 'Suresh Perera',
          completedDate: '15 Mar 2026',
          earned: 'Rs. 2,800',
          rating: 4.8,
        ),
        const SizedBox(height: 12),
        _CompletedJobCard(
          title: 'Deep clean apartment',
          categoryIcon: '🧹',
          clientName: 'Amali Senanayake',
          completedDate: '12 Mar 2026',
          earned: 'Rs. 4,200',
          rating: 5.0,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CompletedJobCard extends StatelessWidget {
  final String title;
  final String categoryIcon;
  final String clientName;
  final String completedDate;
  final String earned;
  final double rating;

  const _CompletedJobCard({
    required this.title,
    required this.categoryIcon,
    required this.clientName,
    required this.completedDate,
    required this.earned,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(categoryIcon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTypography.headlineSmall),
              ),
              Text(
                earned,
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(clientName, style: AppTypography.labelSmall),
              const SizedBox(width: 10),
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(completedDate, style: AppTypography.labelSmall),
              const Spacer(),
              RatingStars(rating: rating, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
