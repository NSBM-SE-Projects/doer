import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import 'job_detail_screen.dart';

class BrowseJobsScreen extends StatefulWidget {
  const BrowseJobsScreen({super.key});

  @override
  State<BrowseJobsScreen> createState() => _BrowseJobsScreenState();
}

class _BrowseJobsScreenState extends State<BrowseJobsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  int _selectedRadius = 10;
  bool _isLoading = true;
  List<dynamic> _jobs = [];

  final List<int> _radiusOptions = [5, 10, 15, 25];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      _jobs = await ApiService().getAvailableJobs();
      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredJobs {
    return _jobs.where((j) {
      final catName = j['category']?['name'] ?? '';
      final matchCategory = _selectedCategory == 'All' || catName == _selectedCategory;
      final query = _searchController.text.toLowerCase();
      final matchSearch = query.isEmpty ||
          (j['title'] ?? '').toString().toLowerCase().contains(query) ||
          catName.toLowerCase().contains(query);
      return matchCategory && matchSearch;
    }).toList();
  }

  String _getCategoryIcon(String? name) {
    final cat = AppCategories.all.where((c) => c.name.toLowerCase() == (name ?? '').toLowerCase());
    return cat.isNotEmpty ? cat.first.icon : '🔧';
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
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
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textTertiary, size: 18),
                          onPressed: () { _searchController.clear(); setState(() {}); },
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
                  _FilterChip(label: 'All', isSelected: _selectedCategory == 'All',
                      onTap: () => setState(() => _selectedCategory = 'All')),
                  const SizedBox(width: 8),
                  ...AppCategories.all.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: '${c.icon} ${c.name}',
                      isSelected: _selectedCategory == c.name,
                      onTap: () => setState(() => _selectedCategory = c.name),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${_filteredJobs.length} jobs found', style: AppTypography.labelMedium),
            ),
            const SizedBox(height: 8),

            // Job list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredJobs.isEmpty
                      ? const EmptyState(
                          icon: '🔍',
                          title: 'No jobs found',
                          subtitle: 'Try adjusting your filters or expanding the search radius.',
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchJobs,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _filteredJobs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final job = _filteredJobs[index];
                              final catName = job['category']?['name'] ?? '';
                              return JobListingCard(
                                title: job['title'] ?? '',
                                category: catName,
                                categoryIcon: _getCategoryIcon(catName),
                                budget: job['price'] != null
                                    ? 'Rs. ${job['price'].toStringAsFixed(0)}'
                                    : 'Negotiable',
                                location: job['address'] ?? '',
                                distance: 0,
                                postedAt: _timeAgo(job['createdAt']),
                                onTap: () {
                                  Navigator.pushNamed(context, '/job-detail',
                                    arguments: JobDetailData(
                                      id: job['id'],
                                      title: job['title'] ?? '',
                                      category: catName,
                                      categoryIcon: _getCategoryIcon(catName),
                                      budget: job['price'] != null
                                          ? 'Rs. ${job['price'].toStringAsFixed(0)}'
                                          : 'Negotiable',
                                      distanceKm: 0,
                                      postedAt: _timeAgo(job['createdAt']),
                                      clientName: job['customer']?['user']?['name'] ?? 'Customer',
                                      clientRating: 4.5,
                                      clientJobsPosted: 1,
                                      description: job['description'] ?? '',
                                      scheduledDate: '',
                                      address: job['address'] ?? '',
                                      status: job['status'],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
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
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
