import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _isLoading = true;
  List<dynamic> _payments = [];
  double _totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      _payments = await ApiService().getMyPayments();
      _totalEarnings = 0;
      for (final p in _payments) {
        if (p['status'] == 'COMPLETED') {
          _totalEarnings += (p['amount'] ?? 0).toDouble();
        }
      }
      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: EarningsSummaryCard(
                    totalEarnings: 'Rs. ${_totalEarnings.toStringAsFixed(0)}',
                    pendingPayout: 'Rs. ${_payments.where((p) => p['status'] == 'PENDING').fold<double>(0, (sum, p) => sum + (p['amount'] ?? 0).toDouble()).toStringAsFixed(0)}',
                    thisMonth: '${_payments.length} payments',
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Subscription status
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.subscriptions_outlined, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Monthly Subscription', style: AppTypography.headlineSmall),
                          Text('Not subscribed',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ]),
                      ),
                      Text('Free', style: AppTypography.headlineSmall.copyWith(color: AppColors.primary)),
                    ]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(title: 'Payment History'),
                ),
              ),

              _payments.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: EmptyState(icon: '💰', title: 'No payments yet',
                          subtitle: 'Complete jobs to see your payment history'),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = _payments[index];
                          final job = p['job'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border)),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: p['status'] == 'COMPLETED' ? AppColors.successLight : AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(10)),
                                  child: Icon(
                                    p['status'] == 'COMPLETED' ? Icons.check_circle_outline : Icons.schedule,
                                    color: p['status'] == 'COMPLETED' ? AppColors.success : AppColors.warning, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(job?['title'] ?? 'Payment', style: AppTypography.headlineSmall),
                                    const SizedBox(height: 2),
                                    Text(p['status'] ?? '', style: AppTypography.bodySmall),
                                  ]),
                                ),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('Rs. ${(p['amount'] ?? 0).toStringAsFixed(0)}',
                                    style: AppTypography.headlineSmall.copyWith(color: AppColors.success)),
                                  Text(_formatDate(p['createdAt']), style: AppTypography.labelSmall),
                                ]),
                              ]),
                            ),
                          );
                        },
                        childCount: _payments.length,
                      ),
                    ),
                  ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
    );
  }
}
