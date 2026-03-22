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
  double _pendingEarnings = 0;
  double _disputedAmount = 0;
  double _thisMonthEarnings = 0;
  int _thisMonthCount = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService().getEarnings();
      setState(() {
        _totalEarnings = (data['totalEarnings'] ?? 0).toDouble();
        _pendingEarnings = (data['pendingEarnings'] ?? 0).toDouble();
        _disputedAmount = (data['disputedAmount'] ?? 0).toDouble();
        _thisMonthEarnings = (data['thisMonthEarnings'] ?? 0).toDouble();
        _thisMonthCount = data['thisMonthCount'] ?? 0;
        _payments = data['payments'] as List? ?? [];
        _isLoading = false;
      });
    } catch (_) {
      // Fallback to basic payments list
      try {
        _payments = await ApiService().getMyPayments();
        _totalEarnings = 0;
        _pendingEarnings = 0;
        for (final p in _payments) {
          final amount = (p['amount'] ?? 0).toDouble();
          if (p['status'] == 'RELEASED') _totalEarnings += amount;
          if (p['status'] == 'HELD') _pendingEarnings += amount;
          if (p['status'] == 'DISPUTED') _disputedAmount += amount;
        }
      } catch (_) {}
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

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'RELEASED': return 'Released';
      case 'HELD': return 'In Escrow';
      case 'DISPUTED': return 'Disputed';
      case 'REFUNDED': return 'Refunded';
      case 'PENDING': return 'Pending';
      default: return status ?? 'Unknown';
    }
  }

  Color _statusColor(String label) {
    switch (label) {
      case 'Released': return AppColors.success;
      case 'In Escrow': return AppColors.warning;
      case 'Disputed': return AppColors.error;
      case 'Refunded': return Colors.purple;
      default: return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String label) {
    switch (label) {
      case 'Released': return Icons.check_circle_outline;
      case 'In Escrow': return Icons.hourglass_top_rounded;
      case 'Disputed': return Icons.gavel_rounded;
      case 'Refunded': return Icons.replay_rounded;
      default: return Icons.schedule;
    }
  }

  Future<void> _respondToDispute(Map<String, dynamic> payment) async {
    final jobId = payment['job']?['id'];
    if (jobId == null) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Respond to Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide your side of the story for "${payment['job']?['title'] ?? 'this job'}".',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe what happened...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    try {
      await ApiService().respondToDispute(jobId, response: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response submitted successfully')),
      );
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.errorMessage(e))),
      );
    }
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
        : RefreshIndicator(
            onRefresh: _fetch,
            child: CustomScrollView(
              slivers: [
                // Earnings summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: EarningsSummaryCard(
                      totalEarnings: 'Rs. ${_totalEarnings.toStringAsFixed(0)}',
                      pendingPayout: 'Rs. ${_pendingEarnings.toStringAsFixed(0)}',
                      thisMonth: '$_thisMonthCount payments · Rs. ${_thisMonthEarnings.toStringAsFixed(0)}',
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Disputed amount warning
                if (_disputedAmount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gavel_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Rs. ${_disputedAmount.toStringAsFixed(0)} is under dispute. Respond to disputes below.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.error, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_disputedAmount > 0)
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

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
                            final label = _statusLabel(p['status']);
                            final color = _statusColor(label);
                            final isDisputed = label == 'Disputed';
                            final hasResponse = p['dispute']?['workerResponse'] != null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isDisputed ? AppColors.error.withValues(alpha: 0.3) : AppColors.border)),
                                child: Column(
                                  children: [
                                    Row(children: [
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10)),
                                        child: Icon(_statusIcon(label), color: color, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(job?['title'] ?? 'Payment', style: AppTypography.headlineSmall),
                                          const SizedBox(height: 2),
                                          Text(label, style: AppTypography.bodySmall.copyWith(color: color)),
                                        ]),
                                      ),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        Text('Rs. ${(p['amount'] ?? 0).toStringAsFixed(0)}',
                                          style: AppTypography.headlineSmall.copyWith(color: color)),
                                        Text(_formatDate(p['createdAt']), style: AppTypography.labelSmall),
                                      ]),
                                    ]),
                                    // Show respond button for disputed payments
                                    if (isDisputed && !hasResponse) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _respondToDispute(p),
                                          icon: const Icon(Icons.reply_rounded, size: 16),
                                          label: const Text('Respond to Dispute'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: const BorderSide(color: AppColors.error),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isDisputed && hasResponse) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('Response submitted — awaiting admin review',
                                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
          ),
    );
  }
}
