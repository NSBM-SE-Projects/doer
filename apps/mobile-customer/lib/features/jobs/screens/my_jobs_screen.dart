import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../messaging/screens/messaging_screens.dart';
import '../../reviews/screens/review_notification_screens.dart';

// ──────────────────────────────────────────────────────────────
// MY JOBS SCREEN
// Tabbed view with 3 tabs: Active, Completed, Cancelled.
// Each tab shows a list of JobCards filtered by status.
// Has a FAB to post a new job.
// ──────────────────────────────────────────────────────────────
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
  List<dynamic> _completedJobs = [];
  List<dynamic> _cancelledJobs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getMyJobs();
      final jobs = data['jobs'] as List;
      setState(() {
        _activeJobs = jobs.where((j) => j['status'] == 'OPEN' || j['status'] == 'APPLICATIONS_RECEIVED' || j['status'] == 'ASSIGNED' || j['status'] == 'IN_PROGRESS').toList();
        _completedJobs = jobs.where((j) => j['status'] == 'COMPLETED' || j['status'] == 'REVIEWING' || j['status'] == 'CLOSED').toList();
        _cancelledJobs = jobs.where((j) => j['status'] == 'CANCELLED').toList();
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

  String _getCategoryIcon(String? name) {
    final cat = AppCategories.all.where((c) => c.name.toLowerCase() == (name ?? '').toLowerCase());
    return cat.isNotEmpty ? cat.first.icon : '🔧';
  }

  /// Map backend status (OPEN, ASSIGNED, etc.) to app status (posted, worker_accepted, etc.)
  String _mapStatus(String? backendStatus) {
    switch (backendStatus?.toUpperCase()) {
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: AppTypography.labelLarge,
          unselectedLabelStyle: AppTypography.labelMedium,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildJobListFromApi(_activeJobs, 'No active jobs', 'Post a job to get started'),
              _buildJobListFromApi(_completedJobs, 'No completed jobs', 'Completed jobs will appear here'),
              _buildJobListFromApi(_cancelledJobs, 'No cancelled jobs', 'Jobs you cancel will appear here'),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/post-job');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Job'),
      ),
    );
  }

  Widget _buildJobListFromApi(List<dynamic> jobs, String emptyTitle, String emptySub) {
    if (jobs.isEmpty) {
      return EmptyState(icon: '📭', title: emptyTitle, subtitle: emptySub);
    }
    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final job = jobs[i];
          final catName = job['category']?['name'] ?? '';
          final workerUser = job['worker']?['user'];
          return JobCard(
            title: job['title'] ?? '',
            category: catName,
            categoryIcon: _getCategoryIcon(catName),
            status: _mapStatus(job['status']),
            budget: job['price'] != null ? 'Rs. ${job['price'].toStringAsFixed(0)}' : 'TBD',
            date: _timeAgo(job['createdAt']),
            workerName: workerUser?['name'] ?? '',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job['id'])));
            },
          );
        },
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

