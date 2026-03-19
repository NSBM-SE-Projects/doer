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
// All worker cards navigate to WorkerProfileScreen.
// Filter chips filter the list by category.
// ──────────────────────────────────────────────────────────────
class BrowseWorkersScreen extends StatefulWidget {
  final String? categoryFilter;
  const BrowseWorkersScreen({super.key, this.categoryFilter});

  @override
  State<BrowseWorkersScreen> createState() => _BrowseWorkersScreenState();
}

class _BrowseWorkersScreenState extends State<BrowseWorkersScreen> {
  String _selectedFilter = 'Nearest';

  // Mock worker data — will be replaced by API data later
  final List<Map<String, dynamic>> _allWorkers = [
    {'name': 'Nimal Perera', 'skill': 'Electrician', 'badge': 'gold', 'rating': 4.8, 'distance': 2.1},
    {'name': 'Saman Fernando', 'skill': 'Plumber', 'badge': 'silver', 'rating': 4.5, 'distance': 3.4},
    {'name': 'Kumari Silva', 'skill': 'House Cleaning', 'badge': 'platinum', 'rating': 4.9, 'distance': 1.8},
    {'name': 'Ruwan Jayasinghe', 'skill': 'Painter', 'badge': 'bronze', 'rating': 4.2, 'distance': 5.1},
    {'name': 'Kasun Bandara', 'skill': 'Electrician', 'badge': 'gold', 'rating': 4.7, 'distance': 4.2},
    {'name': 'Priya Rajapaksa', 'skill': 'Gardener', 'badge': 'silver', 'rating': 4.3, 'distance': 3.8},
  ];

  List<Map<String, dynamic>> get _filteredWorkers {
    var workers = List<Map<String, dynamic>>.from(_allWorkers);

    switch (_selectedFilter) {
      case 'Nearest':
        workers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
        break;
      case 'Top Rated':
        workers.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'Gold+':
        workers = workers.where((w) => w['badge'] == 'gold' || w['badge'] == 'platinum').toList();
        break;
      case 'Available Now':
        // For now show all — will filter by real availability from API later
        break;
    }

    return workers;
  }

  @override
  Widget build(BuildContext context) {
    final workers = _filteredWorkers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryFilter ?? 'Browse Workers'),
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
              children: ['Nearest', 'Top Rated', 'Gold+', 'Available Now']
                  .map((filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedFilter == filter
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedFilter == filter
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: AppTypography.labelMedium.copyWith(
                                color: _selectedFilter == filter
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Worker list — every card navigates to profile
          Expanded(
            child: workers.isEmpty
                ? const EmptyState(
                    icon: '🔍',
                    title: 'No workers found',
                    subtitle: 'Try a different filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: workers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final w = workers[index];
                      return WorkerCard(
                        name: w['name'],
                        skill: w['skill'],
                        badge: w['badge'],
                        rating: w['rating'],
                        distance: w['distance'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WorkerProfileScreen()),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
