import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/router/app_router.dart';
import 'job_detail_screen.dart';

// ──────────────────────────────────────────────────────────────
// BROWSE JOBS SCREEN
// Worker can browse all available jobs, filtered by:
//   - Category (service type)
//   - Distance radius
//   - Budget range
// Uses a search bar + filter chips at the top.
// ──────────────────────────────────────────────────────────────
class BrowseJobsScreen extends StatefulWidget {
  const BrowseJobsScreen({super.key});

  @override
  State<BrowseJobsScreen> createState() => _BrowseJobsScreenState();
}

class _BrowseJobsScreenState extends State<BrowseJobsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  int _selectedRadius = 10; // km

  final List<int> _radiusOptions = [5, 10, 15, 25];

  static final List<_MockJob> _jobs = [
    _MockJob('Fix bathroom tiles', 'Plumbing', '🔧', 'Rs. 3,200',
        'Nugegoda, Colombo', 1.1, '5 min ago'),
    _MockJob('Install ceiling fan', 'Electrical', '⚡', 'Rs. 2,000',
        'Maharagama, Colombo', 2.3, '15 min ago'),
    _MockJob('Deep clean 3-bedroom house', 'Cleaning', '🧹', 'Rs. 5,000',
        'Kottawa, Colombo', 3.8, '30 min ago'),
    _MockJob('Paint living room walls', 'Painting', '🎨', 'Rs. 7,500',
        'Moratuwa, Colombo', 4.2, '1 hr ago'),
    _MockJob('Garden maintenance', 'Gardening', '🌿', 'Rs. 1,800',
        'Boralesgamuwa, Colombo', 5.5, '2 hr ago'),
    _MockJob('Move furniture - 2-bedroom flat', 'Moving', '📦', 'Rs. 6,000',
        'Dehiwala, Colombo', 6.1, '3 hr ago'),
    _MockJob('Fix kitchen cabinet doors', 'Carpentry', '🪚', 'Rs. 2,500',
        'Piliyandala, Colombo', 7.4, '4 hr ago'),
    _MockJob('Washing machine repair', 'Appliance', '🔌', 'Rs. 1,500',
        'Homagama, Colombo', 8.2, '5 hr ago'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_MockJob> get _filteredJobs {
    return _jobs.where((j) {
      final matchCategory =
          _selectedCategory == 'All' || j.category == _selectedCategory;
      final matchRadius = j.distance <= _selectedRadius;
      final query = _searchController.text.toLowerCase();
      final matchSearch = query.isEmpty ||
          j.title.toLowerCase().contains(query) ||
          j.category.toLowerCase().contains(query);
      return matchCategory && matchRadius && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Browse Jobs', style: AppTypography.displaySmall),
            ),

            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search by title or category...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textTertiary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.textTertiary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Category filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedCategory == 'All',
                    onTap: () => setState(() => _selectedCategory = 'All'),
                  ),
                  const SizedBox(width: 8),
                  ...AppCategories.all.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: '${c.icon} ${c.name}',
                          isSelected: _selectedCategory == c.name,
                          onTap: () =>
                              setState(() => _selectedCategory = c.name),
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Radius filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Radius:', style: AppTypography.labelMedium),
                  const SizedBox(width: 8),
                  ..._radiusOptions.map((r) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: '${r}km',
                          isSelected: _selectedRadius == r,
                          onTap: () => setState(() => _selectedRadius = r),
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${_filteredJobs.length} jobs found',
                style: AppTypography.labelMedium,
              ),
            ),

            const SizedBox(height: 8),

            // Job list
            Expanded(
              child: _filteredJobs.isEmpty
                  ? const EmptyState(
                      icon: '🔍',
                      title: 'No jobs found',
                      subtitle:
                          'Try adjusting your filters or expanding the search radius.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: _filteredJobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final job = _filteredJobs[index];
                        // map mock job to detail data (use sample if id matches, else build inline)
                        final detail = index < kSampleJobs.length
                            ? kSampleJobs[index]
                            : JobDetailData(
                                id: '$index',
                                title: job.title,
                                category: job.category,
                                categoryIcon: job.icon,
                                budget: job.budget,
                                distanceKm: job.distance,
                                postedAt: job.postedAt,
                                clientName: 'Client',
                                clientRating: 4.5,
                                clientJobsPosted: 1,
                                description:
                                    'Job details will be shown here.',
                                scheduledDate: 'To be confirmed',
                                address: job.location,
                              );
                        return JobListingCard(
                          title: job.title,
                          category: job.category,
                          categoryIcon: job.icon,
                          budget: job.budget,
                          location: job.location,
                          distance: job.distance,
                          postedAt: job.postedAt,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.jobDetail,
                            arguments: detail,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MockJob {
  final String title;
  final String category;
  final String icon;
  final String budget;
  final String location;
  final double distance;
  final String postedAt;

  const _MockJob(this.title, this.category, this.icon, this.budget,
      this.location, this.distance, this.postedAt);
}
