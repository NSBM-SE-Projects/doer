import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../jobs/screens/job_detail_screen.dart';
import '../../jobs/screens/my_jobs_screen.dart';
import '../../jobs/screens/browse_jobs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isAvailable = true;
  bool _isLoading = true;
  String _workerName = '';
  String _verificationStatus = 'PENDING';
  double _rating = 0;
  int _totalJobs = 0;
  List<dynamic> _availableJobs = [];
  List<dynamic> _activeJobs = [];
  double _totalEarnings = 0;
  double _pendingPayout = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService().getMe(),
        ApiService().getAvailableJobs(),
        ApiService().getMyJobs(),
        ApiService().getMyPayments(),
      ]);

      final userData = results[0] as Map<String, dynamic>;
      final user = userData['user'];
      final wp = user['workerProfile'];

      setState(() {
        _workerName = user['name'] ?? AuthService().currentUser?.displayName ?? 'Worker';
        _isAvailable = wp?['isAvailable'] ?? true;
        _verificationStatus = wp?['verificationStatus'] ?? 'PENDING';
        _rating = (wp?['rating'] ?? 0).toDouble();
        _totalJobs = wp?['totalJobs'] ?? 0;
        _availableJobs = results[1] as List;
        final allJobs = (results[2] as Map<String, dynamic>)['jobs'] as List;
        _activeJobs = allJobs.where((j) =>
          j['status'] == 'ASSIGNED' || j['status'] == 'IN_PROGRESS'
        ).toList();

        final payments = results[3] as List;
        _totalEarnings = 0;
        _pendingPayout = 0;
        for (final p in payments) {
          final amount = (p['amount'] ?? 0).toDouble();
          if (p['status'] == 'COMPLETED') {
            _totalEarnings += amount;
          } else if (p['status'] == 'PENDING') {
            _pendingPayout += amount;
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _workerName = AuthService().currentUser?.displayName ?? 'Worker';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isAvailable = value);
    try {
      await ApiService().updateWorkerProfile(isAvailable: value);
    } catch (_) {
      setState(() => _isAvailable = !value);
    }
  }

  String _getCategoryIcon(String? categoryName) {
    final cat = AppCategories.all.where((c) =>
      c.name.toLowerCase() == (categoryName ?? '').toLowerCase()
    );
    return cat.isNotEmpty ? cat.first.icon : '🔧';
  }

  JobDetailData _jobDetailFromMap(Map<String, dynamic> job) {
    final catName = job['category']?['name'] ?? '';
    return JobDetailData(
      id: job['id'] ?? '',
      title: job['title'] ?? '',
      category: catName,
      categoryIcon: _getCategoryIcon(catName),
      budget: job['price'] != null ? 'Rs. ${job['price'].toStringAsFixed(0)}' : 'Negotiable',
      distanceKm: 0,
      postedAt: _timeAgo(job['createdAt']),
      clientName: job['customer']?['user']?['name'] ?? 'Customer',
      clientRating: (job['customer']?['user']?['customerProfile']?['rating'] ?? 0).toDouble(),
      clientJobsPosted: 0,
      description: job['description'] ?? '',
      scheduledDate: job['scheduledDate'] ?? '',
      address: job['address'] ?? '',
      status: job['status'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Good morning,', style: AppTypography.bodySmall),
                                Text(_workerName, style: AppTypography.displaySmall),
                              ],
                            ),
                          ),
                          BadgePill(badge: _verificationStatus == 'VERIFIED'
                              ? BadgeLevel.bronze : BadgeLevel.trainee),
                          const SizedBox(width: 10),
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(Icons.notifications_outlined,
                                      color: AppColors.textSecondary, size: 20),
                                ),
                              ),
                              Positioned(
                                top: 6, right: 6,
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error, shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Availability toggle
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isAvailable ? AppColors.successLight : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isAvailable
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: _isAvailable ? AppColors.success : AppColors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isAvailable ? 'You\'re Online' : 'You\'re Offline',
                                    style: AppTypography.headlineSmall.copyWith(
                                      color: _isAvailable ? AppColors.success : AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    _isAvailable
                                        ? 'Clients can see you in job matches'
                                        : 'You\'re hidden from job matches',
                                    style: AppTypography.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isAvailable,
                              onChanged: _toggleAvailability,
                              activeColor: AppColors.success,
                              activeTrackColor: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Earnings summary
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: EarningsSummaryCard(
                        totalEarnings: 'Rs. ${_totalEarnings.toStringAsFixed(0)}',
                        pendingPayout: 'Rs. ${_pendingPayout.toStringAsFixed(0)}',
                        thisMonth: '$_totalJobs jobs done',
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Verification nudge
                  if (_verificationStatus != 'VERIFIED')
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, color: AppColors.warning, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Complete your verification',
                                        style: AppTypography.headlineSmall.copyWith(color: AppColors.warning)),
                                    Text('Upload NIC to unlock Bronze badge',
                                        style: AppTypography.labelSmall),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/verification'),
                                child: Text('Go',
                                    style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.warning, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Active job section
                  if (_activeJobs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            SectionHeader(title: 'Active Job', actionText: 'My Jobs', onAction: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyJobsScreen()));
                            }),
                            ..._activeJobs.map((job) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ActiveJobCard(
                                title: job['title'] ?? '',
                                categoryIcon: _getCategoryIcon(job['category']?['name']),
                                status: job['status'] == 'IN_PROGRESS'
                                    ? JobStatus.inProgress : JobStatus.workerAccepted,
                                clientName: job['customer']?['user']?['name'] ?? 'Customer',
                                scheduledDate: '',
                                budget: job['price'] != null ? 'Rs. ${job['price'].toStringAsFixed(0)}' : '',
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.jobDetail,
                                    arguments: _jobDetailFromMap(job),
                                  );
                                },
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),

                  if (_activeJobs.isNotEmpty)
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Nearby jobs
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(title: 'Nearby Jobs', actionText: 'Browse all', onAction: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowseJobsScreen()));
                      }),
                    ),
                  ),

                  if (_availableJobs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: EmptyState(
                          icon: '🔍',
                          title: 'No jobs available',
                          subtitle: 'Check back soon for new jobs in your area',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final job = _availableJobs[index];
                            final catName = job['category']?['name'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: JobListingCard(
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
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.jobDetail,
                                    arguments: _jobDetailFromMap(job),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: _availableJobs.length > 5 ? 5 : _availableJobs.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
      ),
    );
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
