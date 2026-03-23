import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';

class RecommendedWorkersScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final List<dynamic>? initialMatches;

  const RecommendedWorkersScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    this.initialMatches,
  });

  @override
  State<RecommendedWorkersScreen> createState() => _RecommendedWorkersScreenState();
}

class _RecommendedWorkersScreenState extends State<RecommendedWorkersScreen> {
  bool _loading = true;
  List<dynamic> _matches = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialMatches != null && widget.initialMatches!.isNotEmpty) {
      _matches = widget.initialMatches!;
      _loading = false;
    } else {
      _fetchMatches();
    }
  }

  Future<void> _fetchMatches() async {
    setState(() => _loading = true);
    try {
      _matches = await ApiService().getJobMatches(widget.jobId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _badgeColor(String? badge) {
    switch (badge?.toUpperCase()) {
      case 'PLATINUM': return const Color(0xFF8B5CF6);
      case 'GOLD': return const Color(0xFFF59E0B);
      case 'SILVER': return const Color(0xFF9CA3AF);
      case 'BRONZE': return const Color(0xFFD97706);
      default: return const Color(0xFF6B7280);
    }
  }

  String _badgeLabel(String? badge) {
    switch (badge?.toUpperCase()) {
      case 'PLATINUM': return 'Platinum';
      case 'GOLD': return 'Gold';
      case 'SILVER': return 'Silver';
      case 'BRONZE': return 'Bronze';
      default: return 'Trainee';
    }
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
        title: const Text('Recommended Workers'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search_off_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('No Workers Found Nearby', style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'No available workers match your job right now. Workers will be able to find and apply to your job from the browse screen.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DoerButton(
              label: 'Go to My Jobs',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_matches.length} Workers Recommended',
                            style: AppTypography.headlineMedium),
                        const SizedBox(height: 2),
                        Text('For "${widget.jobTitle}"',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Workers are ranked by proximity, rating, completion rate, and trust badge.',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.info, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Worker list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchMatches,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final match = _matches[i];
                final worker = match['worker'];
                final user = worker?['user'];
                final name = user?['name'] ?? 'Unknown Worker';
                final avatar = user?['avatarUrl'];
                final rating = (worker?['rating'] ?? 0).toDouble();
                final totalJobs = worker?['totalJobs'] ?? 0;
                final badge = worker?['badgeLevel']?.toString();
                final distance = (match['distanceKm'] ?? 0).toDouble();
                final score = (match['matchScore'] ?? 0).toDouble();
                final categories = (worker?['categories'] as List?)
                    ?.map((c) => c['category']?['name'] ?? '')
                    .where((n) => n.isNotEmpty)
                    .join(', ') ?? '';
                final completion = ((worker?['completionRate'] ?? 0) * 100).toStringAsFixed(0);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: i == 0 ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                      width: i == 0 ? 1.5 : 1,
                    ),
                    boxShadow: i == 0
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Rank badge
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? AppColors.primary
                                  : i < 3
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '#${i + 1}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: i == 0 ? Colors.white : i < 3 ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _badgeColor(badge).withValues(alpha: 0.15),
                            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                            child: avatar == null
                                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: AppTypography.headlineSmall.copyWith(color: _badgeColor(badge)))
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Name & category
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(name, style: AppTypography.headlineSmall,
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                    if (i == 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('Best Match',
                                            style: AppTypography.labelSmall.copyWith(
                                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9)),
                                      ),
                                    ],
                                  ],
                                ),
                                if (categories.isNotEmpty)
                                  Text(categories,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),

                          // Match score
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${(score * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.headlineSmall.copyWith(
                                      color: AppColors.success, fontWeight: FontWeight.w700)),
                              Text('match', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Stats row
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _StatChip(
                              icon: Icons.location_on_outlined,
                              label: '${distance.toStringAsFixed(1)} km',
                              color: AppColors.info,
                            ),
                            _StatChip(
                              icon: Icons.star_rounded,
                              label: rating > 0 ? rating.toStringAsFixed(1) : 'New',
                              color: AppColors.badgeGold,
                            ),
                            _StatChip(
                              icon: Icons.check_circle_outline,
                              label: '$completion%',
                              color: AppColors.success,
                            ),
                            _StatChip(
                              icon: Icons.workspace_premium_rounded,
                              label: _badgeLabel(badge),
                              color: _badgeColor(badge),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Match score bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score,
                          minHeight: 4,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            i == 0 ? AppColors.primary : AppColors.success,
                          ),
                        ),
                      ),

                      if (totalJobs > 0) ...[
                        const SizedBox(height: 6),
                        Text('$totalJobs jobs completed',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Bottom bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: DoerButton(
            label: 'Go to My Jobs',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(label,
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
