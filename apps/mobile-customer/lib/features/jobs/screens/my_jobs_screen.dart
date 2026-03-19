import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// MY JOBS SCREEN
// Tabbed view with 3 tabs: Active, Completed, Cancelled.
// Each tab shows a list of JobCards filtered by status.
// Has a FAB to post a new job.
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
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: AppTypography.labelLarge,
          unselectedLabelStyle: AppTypography.labelMedium,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active jobs
          _buildJobList(isActive: true),
          // Completed jobs
          _buildJobList(isActive: false),
          // Cancelled - show empty state
          const EmptyState(
            icon: '📭',
            title: 'No cancelled jobs',
            subtitle: 'Jobs you cancel will appear here.',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/post-job');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Job'),
      ),
    );
  }

  Widget _buildJobList({required bool isActive}) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        JobCard(
          title: 'Fix kitchen sink leak',
          category: 'Plumbing',
          categoryIcon: '🔧',
          status: isActive ? JobStatus.inProgress : JobStatus.completed,
          budget: 'Rs. 5,000',
          date: 'Today',
          workerName: 'Saman F.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobDetailScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        JobCard(
          title: 'Paint bedroom walls',
          category: 'Painting',
          categoryIcon: '🎨',
          status: isActive ? JobStatus.posted : JobStatus.reviewed,
          budget: 'Rs. 15,000',
          date: 'Mar 25',
          onTap: () {},
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// JOB DETAIL SCREEN
// Full view of a single job. Sections:
//   1. Header: category icon + title + status pill
//   2. Timeline: visual progress (Posted → Matched → In Progress → Done)
//   3. Worker card: assigned worker with chat/call buttons
//   4. Job details: description, budget, date, location, urgency
//   5. Payment info: agreed price + escrow status
//   6. Bottom bar: Cancel Job / Release Payment buttons
// ──────────────────────────────────────────────────────────────
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Job Details'),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Header ──
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.categoryPlumbing,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                      child: Text('🔧', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fix kitchen sink leak',
                          style: AppTypography.headlineLarge),
                      const SizedBox(height: 4),
                      Text('Plumbing', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                const JobStatusPill(status: JobStatus.inProgress),
              ],
            ),

            const SizedBox(height: 24),

            // ── 2. Timeline ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Timeline', style: AppTypography.headlineMedium),
                  const SizedBox(height: 16),
                  _TimelineItem(
                      title: 'Job Posted',
                      subtitle: 'Mar 18, 2026 · 9:30 AM',
                      isCompleted: true,
                      isFirst: true),
                  _TimelineItem(
                      title: 'Worker Matched',
                      subtitle: 'Saman Fernando accepted',
                      isCompleted: true),
                  _TimelineItem(
                      title: 'In Progress',
                      subtitle: 'Worker is on the way',
                      isActive: true),
                  _TimelineItem(
                      title: 'Completed',
                      subtitle: 'Pending',
                      isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 3. Worker info ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Text('S',
                        style: AppTypography.headlineMedium
                            .copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saman Fernando',
                            style: AppTypography.headlineSmall),
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 14, color: AppColors.badgeGold),
                            const SizedBox(width: 3),
                            Text('4.5', style: AppTypography.labelMedium),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.badgeSilver.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Silver',
                                  style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chat button
                  _ActionIcon(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary,
                      onTap: () {}),
                  const SizedBox(width: 4),
                  // Call button
                  _ActionIcon(
                      icon: Icons.phone_outlined,
                      color: AppColors.success,
                      onTap: () {}),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 4. Job details ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: AppTypography.headlineMedium),
                  const SizedBox(height: 14),
                  Text(
                    'The kitchen sink has been leaking from the base for about a week. Water pools under the cabinet. May need to replace the seal or the entire faucet.',
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Budget',
                      value: 'Rs. 3,000 — Rs. 5,000'),
                  const SizedBox(height: 12),
                  _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Scheduled',
                      value: 'Mar 19, 2026 · 10:00 AM'),
                  const SizedBox(height: 12),
                  _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: '42 Galle Road, Colombo 03'),
                  const SizedBox(height: 12),
                  _DetailRow(
                      icon: Icons.bolt_rounded,
                      label: 'Urgency',
                      value: 'Normal'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 5. Payment ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment', style: AppTypography.headlineMedium),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Agreed Price',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      Text('Rs. 4,500', style: AppTypography.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Escrow Status',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Held in escrow',
                            style: AppTypography.labelSmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      // ── 6. Bottom action buttons ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
                child: DoerButton(
                    label: 'Cancel Job',
                    isOutlined: true,
                    onPressed: () {})),
            const SizedBox(width: 12),
            Expanded(
                child:
                    DoerButton(label: 'Release Payment', onPressed: () {})),
          ],
        ),
      ),
    );
  }
}

// ── Timeline step widget ──
class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Vertical line + circle dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted || isActive
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                // Circle indicator
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.primary
                        : isActive
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.border,
                    border: isActive
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.headlineSmall.copyWith(
                          color: isCompleted || isActive
                              ? AppColors.textPrimary
                              : AppColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall.copyWith(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textTertiary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail row (icon + label + value) ──
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: AppTypography.bodySmall)),
        Expanded(
            child: Text(value,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500))),
      ],
    );
  }
}

// ── Small round icon button (chat/call) ──
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
