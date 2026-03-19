import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// EARNINGS SCREEN
// Shows worker's full earnings breakdown:
//   - Total / pending / this month summary card
//   - Payout history list
// Workers keep 100% earnings (flat monthly subscription model).
// ──────────────────────────────────────────────────────────────
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  static const _payouts = [
    _PayoutData('Fix kitchen plumbing', 'Rs. 3,500', 'Mar 15, 2026',
        'Nimal Jayawardena', true),
    _PayoutData('Install ceiling fan', 'Rs. 2,000', 'Mar 12, 2026',
        'Priya Fernando', true),
    _PayoutData('House deep cleaning', 'Rs. 4,200', 'Mar 8, 2026',
        'Amali Senanayake', true),
    _PayoutData('Paint bedroom walls', 'Rs. 6,500', 'Mar 3, 2026',
        'Saman Wickramasinghe', true),
    _PayoutData('Garden maintenance', 'Rs. 1,800', 'Feb 28, 2026',
        'Kasun Ranasinghe', false),
  ];

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
      body: CustomScrollView(
        slivers: [
          // Earnings summary card
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: EarningsSummaryCard(
                totalEarnings: 'Rs. 48,500',
                pendingPayout: 'Rs. 6,200',
                thisMonth: 'Rs. 12,800',
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.subscriptions_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Subscription',
                              style: AppTypography.headlineSmall),
                          Text(
                            'Active · Renews Apr 1, 2026',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. 990/mo',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Payout history header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Payout History'),
            ),
          ),

          // Payout list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final payout = _payouts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PayoutCard(payout: payout),
                  );
                },
                childCount: _payouts.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  final _PayoutData payout;
  const _PayoutCard({super.key, required this.payout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payout.jobTitle, style: AppTypography.headlineSmall),
                const SizedBox(height: 2),
                Text(payout.clientName, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payout.amount,
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
              Text(payout.date, style: AppTypography.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutData {
  final String jobTitle;
  final String amount;
  final String date;
  final String clientName;
  final bool isPaid;

  const _PayoutData(
      this.jobTitle, this.amount, this.date, this.clientName, this.isPaid);
}
