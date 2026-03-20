import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';

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
class WorkerProfileScreen extends StatefulWidget {
  final String workerId;
  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  Map<String, dynamic>? _worker;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWorker();
  }

  Future<void> _fetchWorker() async {
    try {
      final data = await ApiService().getWorker(widget.workerId);
      if (mounted) {
        setState(() {
          _worker = data;
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

  Color _badgeColor(String badge) {
    switch (badge) {
      case BadgeLevel.platinum:
        return AppColors.badgePlatinum;
      case BadgeLevel.gold:
        return AppColors.badgeGold;
      case BadgeLevel.silver:
        return AppColors.badgeSilver;
      case BadgeLevel.bronze:
        return AppColors.badgeBronze;
      default:
        return AppColors.textTertiary;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _worker == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Failed to load worker profile',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                    _fetchWorker();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final w = _worker!;
    final user = w['user'] as Map<String, dynamic>? ?? {};
    final name = (user['name'] as String?) ?? 'Unknown';
    final avatarUrl = user['avatarUrl'] as String?;
    final bio = (w['bio'] as String?) ?? '';
    final rating = (w['rating'] as num?)?.toDouble() ?? 0.0;
    final totalJobs = (w['totalJobs'] as num?)?.toInt() ?? 0;
    final verificationStatus = w['verificationStatus'] as String?;
    final isAvailable = w['isAvailable'] as bool? ?? false;
    final categories = (w['categories'] as List<dynamic>?) ?? [];
    final reviews = (w['reviews'] as List<dynamic>?) ?? [];

    final badge = _badgeFromVerification(verificationStatus);
    final badgeColor = _badgeColor(badge);
    final badgeLabel = '${BadgeLevel.label(badge)} Verified Worker';

    final categoryNames = categories
        .map((c) {
          final cat = c['category'] as Map<String, dynamic>?;
          return cat?['name'] as String? ?? '';
        })
        .where((n) => n.isNotEmpty)
        .toList();

    final firstCategory = categoryNames.isNotEmpty ? categoryNames.first : '';

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
                  color: AppColors.surface.withValues(alpha: 0.9),
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
                    avatarUrl != null && avatarUrl.isNotEmpty
                        ? CircleAvatar(
                            radius: 44,
                            backgroundImage: NetworkImage(avatarUrl),
                            backgroundColor: AppColors.surface,
                          )
                        : CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.surface,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: AppTypography.displayLarge
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                    const SizedBox(height: 14),
                    Text(name, style: AppTypography.displaySmall),
                    const SizedBox(height: 4),
                    Text(
                      firstCategory,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RatingStars(rating: rating, size: 16),
                        const SizedBox(width: 6),
                        Text(rating.toStringAsFixed(1),
                            style: AppTypography.labelMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Text('(${reviews.length} reviews)',
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
                      _StatCard(label: 'Jobs Done', value: '$totalJobs'),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Rating',
                        value: rating > 0 ? rating.toStringAsFixed(1) : '-',
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Reviews',
                        value: '${reviews.length}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── 2. Badge ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: badgeColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium,
                            color: badgeColor, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(badgeLabel,
                                  style: AppTypography.headlineSmall),
                              const SizedBox(height: 2),
                              Text(
                                totalJobs > 0
                                    ? '$totalJobs+ jobs completed'
                                    : 'New worker',
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
                  if (bio.isNotEmpty) ...[
                    Text('About', style: AppTypography.headlineMedium),
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── 4. Skills ──
                  if (categoryNames.isNotEmpty) ...[
                    Text('Skills & Services',
                        style: AppTypography.headlineMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categoryNames
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
                  ],

                  // ── 5. Availability ──
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
                            Text('Status',
                                style: AppTypography.bodySmall),
                            Text(
                              isAvailable ? 'Available' : 'Unavailable',
                              style: AppTypography.headlineLarge,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.successLight
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 8,
                                  color: isAvailable
                                      ? AppColors.success
                                      : AppColors.textTertiary),
                              const SizedBox(width: 6),
                              Text(
                                isAvailable ? 'Available Now' : 'Busy',
                                style: AppTypography.labelSmall.copyWith(
                                    color: isAvailable
                                        ? AppColors.success
                                        : AppColors.textTertiary,
                                    fontWeight: FontWeight.w600),
                              ),
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
                                  AppColors.textTertiary.withValues(alpha: 0.4),
                              size: 32),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 7. Reviews ──
                  SectionHeader(
                      title: 'Reviews (${reviews.length})',
                      actionText: reviews.length > 2 ? 'See all' : null,
                      onAction: () {}),
                  if (reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No reviews yet',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    )
                  else
                    ...reviews.take(3).map((r) {
                      final review = r as Map<String, dynamic>;
                      final customer = review['customer'] as Map<String, dynamic>?;
                      final customerUser = customer?['user'] as Map<String, dynamic>?;
                      final reviewerName = (customerUser?['name'] as String?) ?? 'Anonymous';
                      final reviewRating = (review['rating'] as num?)?.toInt() ?? 0;
                      final comment = (review['comment'] as String?) ?? '';
                      final createdAt = review['createdAt'] as String?;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReviewCard(
                          name: reviewerName,
                          rating: reviewRating,
                          date: _formatDate(createdAt),
                          text: comment,
                        ),
                      );
                    }),

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
          onPressed: () {
            Navigator.pushNamed(context, '/post-job');
          },
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
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(text,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.5)),
          ],
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
class BrowseWorkersScreen extends StatefulWidget {
  final String? categoryFilter;
  const BrowseWorkersScreen({super.key, this.categoryFilter});

  @override
  State<BrowseWorkersScreen> createState() => _BrowseWorkersScreenState();
}

class _BrowseWorkersScreenState extends State<BrowseWorkersScreen> {
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
      final data = await ApiService().getWorkers();
      if (mounted) {
        setState(() {
          _workers = data;
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
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
                      )
                    : _workers.isEmpty
                        ? Center(
                            child: Text(
                              'No workers found',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textTertiary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _workers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final w = _workers[index] as Map<String, dynamic>;
                              final user =
                                  w['user'] as Map<String, dynamic>? ?? {};
                              final name =
                                  (user['name'] as String?) ?? 'Unknown';
                              final rating =
                                  (w['rating'] as num?)?.toDouble() ?? 0.0;
                              final verificationStatus =
                                  w['verificationStatus'] as String?;
                              final categories =
                                  (w['categories'] as List<dynamic>?) ?? [];
                              final firstCategory = categories.isNotEmpty
                                  ? ((categories.first['category']
                                          as Map<String, dynamic>?)?['name']
                                      as String? ?? '')
                                  : '';

                              return WorkerCard(
                                name: name,
                                skill: firstCategory,
                                badge: _badgeFromVerification(
                                    verificationStatus),
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
                              );
                            },
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