// ──────────────────────────────────────────────────────────────
// JOB DETAIL SCREEN
// Full view of a single job. Sections:
//   1. Header: category icon + title + status pill
//   2. Timeline: visual progress (Posted -> Matched -> In Progress -> Done)
//   3. Worker card: assigned worker with chat/call buttons
//   4. Job details: description, budget, date, location, urgency
//   5. Payment info: agreed price + escrow status
//   6. Bottom bar: Cancel Job / Release Payment buttons
// ──────────────────────────────────────────────────────────────
class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isLoading = true;
  bool _actionLoading = false;
  Map<String, dynamic>? _job;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchJob();
  }

  Future<void> _fetchJob() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService().getJob(widget.jobId);
      setState(() { _job = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load job details'; _isLoading = false; });
    }
  }

  String _getCategoryIcon(String? name) {
    final cat = AppCategories.all.where((c) => c.name.toLowerCase() == (name ?? '').toLowerCase());
    return cat.isNotEmpty ? cat.first.icon : '🔧';
  }

  Color _getCategoryColor(String? name) {
    switch (name?.toLowerCase()) {
      case 'plumbing': return AppColors.categoryPlumbing;
      case 'electrical': return AppColors.categoryElectrical;
      case 'cleaning': return AppColors.categoryCleaning;
      case 'painting': return AppColors.categoryPainting;
      case 'gardening': return AppColors.categoryGardening;
      case 'moving': return AppColors.categoryMoving;
      default: return AppColors.categoryPlumbing;
    }
  }

  String _mapStatus(String? backendStatus) {
    switch (backendStatus?.toUpperCase()) {
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy · h:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatBudget(dynamic min, dynamic max) {
    if (min != null && max != null) {
      return 'Rs. ${_formatNumber(min)} — Rs. ${_formatNumber(max)}';
    } else if (min != null) {
      return 'Rs. ${_formatNumber(min)}+';
    } else if (max != null) {
      return 'Up to Rs. ${_formatNumber(max)}';
    }
    return 'TBD';
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final num n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,##0').format(n);
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'TBD';
    return 'Rs. ${_formatNumber(price)}';
  }

  String _getPaymentStatus(Map<String, dynamic>? payment, String? jobStatus) {
    if (payment == null) {
      if (jobStatus == 'COMPLETED') return 'Pending payment';
      return 'No payment yet';
    }
    final status = payment['status']?.toString().toUpperCase() ?? '';
    switch (status) {
      case 'HELD': return 'Held in escrow';
      case 'RELEASED': return 'Released';
      case 'REFUNDED': return 'Refunded';
      case 'PENDING': return 'Pending';
      default: return status.isNotEmpty ? status : 'N/A';
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Held in escrow': return AppColors.warning;
      case 'Released': return AppColors.success;
      case 'Refunded': return AppColors.error;
      default: return AppColors.textTertiary;
    }
  }

  Color _getPaymentStatusBgColor(String status) {
    switch (status) {
      case 'Held in escrow': return AppColors.warningLight;
      case 'Released': return AppColors.successLight;
      case 'Refunded': return AppColors.errorLight;
      default: return AppColors.surfaceVariant;
    }
  }

  Future<void> _cancelJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Job'),
        content: const Text('Are you sure you want to cancel this job? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, keep it')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ApiService().cancelJob(widget.jobId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job cancelled successfully')),
      );
      _fetchJob();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel job: $e')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _releasePayment() async {
    final price = _formatPrice(_job?['price']);
    final workerName = _job?['worker']?['user']?['name'] ?? 'the worker';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Payment'),
        content: Text('Release $price directly to $workerName? This confirms the job is complete.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Release Funds'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      await ApiService().createPayment(widget.jobId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$price released to $workerName'), backgroundColor: AppColors.success),
      );
      _fetchJob();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.errorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _openChat() {
    final workerName = _job?['worker']?['user']?['name'] ?? 'Worker';
    final jobTitle = _job?['title'] ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          jobId: widget.jobId,
          workerName: workerName,
          jobTitle: jobTitle,
        ),
      ),
    );
  }

  /// Build timeline items dynamically based on the job status
  List<_TimelineItem> _buildTimelineItems() {
    final status = _job?['status']?.toString().toUpperCase() ?? 'OPEN';
    final workerName = _job?['worker']?['user']?['name'];
    final createdAt = _formatDate(_job?['createdAt']);
    final completedAt = _formatDate(_job?['completedAt']);

    // Status ordering for progress calculation
    // Normalize statuses to the 4-step timeline
    final normalizedStatus = status == 'APPLICATIONS_RECEIVED' ? 'OPEN'
        : (status == 'REVIEWING' || status == 'CLOSED') ? 'COMPLETED'
        : status;
    const statusOrder = ['OPEN', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED'];
    final currentIndex = statusOrder.indexOf(normalizedStatus);

    if (status == 'CANCELLED') {
      return [
        _TimelineItem(
          title: 'Job Posted',
          subtitle: createdAt,
          isCompleted: true,
          isFirst: true,
        ),
        _TimelineItem(
          title: 'Cancelled',
          subtitle: 'This job was cancelled',
          isCompleted: true,
          isLast: true,
        ),
      ];
    }

    return [
      _TimelineItem(
        title: 'Job Posted',
        subtitle: createdAt,
        isCompleted: currentIndex >= 0,
        isActive: currentIndex == 0,
        isFirst: true,
      ),
      _TimelineItem(
        title: 'Worker Matched',
        subtitle: workerName != null ? '$workerName accepted' : 'Waiting for a worker',
        isCompleted: currentIndex >= 1,
        isActive: currentIndex == 1,
      ),
      _TimelineItem(
        title: 'In Progress',
        subtitle: currentIndex >= 2 ? 'Work underway' : 'Pending',
        isCompleted: currentIndex >= 2,
        isActive: currentIndex == 2,
      ),
      _TimelineItem(
        title: 'Completed',
        subtitle: currentIndex >= 3 ? completedAt : 'Pending',
        isCompleted: currentIndex >= 3,
        isActive: currentIndex == 3,
        isLast: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Job Details'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'cancel' && _job != null) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel Job'),
                    content: const Text('Are you sure you want to cancel this job?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Yes, Cancel', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await ApiService().cancelJob(widget.jobId);
                    if (mounted) _fetchJob();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiService.errorMessage(e))));
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'cancel', child: Text('Cancel Job')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _fetchJob, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildBody(),
      bottomNavigationBar: (!_isLoading && _error == null && _job != null) ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    final job = _job!;
    final categoryName = job['category']?['name'] ?? '';
    final title = job['title'] ?? 'Untitled Job';
    final description = job['description'] ?? '';
    final status = _mapStatus(job['status']);
    final workerUser = job['worker']?['user'];
    final workerName = workerUser?['name'] ?? '';
    final workerRating = job['worker']?['rating'];
    final price = job['price'];
    final budgetMin = job['budgetMin'];
    final budgetMax = job['budgetMax'];
    final urgency = job['urgency'] ?? 'Normal';
    final address = job['address'] ?? 'N/A';
    final scheduledAt = _formatDate(job['scheduledAt']);
    final payment = job['payment'];
    final jobStatus = job['status']?.toString().toUpperCase() ?? '';
    final paymentStatusText = _getPaymentStatus(payment, jobStatus);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- 1. Header --
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(categoryName),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(_getCategoryIcon(categoryName),
                        style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headlineLarge),
                    const SizedBox(height: 4),
                    Text(categoryName, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              JobStatusPill(status: status),
            ],
          ),

          const SizedBox(height: 24),

          // -- 2. Timeline --
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Job Timeline', style: AppTypography.headlineMedium),
                const SizedBox(height: 16),
                ..._buildTimelineItems(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -- 3. Worker info (only show if a worker is assigned) --
          if (workerName.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Text(
                        workerName.isNotEmpty ? workerName[0].toUpperCase() : '?',
                        style: AppTypography.headlineMedium
                            .copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workerName, style: AppTypography.headlineSmall),
                        Row(
                          children: [
                            if (workerRating != null) ...[
                              Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.badgeGold),
                              const SizedBox(width: 3),
                              Text(
                                  workerRating is num
                                      ? workerRating.toStringAsFixed(1)
                                      : workerRating.toString(),
                                  style: AppTypography.labelMedium),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chat button
                  _ActionIcon(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary,
                      onTap: _openChat),
                  const SizedBox(width: 4),
                  // Call button
                  _ActionIcon(
                      icon: Icons.phone_outlined,
                      color: AppColors.success,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Contact Support'),
                            content: const Text('For support, email us at:\nsupport@doer.lk'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                            ],
                          ),
                        );
                      }),
                ],
              ),
            ),

          if (workerName.isNotEmpty) const SizedBox(height: 20),

          // -- 3b. Applications (show when job is OPEN or APPLICATIONS_RECEIVED) --
          if (jobStatus == 'OPEN' || jobStatus == 'APPLICATIONS_RECEIVED')
            _ApplicationsSection(
              jobId: widget.jobId,
              onAccepted: _fetchJob,
            ),

          if (jobStatus == 'OPEN' || jobStatus == 'APPLICATIONS_RECEIVED')
            const SizedBox(height: 20),

          // -- 4. Job details --
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: AppTypography.headlineMedium),
                const SizedBox(height: 14),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary, height: 1.6),
                  ),
                if (description.isNotEmpty) const SizedBox(height: 20),
                _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Budget',
                    value: _formatBudget(budgetMin, budgetMax)),
                const SizedBox(height: 12),
                _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Scheduled',
                    value: scheduledAt),
                const SizedBox(height: 12),
                _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: address),
                const SizedBox(height: 12),
                _DetailRow(
                    icon: Icons.bolt_rounded,
                    label: 'Urgency',
                    value: urgency),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -- 5. Payment --
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment', style: AppTypography.headlineMedium),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Agreed Price',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    Text(_formatPrice(price), style: AppTypography.headlineSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Status',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusBgColor(paymentStatusText),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(paymentStatusText,
                          style: AppTypography.labelSmall.copyWith(
                              color: _getPaymentStatusColor(paymentStatusText),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    final status = _job?['status']?.toString().toUpperCase() ?? '';
    if (status == 'CANCELLED' || status == 'CLOSED') return null;

    final canCancel = status == 'OPEN' || status == 'ASSIGNED' || status == 'IN_PROGRESS';
    final isCompletedOrReviewing = status == 'COMPLETED' || status == 'REVIEWING';
    final hasPayment = _job?['payment'] != null;
    final hasReview = _job?['review'] != null;
    final canPay = isCompletedOrReviewing && !hasPayment;
    final canReview = isCompletedOrReviewing && !hasReview;

    if (!canCancel && !canPay && !canReview) return null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          if (canCancel)
            Expanded(
                child: DoerButton(
                    label: 'Cancel Job',
                    isOutlined: true,
                    onPressed: _actionLoading ? null : _cancelJob)),
          if (canCancel && (canPay || canReview)) const SizedBox(width: 12),
          if (canPay)
            Expanded(
                child: DoerButton(
                    label: 'Confirm & Pay',
                    onPressed: _actionLoading ? null : _releasePayment)),
          if (canPay && canReview) const SizedBox(width: 12),
          if (canReview)
            Expanded(
                child: DoerButton(
                    label: 'Leave Review',
                    isOutlined: canPay,
                    icon: Icons.star_outline_rounded,
                    onPressed: () {
                      final workerName = _job?['worker']?['user']?['name'] ?? 'Worker';
                      final jobTitle = _job?['title'] ?? '';
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => RateReviewScreen(
                          jobId: widget.jobId,
                          workerName: workerName,
                          jobTitle: jobTitle,
                        ),
                      )).then((_) => _fetchJob());
                    })),
        ],
      ),
    );
  }
}

