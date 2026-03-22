import 'dart:math';
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
  double? _workerLat;
  double? _workerLng;

  double _calcDistance(double? lat, double? lng) {
    if (_workerLat == null || _workerLng == null || lat == null || lng == null) return 0;
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat - _workerLat!) * p) / 2 +
        cos(_workerLat! * p) * cos(lat * p) * (1 - cos((lng - _workerLng!) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

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
      if (_workerLat == null) {
        final me = await ApiService().getMe();
        final wp = me['user']?['workerProfile'];
        _workerLat = (wp?['lat'] as num?)?.toDouble();
        _workerLng = (wp?['lng'] as num?)?.toDouble();
      }
      _jobs = await ApiService().getAvailableJobs();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.errorMessage(e))),
        );
      }
    }
  }

  String _formatBudget(Map<String, dynamic> job) {
    final min = job['budgetMin'];
    final max = job['budgetMax'];
    final price = job['price'];
    if (min != null && max != null) return 'Rs. ${min.toStringAsFixed(0)} — ${max.toStringAsFixed(0)}';
    if (price != null) return 'Rs. ${price.toStringAsFixed(0)}';
    return 'Negotiable';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) { return ''; }
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
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final job = _filteredJobs[index];
                              final catName = job['category']?['name'] ?? '';
                              return JobListingCard(
                                title: job['title'] ?? '',
                                category: catName,
                                categoryIcon: _getCategoryIcon(catName),
                                budget: _formatBudget(job),
                                location: job['address'] ?? '',
                                distance: _calcDistance((job['latitude'] as num?)?.toDouble(), (job['longitude'] as num?)?.toDouble()),
                                postedAt: _timeAgo(job['createdAt']),
                                lat: (job['latitude'] as num?)?.toDouble(),
                                lng: (job['longitude'] as num?)?.toDouble(),
                                onTap: () {
                                  Navigator.pushNamed(context, '/job-detail',
                                    arguments: JobDetailData(
                                      id: job['id'],
                                      title: job['title'] ?? '',
                                      category: catName,
                                      categoryIcon: _getCategoryIcon(catName),
                                      budget: _formatBudget(job),
                                      distanceKm: _calcDistance((job['latitude'] as num?)?.toDouble(), (job['longitude'] as num?)?.toDouble()),
                                      postedAt: _timeAgo(job['createdAt']),
                                      clientName: job['customer']?['user']?['name'] ?? 'Customer',
                                      clientRating: 4.5,
                                      clientJobsPosted: 1,
                                      description: job['description'] ?? '',
                                      scheduledDate: _formatDateTime(job['scheduledAt']),
                                      scheduledTime: _formatTime(job['scheduledAt']),
                                      urgency: job['urgency'],
                                      address: job['address'] ?? '',
                                      status: job['status'],
                                      lat: (job['latitude'] as num?)?.toDouble(),
                                      lng: (job['longitude'] as num?)?.toDouble(),
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
