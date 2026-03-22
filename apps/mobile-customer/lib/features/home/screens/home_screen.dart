import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import 'category_detail_screen.dart';
import '../../workers/screens/worker_screens.dart';
import '../../jobs/screens/my_jobs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _userName = '';
  String _userLocation = 'Sri Lanka';
  List<dynamic> _workers = [];
  List<dynamic> _myJobs = [];
  int _activeJobCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService().getMe(),
        ApiService().getWorkers(),
        ApiService().getMyJobs(),
      ]);
      final user = (results[0] as Map)['user'];
      final workers = results[1] as List;
      final jobsData = results[2] as Map;
      final jobs = jobsData['jobs'] as List;

      setState(() {
        _userName = user['name'] ?? AuthService().currentUser?.displayName ?? '';
        _userLocation = user['customerProfile']?['address'] ?? 'Sri Lanka';
        _workers = workers.take(3).toList();
        _myJobs = jobs;
        _activeJobCount = jobs.where((j) =>
          j['status'] == 'OPEN' || j['status'] == 'ASSIGNED' || j['status'] == 'IN_PROGRESS'
        ).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = AuthService().currentUser?.displayName ?? '';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.errorMessage(e))),
        );
      }
    }
  }

  String _mapStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'OPEN': return JobStatus.posted;
      case 'APPLICATIONS_RECEIVED': return JobStatus.applicationsReceived;
      case 'ASSIGNED': return JobStatus.workerAccepted;
      case 'IN_PROGRESS': return JobStatus.inProgress;
      case 'COMPLETED': return JobStatus.completed;
      case 'REVIEWING': return JobStatus.reviewed;
      case 'CLOSED': return JobStatus.closed;
      case 'CANCELLED': return JobStatus.cancelled;
      default: return JobStatus.posted;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _getBadgeLevel(Map<dynamic, dynamic> worker) {
    final status = worker['verificationStatus'] ?? '';
    final totalJobs = (worker['totalJobs'] ?? 0) as int;
    if (status == 'VERIFIED' && totalJobs >= 100) return BadgeLevel.platinum;
    if (status == 'VERIFIED' && totalJobs >= 50) return BadgeLevel.gold;
    if (status == 'VERIFIED' && totalJobs >= 20) return BadgeLevel.silver;
    if (status == 'VERIFIED' || totalJobs >= 5) return BadgeLevel.bronze;
    return BadgeLevel.trainee;
  }

  String _getCategoryIcon(String? name) {
    final cat = AppCategories.all.where((c) => c.name.toLowerCase() == (name ?? '').toLowerCase());
    return cat.isNotEmpty ? cat.first.icon : '🔧';
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getGreeting(),
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                                const SizedBox(height: 2),
                                Text(_userName.split(' ').first, style: AppTypography.displaySmall),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(_userLocation.length > 15 ? '${_userLocation.substring(0, 15)}...' : _userLocation, style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/notifications'),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border)),
                              child: Stack(children: [
                                const Center(child: Icon(Icons.notifications_outlined, size: 20, color: AppColors.textPrimary)),
                                Positioned(top: 8, right: 8,
                                  child: Container(width: 8, height: 8,
                                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('What do you need\ndone today?', style: AppTypography.displayLarge),
                    ),
                    const SizedBox(height: 18),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DoerSearchBar(onTap: () => Navigator.pushNamed(context, '/search')),
                    ),
                    const SizedBox(height: 28),

                    // Categories
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(title: 'Services', actionText: 'See all', onAction: () {}),
                    ),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: AppCategories.all.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final cat = AppCategories.all[index];
                          return CategoryChip(category: cat, compact: true, onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => CategoryDetailScreen(category: cat),
                            ));
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Active jobs banner
                    if (_activeJobCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/my-jobs'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                            child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('You have $_activeJobCount active job${_activeJobCount > 1 ? 's' : ''}',
                                  style: AppTypography.headlineSmall.copyWith(color: Colors.white)),
                                const SizedBox(height: 2),
                                Text('Track progress and chat with workers',
                                  style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                              ]),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                          ]),
                          ),
                        ),
                      ),

                    if (_activeJobCount > 0) const SizedBox(height: 28),

                    // Top rated workers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(title: 'Top rated near you', actionText: 'See all',
                        onAction: () => Navigator.pushNamed(context, '/browse-workers')),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _workers.isEmpty
                        ? Text('No workers available yet', style: AppTypography.bodySmall)
                        : Column(
                            children: _workers.map<Widget>((w) {
                              final user = w['user'] ?? {};
                              final cats = w['categories'] as List? ?? [];
                              final catName = cats.isNotEmpty ? (cats[0]['category']?['name'] ?? '') : '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: WorkerCard(
                                  name: user['name'] ?? '',
                                  skill: catName,
                                  badge: _getBadgeLevel(w),
                                  rating: (w['rating'] ?? 0).toDouble(),
                                  distance: 0,
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => WorkerProfileScreen(
                                        workerId: w['id'].toString(),
                                      ),
                                    ));
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                    ),
                    const SizedBox(height: 28),

                    // Recent jobs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(title: 'Recent jobs', actionText: 'View all', onAction: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const MyJobsScreen(),
                        ));
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _myJobs.isEmpty
                        ? Text('No jobs yet. Post your first job!', style: AppTypography.bodySmall)
                        : Column(
                            children: _myJobs.take(3).map<Widget>((job) {
                              final catName = job['category']?['name'] ?? '';
                              final workerUser = job['worker']?['user'];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: JobCard(
                                  title: job['title'] ?? '',
                                  category: catName,
                                  categoryIcon: _getCategoryIcon(catName),
                                  status: _mapStatus(job['status']),
                                  budget: job['price'] != null ? 'Rs. ${job['price'].toStringAsFixed(0)}' : 'TBD',
                                  date: _timeAgo(job['createdAt']),
                                  workerName: workerUser != null ? workerUser['name'] ?? '' : '',
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => JobDetailScreen(jobId: job['id']),
                                    ));
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}
