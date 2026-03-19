import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// PAYMENT SCREEN (CHECKOUT)
// From the Doer spec: payments use escrow — money is held safely
// until both parties confirm job completion. This screen shows:
//   1. Job summary with price breakdown
//   2. Escrow info banner
//   3. Payment method selector (card / bank / mobile wallet)
//   4. Card details form (when card selected)
//   5. Pay button → success bottom sheet
// ──────────────────────────────────────────────────────────────
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Make Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Job summary ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.categoryPlumbing,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                            child:
                                Text('🔧', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fix kitchen sink leak',
                                style: AppTypography.headlineSmall),
                            Text('Saman Fernando',
                                style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  _PriceRow(label: 'Service Fee', value: 'Rs. 4,500'),
                  const SizedBox(height: 8),
                  _PriceRow(
                      label: 'Platform Fee', value: 'Rs. 0', isFree: true),
                  const SizedBox(height: 8),
                  _PriceRow(label: 'Tax', value: 'Rs. 0'),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTypography.headlineMedium),
                      Text('Rs. 4,500',
                          style: AppTypography.headlineLarge
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 2. Escrow info ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppColors.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your payment is held securely in escrow and only released to the worker after you confirm job completion.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.info, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 3. Payment methods ──
            Text('Payment Method', style: AppTypography.headlineMedium),
            const SizedBox(height: 14),
            _PaymentMethodTile(
              icon: Icons.credit_card_rounded,
              title: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, Amex',
              selected: _selectedMethod == 'card',
              onTap: () => setState(() => _selectedMethod = 'card'),
            ),
            const SizedBox(height: 10),
            _PaymentMethodTile(
              icon: Icons.account_balance_rounded,
              title: 'Bank Transfer',
              subtitle: 'Direct bank transfer',
              selected: _selectedMethod == 'bank',
              onTap: () => setState(() => _selectedMethod = 'bank'),
            ),
            const SizedBox(height: 10),
            _PaymentMethodTile(
              icon: Icons.phone_android_rounded,
              title: 'eZ Cash / mCash',
              subtitle: 'Mobile wallet payment',
              selected: _selectedMethod == 'mobile',
              onTap: () => setState(() => _selectedMethod = 'mobile'),
            ),

            const SizedBox(height: 28),

            // ── 4. Card form (only when card selected) ──
            if (_selectedMethod == 'card') ...[
              Text('Card Details', style: AppTypography.headlineMedium),
              const SizedBox(height: 14),
              TextField(
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Card Number',
                  prefixIcon: Icon(Icons.credit_card_outlined,
                      size: 20, color: AppColors.textTertiary),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: AppTypography.bodyMedium,
                      decoration: const InputDecoration(hintText: 'MM/YY'),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: AppTypography.bodyMedium,
                      decoration: const InputDecoration(hintText: 'CVV'),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                style: AppTypography.bodyMedium,
                decoration:
                    const InputDecoration(hintText: 'Cardholder Name'),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ],
        ),
      ),
      // ── 5. Pay button ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: DoerButton(
          label: 'Pay Rs. 4,500',
          icon: Icons.lock_rounded,
          onPressed: () => _showPaymentSuccess(context),
        ),
      ),
    );
  }

  // Success bottom sheet after payment
  void _showPaymentSuccess(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Payment Successful!',
                style: AppTypography.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Rs. 4,500 has been securely held in escrow.\nIt will be released once you confirm job completion.',
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            DoerButton(
              label: 'Track Job',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('Back to Home',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// Price row in job summary
class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFree;
  const _PriceRow(
      {required this.label, required this.value, this.isFree = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        Row(
          children: [
            Text(value, style: AppTypography.bodyMedium),
            if (isFree) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('FREE',
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 9)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Payment method selector tile
class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.headlineSmall),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// PAYMENT HISTORY SCREEN
// Shows spending summary card + monthly grouped transactions.
// Each transaction shows status: Completed, In Escrow, or Refunded.
// ──────────────────────────────────────────────────────────────
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment History'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Total spending card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Spent',
                    style: AppTypography.bodySmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Text('Rs. 45,500',
                    style: AppTypography.displayLarge
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('9 completed transactions',
                    style: AppTypography.labelSmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text('March 2026', style: AppTypography.labelMedium),
          const SizedBox(height: 12),
          _TransactionItem(
              title: 'Fix kitchen sink leak',
              worker: 'Saman Fernando',
              amount: 'Rs. 4,500',
              date: 'Mar 19',
              status: 'In Escrow',
              statusColor: AppColors.warning),
          _TransactionItem(
              title: 'Rewire living room',
              worker: 'Nimal Perera',
              amount: 'Rs. 12,000',
              date: 'Mar 15',
              status: 'Completed',
              statusColor: AppColors.success),
          _TransactionItem(
              title: 'Deep clean apartment',
              worker: 'Kumari Silva',
              amount: 'Rs. 8,000',
              date: 'Mar 8',
              status: 'Completed',
              statusColor: AppColors.success),

          const SizedBox(height: 20),

          Text('February 2026', style: AppTypography.labelMedium),
          const SizedBox(height: 12),
          _TransactionItem(
              title: 'Paint bedroom walls',
              worker: 'Ruwan Jayasinghe',
              amount: 'Rs. 15,000',
              date: 'Feb 22',
              status: 'Completed',
              statusColor: AppColors.success),
          _TransactionItem(
              title: 'Garden maintenance',
              worker: 'Priya Rajapaksa',
              amount: 'Rs. 6,000',
              date: 'Feb 10',
              status: 'Refunded',
              statusColor: AppColors.error),
        ],
      ),
    );
  }
}

// Single transaction row
class _TransactionItem extends StatelessWidget {
  final String title;
  final String worker;
  final String amount;
  final String date;
  final String status;
  final Color statusColor;

  const _TransactionItem({
    required this.title,
    required this.worker,
    required this.amount,
    required this.date,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              status == 'Completed'
                  ? Icons.check_circle_outline_rounded
                  : status == 'Refunded'
                      ? Icons.replay_rounded
                      : Icons.hourglass_top_rounded,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineSmall),
                const SizedBox(height: 2),
                Text('$worker · $date', style: AppTypography.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: AppTypography.headlineSmall
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(status,
                  style: AppTypography.labelSmall.copyWith(
                      color: statusColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
