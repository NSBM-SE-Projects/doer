import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../workers/screens/worker_screens.dart';

// ──────────────────────────────────────────────────────────────
// CATEGORY DETAIL SCREEN
// Shows all workers for a specific service category.
// Uses CustomScrollView with SliverAppBar for the collapsing
// header effect — the category icon and name shrink as you scroll.
// Sections:
//   1. Collapsing header with category icon + name + worker count
//   2. "Post a job" CTA card
//   3. Filter/sort bar
//   4. List of WorkerCards for this category
// ──────────────────────────────────────────────────────────────
class CategoryDetailScreen extends StatefulWidget {
  final ServiceCategory category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<dynamic> _workers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    try {
      // Try fetching by category ID if available
      List<dynamic> workers;
      if (widget.category.id.isNotEmpty) {
        workers = await ApiService().getWorkers(categoryId: widget.category.id);
      } else {
        // Fallback: fetch all workers and filter by category name
        final all = await ApiService().getWorkers();
        workers = all.where((w) {
          final categories = (w['categories'] as List<dynamic>?) ?? [];
          return categories.any((c) {
            final cat = c['category'] as Map<String, dynamic>?;
            final catName = (cat?['name'] as String?) ?? '';
            return catName.toLowerCase() == widget.category.name.toLowerCase();
          });
        }).toList();
      }
      if (mounted) {
        setState(() {
          _workers = workers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiService.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  String _badgeFromVerification(String? status) {
    switch (status) {
      case 'PLATINUM':
        return BadgeLevel.platinum;
      case 'GOLD':
        return BadgeLevel.gold;
      case 'SILVER':
        return BadgeLevel.silver;
      case 'BRONZE':
        return BadgeLevel.bronze;
      default:
        return BadgeLevel.trainee;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── 1. Collapsing header ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true, // keeps app bar visible when scrolled
            backgroundColor: widget.category.iconBgColor,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: widget.category.iconBgColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(widget.category.icon,
                        style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text(widget.category.name,
                        style: AppTypography.displaySmall),
                    const SizedBox(height: 4),
                    _loading
                        ? Text(
                            'Loading workers...',
                            style: AppTypography.bodySmall,
                          )
                        : Text(
                            '${_workers.length} verified worker${_workers.length == 1 ? '' : 's'} available',
                            style: AppTypography.bodySmall,
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // ── 2 & 3. CTA + Filters ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Quick post job CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/post-job');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Need a ${widget.category.name.toLowerCase()} job done?',
                                    style: AppTypography.headlineSmall),
                                Text('Post a job and get matched instantly',
                                    style: AppTypography.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Filter and sort bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Available Workers',
                            style: AppTypography.headlineMedium),
                      ),
                      // Filter button
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune_rounded,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Filter',
                                style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sort button
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sort_rounded,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Nearest',
                                style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // ── 4. Worker list ──
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      DoerButton(
                        label: 'Retry',
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _fetchWorkers();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_workers.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search_rounded,
                          size: 48,
                          color: AppColors.textTertiary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No workers available in this category yet',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final w = _workers[index] as Map<String, dynamic>;
                    final user = w['user'] as Map<String, dynamic>? ?? {};
                    final name = (user['name'] as String?) ?? 'Unknown';
                    final rating =
                        (w['rating'] as num?)?.toDouble() ?? 0.0;
                    final verificationStatus =
                        w['verificationStatus'] as String?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WorkerCard(
                        name: name,
                        skill: widget.category.name,
                        badge: _badgeFromVerification(verificationStatus),
                        rating: rating,
                        distance: 0.0,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkerProfileScreen(
                                workerId: w['id'].toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: _workers.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
