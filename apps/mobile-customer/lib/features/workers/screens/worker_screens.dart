import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// WORKER PROFILE SCREEN
// Full profile of a worker. Uses CustomScrollView with collapsing
// header showing avatar, name, rating. Sections below:
//   1. Stats row (jobs done, completion rate, response time)
//   2. Trust badge card (Gold Verified etc.)
//   3. About bio
//   4. Skills tags
//   5. Hourly rate + availability
//   6. Portfolio gallery
//   7. Reviews list
//   8. "Book This Worker" button at bottom
// ──────────────────────────────────────────────────────────────
class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsing header with avatar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.surfaceVariant,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.surface,
                      child: Text('N',
                          style: AppTypography.displayLarge
                              .copyWith(color: AppColors.primary)),
                    ),
                    const SizedBox(height: 14),
                    Text('Nimal Perera', style: AppTypography.displaySmall),
                    const SizedBox(height: 4),
                    Text('Electrician · Colombo',
                        style: AppTypography.bodySmall),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const RatingStars(rating: 4.8, size: 16),
                        const SizedBox(width: 6),
                        Text('4.8',
                            style: AppTypography.labelMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Text('(127 reviews)',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Stats ──
                  Row(
                    children: [
                      _StatCard(label: 'Jobs Done', value: '234'),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Completion', value: '96%'),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Response', value: '< 5min'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── 2. Badge ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.badgeGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.badgeGold.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium,
                            color: AppColors.badgeGold, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gold Verified Worker',
                                  style: AppTypography.headlineSmall),
                              const SizedBox(height: 2),
                              Text(
                                'Background checked, skills verified, 234+ jobs completed',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 3. About ──
                  Text('About', style: AppTypography.headlineMedium),
                  const SizedBox(height: 10),
                  Text(
                    'Experienced electrician with over 8 years in residential and commercial electrical work. Specialized in wiring, panel upgrades, lighting installation, and troubleshooting. Available throughout the Colombo district.',
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary, height: 1.6),
                  ),

                  const SizedBox(height: 24),

                  // ── 4. Skills ──
                  Text('Skills & Services',
                      style: AppTypography.headlineMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Wiring',
                      'Panel Upgrades',
                      'Lighting',
                      'Troubleshooting',
                      'Fan Installation',
                      'Socket Repair',
                    ]
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child:
                                  Text(s, style: AppTypography.labelMedium),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── 5. Rate + Availability ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hourly Rate',
                                style: AppTypography.bodySmall),
                            Text('Rs. 1,500 /hr',
                                style: AppTypography.headlineLarge),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 8, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text('Available Now',
                                  style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 6. Portfolio ──
                  SectionHeader(
                      title: 'Portfolio',
                      actionText: 'See all',
                      onAction: () {}),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (_, i) => Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(Icons.image_outlined,
                              color:
                                  AppColors.textTertiary.withOpacity(0.4),
                              size: 32),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 7. Reviews ──
                  SectionHeader(
                      title: 'Reviews (127)',
                      actionText: 'See all',
                      onAction: () {}),
                  _ReviewCard(
                    name: 'Ashen D.',
                    rating: 5,
                    date: 'Mar 15, 2026',
                    text:
                        'Excellent work! Nimal fixed our electrical issues quickly and professionally.',
                  ),
                  const SizedBox(height: 12),
                  _ReviewCard(
                    name: 'Kavinda S.',
                    rating: 4,
                    date: 'Mar 10, 2026',
                    text:
                        'Good job overall. Was a bit late but the quality of work was great.',
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      // ── Book button ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: DoerButton(
          label: 'Book This Worker',
          icon: Icons.calendar_today_outlined,
          onPressed: () {},
        ),
      ),
    );
  }
}

// Stat card (jobs done, completion, response time)
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.headlineLarge
                    .copyWith(color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }
}

// Single review card
class _ReviewCard extends StatelessWidget {
  final String name;
  final int rating;
  final String date;
  final String text;

  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.date,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(name[0],
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.headlineSmall),
                    Text(date, style: AppTypography.labelSmall),
                  ],
                ),
              ),
              RatingStars(rating: rating.toDouble(), size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Text(text,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// BROWSE WORKERS SCREEN
// List of workers with search bar and filter chips.
// Filters: Nearest, Top Rated, Gold+, Available Now
// ──────────────────────────────────────────────────────────────
class BrowseWorkersScreen extends StatelessWidget {
  final String? categoryFilter;
  const BrowseWorkersScreen({super.key, this.categoryFilter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(categoryFilter ?? 'Browse Workers'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: DoerSearchBar(
              hint: 'Search workers by name or skill...',
              autofocus: false,
              onChanged: (v) {},
            ),
          ),
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(label: 'Nearest', selected: true),
                const SizedBox(width: 8),
                _FilterChip(label: 'Top Rated'),
                const SizedBox(width: 8),
                _FilterChip(label: 'Gold+'),
                const SizedBox(width: 8),
                _FilterChip(label: 'Available Now'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Worker list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                WorkerCard(
                  name: 'Nimal Perera',
                  skill: 'Electrician',
                  badge: BadgeLevel.gold,
                  rating: 4.8,
                  distance: 2.1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WorkerProfileScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                WorkerCard(
                  name: 'Saman Fernando',
                  skill: 'Plumber',
                  badge: BadgeLevel.silver,
                  rating: 4.5,
                  distance: 3.4,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                WorkerCard(
                  name: 'Kumari Silva',
                  skill: 'House Cleaning',
                  badge: BadgeLevel.platinum,
                  rating: 4.9,
                  distance: 1.8,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                WorkerCard(
                  name: 'Ruwan Jayasinghe',
                  skill: 'Painter',
                  badge: BadgeLevel.bronze,
                  rating: 4.2,
                  distance: 5.1,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _FilterChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
