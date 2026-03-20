import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../messaging/screens/messaging_screens.dart';

// ──────────────────────────────────────────────────────────────
// JOB DETAIL SCREEN
// Full breakdown of a job a worker is considering.
// Sections: header, client, location, description, schedule, apply.
// ──────────────────────────────────────────────────────────────

class JobDetailScreen extends StatefulWidget {
  final JobDetailData job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _applied = false;
  bool _applying = false;

  Future<void> _applyToJob() async {
    setState(() => _applying = true);
    try {
      await ApiService().applyToJob(widget.job.id);
      if (mounted) {
        setState(() {
          _applying = false;
          _applied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application sent for "${widget.job.title}"'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _applying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiService.errorMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: AppColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),

          // ── Header card ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + posted time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${job.categoryIcon} ${job.category}',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(job.postedAt, style: AppTypography.labelSmall),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(job.title, style: AppTypography.displaySmall),

                  const SizedBox(height: 12),

                  // Budget + distance row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          job.budget,
                          style: AppTypography.headlineLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${job.distanceKm.toStringAsFixed(1)} km away',
                              style: AppTypography.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Client info ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client', style: AppTypography.headlineMedium),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.surfaceVariant,
                          child: Text(
                            job.clientName.isNotEmpty
                                ? job.clientName[0].toUpperCase()
                                : '?',
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.clientName,
                                  style: AppTypography.headlineSmall),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 13, color: AppColors.badgeGold),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${job.clientRating.toStringAsFixed(1)} · ${job.clientJobsPosted} jobs posted',
                                    style: AppTypography.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final s = job.status?.toUpperCase();
                            if (s == 'ASSIGNED' || s == 'IN_PROGRESS' || s == 'COMPLETED') {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  jobId: job.id,
                                  clientName: job.clientName,
                                  jobTitle: job.title,
                                ),
                              ));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You can message the client after your application is accepted.')),
                              );
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 16, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Description ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Description', style: AppTypography.headlineMedium),
                  const SizedBox(height: 10),
                  Text(
                    job.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Schedule + Location details ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: AppTypography.headlineMedium),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Scheduled',
                    value: job.scheduledDate,
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: job.address,
                  ),
                  if (job.estimatedDuration != null) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.timer_outlined,
                      label: 'Est. Duration',
                      value: job.estimatedDuration!,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Map placeholder ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location', style: AppTypography.headlineMedium),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map_outlined,
                                  size: 36, color: AppColors.textTertiary),
                              const SizedBox(height: 8),
                              Text(job.address,
                                  style: AppTypography.bodySmall,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Location: ${job.address}'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Open Maps',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky apply bar ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border:
              const Border(top: BorderSide(color: AppColors.borderLight)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _applied
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Application Submitted',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              )
            : DoerButton(
                label: 'Apply for this Job',
                isLoading: _applying,
                onPressed: _applyToJob,
                icon: Icons.handyman_rounded,
              ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// DATA MODEL
// ──────────────────────────────────────────────────────────────
class JobDetailData {
  final String id;
  final String title;
  final String category;
  final String categoryIcon;
  final String budget;
  final double distanceKm;
  final String postedAt;
  final String clientName;
  final double clientRating;
  final int clientJobsPosted;
  final String description;
  final String scheduledDate;
  final String address;
  final String? estimatedDuration;
  final String? status;

  const JobDetailData({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryIcon,
    required this.budget,
    required this.distanceKm,
    required this.postedAt,
    required this.clientName,
    required this.clientRating,
    required this.clientJobsPosted,
    required this.description,
    required this.scheduledDate,
    required this.address,
    this.estimatedDuration,
    this.status,
  });
}

