import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// RATE & REVIEW SCREEN
// After a job is completed, customer rates the worker.
//   - Interactive star rating (tap to select 1-5)
//   - Text review
//   - Optional photo upload
// Rating label changes: "Tap to rate" → "Could be better" → "Excellent!"
// ──────────────────────────────────────────────────────────────
class RateReviewScreen extends StatefulWidget {
  const RateReviewScreen({super.key});

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Rate & Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Worker info
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.surfaceVariant,
              child: Text('S',
                  style: AppTypography.displaySmall
                      .copyWith(color: AppColors.primary)),
            ),
            const SizedBox(height: 14),
            Text('Saman Fernando', style: AppTypography.headlineLarge),
            const SizedBox(height: 4),
            Text('Fix kitchen sink leak', style: AppTypography.bodySmall),

            const SizedBox(height: 32),

            // Star rating
            Text('How was the service?',
                style: AppTypography.headlineMedium),
            const SizedBox(height: 14),
            RatingStars(
              rating: _rating.toDouble(),
              size: 40,
              interactive: true,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 6),
            Text(
              _rating == 0
                  ? 'Tap to rate'
                  : _rating <= 2
                      ? 'Could be better'
                      : _rating <= 3
                          ? 'Average'
                          : _rating == 4
                              ? 'Good job!'
                              : 'Excellent!',
              style: AppTypography.bodySmall.copyWith(
                color:
                    _rating > 0 ? AppColors.primary : AppColors.textTertiary,
              ),
            ),

            const SizedBox(height: 32),

            // Text review
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Write a review',
                  style: AppTypography.headlineMedium),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                hintText:
                    'Tell others about your experience. Was the work quality good? Was the worker professional?',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // Photo upload
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Add photos (optional)',
                  style: AppTypography.headlineMedium),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.textTertiary, size: 28),
                    const SizedBox(height: 6),
                    Text('Upload work photos',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit button (disabled until rated)
            DoerButton(
              label: 'Submit Review',
              onPressed: _rating > 0 ? () => Navigator.pop(context) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// NOTIFICATIONS SCREEN
// Shows all platform notifications grouped by type:
//   - Job completed (green)
//   - New message (gold)
//   - Worker matched (blue)
//   - Payment held (orange)
//   - Rate experience (gold star)
// Unread items have subtle tint + dot indicator.
// ──────────────────────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        children: [
          _NotifItem(
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              title: 'Job Completed',
              subtitle:
                  'Saman marked "Fix kitchen sink leak" as completed.',
              time: '5 min ago',
              unread: true),
          _NotifItem(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.primary,
              title: 'New Message',
              subtitle: 'Saman Fernando sent you a message.',
              time: '15 min ago',
              unread: true),
          _NotifItem(
              icon: Icons.person_add_outlined,
              iconColor: AppColors.info,
              title: 'Worker Matched',
              subtitle:
                  '3 workers matched for "Paint bedroom walls".',
              time: '2 hours ago'),
          _NotifItem(
              icon: Icons.payment_outlined,
              iconColor: AppColors.warning,
              title: 'Payment Held',
              subtitle: 'Rs. 4,500 held in escrow for sink repair.',
              time: 'Yesterday'),
          _NotifItem(
              icon: Icons.star_outline_rounded,
              iconColor: AppColors.badgeGold,
              title: 'Rate Your Experience',
              subtitle: 'How was Nimal Perera\'s wiring service?',
              time: '2 days ago'),
        ],
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool unread;

  const _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: unread ? AppColors.primary.withValues(alpha: 0.03) : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: AppTypography.headlineSmall.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600)),
                    ),
                    Text(time, style: AppTypography.labelSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTypography.bodySmall.copyWith(
                        color: unread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