// -- Timeline step widget --
class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Vertical line + circle dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted || isActive
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                // Circle indicator
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.primary
                        : isActive
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.border,
                    border: isActive
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.headlineSmall.copyWith(
                          color: isCompleted || isActive
                              ? AppColors.textPrimary
                              : AppColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall.copyWith(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textTertiary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Detail row (icon + label + value) --
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: AppTypography.bodySmall)),
        Expanded(
            child: Text(value,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500))),
      ],
    );
  }
}

// -- Small round icon button (chat/call) --
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// -- Applications section for OPEN jobs --
class _ApplicationsSection extends StatefulWidget {
  final String jobId;
  final VoidCallback onAccepted;
  const _ApplicationsSection({required this.jobId, required this.onAccepted});

  @override
  State<_ApplicationsSection> createState() => _ApplicationsSectionState();
}

class _ApplicationsSectionState extends State<_ApplicationsSection> {
  bool _isLoading = true;
  List<dynamic> _applications = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      _applications = await ApiService().getJobApplications(widget.jobId);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _accept(String applicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Application'),
        content: const Text('Accept this worker? Other pending applications will be automatically rejected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiService().acceptApplication(applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application accepted! Worker assigned.')),
        );
        widget.onAccepted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.errorMessage(e))),
        );
      }
    }
  }

  Future<void> _reject(String applicationId) async {
    try {
      await ApiService().rejectApplication(applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application rejected')),
        );
        _fetch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ));
    }

    final pending = _applications.where((a) =>
      (a['status'] ?? '').toString().toUpperCase() == 'PENDING'
    ).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Applications', style: AppTypography.headlineMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pending.length}',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No applications yet. Workers will apply once they see your job.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ...pending.map((app) {
              final worker = app['worker'];
              final workerUser = worker?['user'];
              final name = workerUser?['name'] ?? 'Worker';
              final rating = (worker?['rating'] ?? 0).toDouble();
              final message = app['message'] ?? '';
              final price = app['price'];
              final appId = app['id'] as String;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceVariant,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTypography.headlineSmall),
                              Row(children: [
                                const Icon(Icons.star_rounded, size: 13, color: AppColors.badgeGold),
                                const SizedBox(width: 3),
                                Text(rating.toStringAsFixed(1), style: AppTypography.labelSmall),
                              ]),
                            ],
                          ),
                        ),
                        if (price != null)
                          Text(
                            'Rs. ${price.toStringAsFixed(0)}',
                            style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                          ),
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        message,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: () => _reject(appId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error, width: 0.5),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Reject', style: AppTypography.labelMedium.copyWith(color: AppColors.error)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () => _accept(appId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Accept', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
