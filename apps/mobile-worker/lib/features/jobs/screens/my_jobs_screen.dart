import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../../core/router/app_router.dart';
import 'job_detail_screen.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _activeJobs = [];
  List<dynamic> _appliedJobs = [];
  List<dynamic> _completedJobs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService().getMyJobs(),
        ApiService().getMyApplications(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final jobs = data['jobs'] as List;
      final applications = results[1] as List;
      setState(() {
        _activeJobs = jobs.where((j) =>
          j['status'] == 'ASSIGNED' || j['status'] == 'IN_PROGRESS'
        ).toList();
        _appliedJobs = applications;
        _completedJobs = jobs.where((j) =>
          j['status'] == 'COMPLETED' || j['status'] == 'REVIEWING' || j['status'] == 'CLOSED'
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.errorMessage(e))),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCategoryIcon(String? name) {
    final cat = AppCategories.all.where((c) => c.name.toLowerCase() == (name ?? '').toLowerCase());
    return cat.isNotEmpty ? cat.first.icon : '🔧';
  }

  String _formatBudget(Map<String, dynamic> job) {
    final min = job['budgetMin'];
    final max = job['budgetMax'];
    final price = job['price'];
    if (min != null && max != null) return 'Rs. ${min.toStringAsFixed(0)} — ${max.toStringAsFixed(0)}';
    if (price != null) return 'Rs. ${price.toStringAsFixed(0)}';
    return 'Negotiable';
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

  JobDetailData _jobDetailFromMap(Map<String, dynamic> job) {
    final catName = job['category']?['name'] ?? '';
    return JobDetailData(
      id: job['id'] ?? '',
      title: job['title'] ?? '',
      category: catName,
      categoryIcon: _getCategoryIcon(catName),
      budget: _formatBudget(job),
      distanceKm: 0,
      postedAt: _formatDate(job['createdAt']),
      clientName: job['customer']?['user']?['name'] ?? 'Customer',
      clientRating: (job['customer']?['user']?['customerProfile']?['rating'] ?? 0).toDouble(),
      clientJobsPosted: 0,
      description: job['description'] ?? '',
      scheduledDate: _formatDate(job['scheduledAt']),
      scheduledTime: _formatTime(job['scheduledAt']),
      urgency: job['urgency'],
      address: job['address'] ?? '',
      status: job['status'],
      lat: (job['latitude'] as num?)?.toDouble(),
      lng: (job['longitude'] as num?)?.toDouble(),
    );
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
              child: Text('My Jobs', style: AppTypography.displaySmall),
            ),
            const SizedBox(height: 12),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  unselectedLabelStyle: AppTypography.labelMedium,
                  unselectedLabelColor: AppColors.textTertiary,
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Active'), Tab(text: 'Applied'), Tab(text: 'Completed')],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Active
                      _activeJobs.isEmpty
                        ? const EmptyState(icon: '📋', title: 'No active jobs', subtitle: 'Accept a job to see it here')
                        : RefreshIndicator(
                            onRefresh: _fetchJobs,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _activeJobs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final job = _activeJobs[i];
                                return ActiveJobCard(
                                  title: job['title'] ?? '',
                                  categoryIcon: _getCategoryIcon(job['category']?['name']),
                                  status: job['status'] == 'IN_PROGRESS'
                                      ? JobStatus.inProgress : JobStatus.workerAccepted,
                                  clientName: job['customer']?['user']?['name'] ?? 'Customer',
                                  scheduledDate: _formatDate(job['scheduledAt']),
                                  budget: job['price'] != null ? 'Rs. ${job['price'].toStringAsFixed(0)}' : '',
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.jobDetail,
                                      arguments: _jobDetailFromMap(job),
                                    );
                                    _fetchJobs();
                                  },
                                );
                              },
                            ),
                          ),
                      // Applied
                      _appliedJobs.isEmpty
                        ? const EmptyState(icon: '📝', title: 'No applications', subtitle: 'Apply to jobs to see them here')
                        : RefreshIndicator(
                            onRefresh: _fetchJobs,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _appliedJobs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final app = _appliedJobs[i];
                                final job = app['job'] ?? {};
                                final catName = job['category']?['name'] ?? '';
                                final status = app['status'] ?? 'PENDING';
                                return _AppliedJobCard(
                                  title: job['title'] ?? '',
                                  categoryIcon: _getCategoryIcon(catName),
                                  status: status,
                                  budget: job['price'] != null ? 'Rs. ${job['price'].toStringAsFixed(0)}' : 'Negotiable',
                                  appliedAt: _formatDate(app['createdAt']),
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.jobDetail,
                                      arguments: _jobDetailFromMap(job),
                                    );
                                    _fetchJobs();
                                  },
                                );
                              },
                            ),
                          ),
                      // Completed
                      _completedJobs.isEmpty
                        ? const EmptyState(icon: '✅', title: 'No completed jobs', subtitle: 'Completed jobs will appear here')
                        : RefreshIndicator(
                            onRefresh: _fetchJobs,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _completedJobs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final job = _completedJobs[i];
                                return _CompletedJobCard(
                                  title: job['title'] ?? '',
                                  categoryIcon: _getCategoryIcon(job['category']?['name']),
                                  clientName: job['customer']?['user']?['name'] ?? 'Customer',
                                  completedDate: _formatDate(job['completedAt']),
                                  earned: job['price'] != null ? 'Rs. ${job['price'].toStringAsFixed(0)}' : '',
                                  rating: (job['review']?['rating'] ?? 0).toDouble(),
                                );
                              },
                            ),
                          ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }
}

class _CompletedJobCard extends StatelessWidget {
  final String title, categoryIcon, clientName, completedDate, earned;
  final double rating;
  const _CompletedJobCard({
    required this.title, required this.categoryIcon, required this.clientName,
    required this.completedDate, required this.earned, required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(categoryIcon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: AppTypography.headlineSmall)),
            Text(earned, style: AppTypography.headlineSmall.copyWith(color: AppColors.success)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(clientName, style: AppTypography.labelSmall),
            const SizedBox(width: 10),
            Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(completedDate, style: AppTypography.labelSmall),
            const Spacer(),
            if (rating > 0) RatingStars(rating: rating, size: 14),
          ]),
        ],
      ),
    );
  }
}

class _AppliedJobCard extends StatelessWidget {
  final String title, categoryIcon, status, budget, appliedAt;
  final VoidCallback onTap;
  const _AppliedJobCard({
    required this.title, required this.categoryIcon, required this.status,
    required this.budget, required this.appliedAt, required this.onTap,
  });

  Color get _statusColor {
    switch (status) {
      case 'ACCEPTED': return AppColors.success;
      case 'REJECTED': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'ACCEPTED': return 'Accepted';
      case 'REJECTED': return 'Rejected';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(categoryIcon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTypography.headlineSmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Text(budget, style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.access_time_rounded, size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('Applied $appliedAt', style: AppTypography.labelSmall),
            ]),
          ],
        ),
      ),
    );
  }
}
