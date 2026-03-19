import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

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
class CategoryDetailScreen extends StatelessWidget {
  final ServiceCategory category;

  const CategoryDetailScreen({super.key, required this.category});

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
            backgroundColor: category.iconBgColor,
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
                color: category.iconBgColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(category.icon,
                        style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text(category.name,
                        style: AppTypography.displaySmall),
                    const SizedBox(height: 4),
                    Text(
                      '24 verified workers available',
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
                                    'Need a ${category.name.toLowerCase()} job done?',
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Mock worker data
                  final workers = [
                    ('Nimal Perera', 'gold', 4.8, 2.1),
                    ('Saman Fernando', 'silver', 4.5, 3.4),
                    ('Ruwan Jayasinghe', 'bronze', 4.2, 5.1),
                    ('Kasun Bandara', 'gold', 4.7, 4.2),
                    ('Chaminda Rajapaksa', 'trainee', 4.0, 6.8),
                  ];
                  if (index >= workers.length) return null;
                  final w = workers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: WorkerCard(
                      name: w.$1,
                      skill: category.name,
                      badge: w.$2,
                      rating: w.$3,
                      distance: w.$4,
                      onTap: () {},
                    ),
                  );
                },
                childCount: 5,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
