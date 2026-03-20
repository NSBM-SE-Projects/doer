import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
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
  final String jobId;
  const PaymentScreen({super.key, required this.jobId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'card';
  bool _loading = true;
  bool _paying = false;
  String? _error;
  Map<String, dynamic>? _job;

  @override
  void initState() {
    super.initState();
    _fetchJob();
  }

  Future<void> _fetchJob() async {
    try {
      final job = await ApiService().getJob(widget.jobId);
      setState(() {
        _job = job;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiService.errorMessage(e);
        _loading = false;
      });
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rs. 0';
    final num amount = price is num ? price : num.tryParse(price.toString()) ?? 0;
    final formatter = NumberFormat('#,###', 'en_US');
    return 'Rs. ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Make Payment'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _job == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Make Payment'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Failed to load job', style: AppTypography.bodyMedium),
              const SizedBox(height: 12),
              TextButton(onPressed: () { setState(() { _loading = true; _error = null; }); _fetchJob(); }, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final jobTitle = _job!['title'] ?? 'Untitled Job';
    final workerProfile = _job!['worker'];
    final workerUser = workerProfile?['user'];
    final workerName = workerUser?['name'] ?? 'Unknown Worker';
    final price = _job!['price'];
    final priceStr = _formatPrice(price);
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
                            Text(jobTitle,
                                style: AppTypography.headlineSmall),
                            Text(workerName,
                                style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 12),
                  _PriceRow(label: 'Service Fee', value: priceStr),
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
                      Text(priceStr,
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
          label: 'Pay $priceStr',
          icon: Icons.lock_rounded,
          onPressed: _paying ? null : () => _handlePay(context, priceStr),
        ),
      ),
    );
  }

  // Call API to create payment, then show success
  Future<void> _handlePay(BuildContext ctx, String priceStr) async {
    setState(() => _paying = true);
    try {
      await ApiService().createPayment(widget.jobId);
      if (!ctx.mounted) return;
      _showPaymentSuccess(ctx, priceStr);
    } catch (e) {
      if (!ctx.mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(ApiService.errorMessage(e))),
      );
    }
  }

  // Success bottom sheet after payment
  void _showPaymentSuccess(BuildContext context, String priceStr) {
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
              '$priceStr has been securely held in escrow.\nIt will be released once you confirm job completion.',
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
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    try {
      final payments = await ApiService().getMyPayments();
      setState(() {
        _payments = payments;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiService.errorMessage(e);
        _loading = false;
      });
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rs. 0';
    final num amount = price is num ? price : num.tryParse(price.toString()) ?? 0;
    final formatter = NumberFormat('#,###', 'en_US');
    return 'Rs. ${formatter.format(amount)}';
  }

  String _mapStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return 'Completed';
      case 'HELD':
      case 'ESCROW':
      case 'PENDING':
        return 'In Escrow';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status ?? 'Unknown';
    }
  }

  Color _statusColor(String displayStatus) {
    switch (displayStatus) {
      case 'Completed':
        return AppColors.success;
      case 'In Escrow':
        return AppColors.warning;
      case 'Refunded':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total from completed payments
    num totalSpent = 0;
    int completedCount = 0;
    for (final p in _payments) {
      final status = _mapStatus(p['status']);
      if (status == 'Completed') {
        final price = p['amount'] ?? p['price'] ?? 0;
        totalSpent += price is num ? price : (num.tryParse(price.toString()) ?? 0);
        completedCount++;
      }
    }

    // Group payments by month/year
    final Map<String, List<dynamic>> grouped = {};
    final dateFormat = DateFormat('MMMM yyyy');
    final dayFormat = DateFormat('MMM d');
    for (final p in _payments) {
      final rawDate = p['createdAt'] ?? p['paidAt'];
      DateTime? dt;
      if (rawDate != null) {
        dt = DateTime.tryParse(rawDate.toString());
      }
      final key = dt != null ? dateFormat.format(dt) : 'Unknown';
      grouped.putIfAbsent(key, () => []).add(p);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTypography.bodyMedium),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() { _loading = true; _error = null; });
                          _fetchPayments();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
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
                          Text(_formatPrice(totalSpent),
                              style: AppTypography.displayLarge
                                  .copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('$completedCount completed transaction${completedCount == 1 ? '' : 's'}',
                              style: AppTypography.labelSmall
                                  .copyWith(color: Colors.white.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_payments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('No payments yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        ),
                      ),

                    ...grouped.entries.expand((entry) {
                      return [
                        Text(entry.key, style: AppTypography.labelMedium),
                        const SizedBox(height: 12),
                        ...entry.value.map((p) {
                          final job = p['job'];
                          final title = job?['title'] ?? 'Untitled Job';
                          final workerProfile = job?['worker'];
                          final workerUser = workerProfile?['user'];
                          final worker = workerUser?['name'] ?? 'Unknown Worker';
                          final amount = _formatPrice(p['amount'] ?? p['price']);
                          final rawDate = p['createdAt'] ?? p['paidAt'];
                          DateTime? dt;
                          if (rawDate != null) {
                            dt = DateTime.tryParse(rawDate.toString());
                          }
                          final date = dt != null ? dayFormat.format(dt) : '';
                          final displayStatus = _mapStatus(p['status']);
                          final color = _statusColor(displayStatus);
                          return _TransactionItem(
                            title: title,
                            worker: worker,
                            amount: amount,
                            date: date,
                            status: displayStatus,
                            statusColor: color,
                          );
                        }),
                        const SizedBox(height: 20),
                      ];
                    }),
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
