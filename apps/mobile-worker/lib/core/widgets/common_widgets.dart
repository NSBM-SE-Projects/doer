import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

// ──────────────────────────────────────────────────────────────
// DOER BUTTON
// Primary button used throughout the worker app.
// Filled (gold) or outlined. Supports loading state and icon.
// ──────────────────────────────────────────────────────────────
class DoerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;

  const DoerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textOnPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final button = isOutlined
        ? OutlinedButton(onPressed: isLoading ? null : onPressed, child: child)
        : ElevatedButton(onPressed: isLoading ? null : onPressed, child: child);

    return SizedBox(
      width: width ?? double.infinity,
      height: AppSizing.buttonHeight,
      child: button,
    );
  }
}

// ──────────────────────────────────────────────────────────────
// SECTION HEADER
// "Nearby Jobs" .............. "See all"
// ──────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.headlineLarge),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// JOB STATUS PILL
// Small colored badge showing job status.
// ──────────────────────────────────────────────────────────────
class JobStatusPill extends StatelessWidget {
  final String status;
  const JobStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: JobStatus.color(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        JobStatus.label(status),
        style: AppTypography.labelSmall.copyWith(
          color: JobStatus.color(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// BADGE PILL
// Shows worker trust badge (Trainee / Bronze / Silver / Gold / Platinum).
// ──────────────────────────────────────────────────────────────
class BadgePill extends StatelessWidget {
  final String badge;
  const BadgePill({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BadgeLevel.color(badge).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(BadgeLevel.icon(badge), size: 12, color: BadgeLevel.color(badge)),
          const SizedBox(width: 4),
          Text(
            BadgeLevel.label(badge),
            style: AppTypography.labelSmall.copyWith(
              color: BadgeLevel.color(badge),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// JOB LISTING CARD
// Shows a job a worker can browse/apply to.
// Displays: title, category, budget, location, distance, status.
// ──────────────────────────────────────────────────────────────
class JobListingCard extends StatelessWidget {
  final String title;
  final String category;
  final String categoryIcon;
  final String budget;
  final String location;
  final double distance;
  final String postedAt;
  final VoidCallback? onTap;

  const JobListingCard({
    super.key,
    required this.title,
    required this.category,
    required this.categoryIcon,
    required this.budget,
    required this.location,
    required this.distance,
    required this.postedAt,
    this.onTap,
  });

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
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(categoryIcon,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.headlineSmall),
                      const SizedBox(height: 2),
                      Text(category, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      budget,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(postedAt, style: AppTypography.labelSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: AppTypography.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// ACTIVE JOB CARD
// Shows a job the worker has accepted / is working on.
// ──────────────────────────────────────────────────────────────
class ActiveJobCard extends StatelessWidget {
  final String title;
  final String categoryIcon;
  final String status;
  final String clientName;
  final String scheduledDate;
  final String budget;
  final VoidCallback? onTap;

  const ActiveJobCard({
    super.key,
    required this.title,
    required this.categoryIcon,
    required this.status,
    required this.clientName,
    required this.scheduledDate,
    required this.budget,
    this.onTap,
  });

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
            Row(
              children: [
                Text(categoryIcon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: AppTypography.headlineSmall),
                ),
                JobStatusPill(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(icon: Icons.person_outline_rounded, text: clientName),
                const SizedBox(width: 10),
                _InfoChip(
                    icon: Icons.calendar_today_outlined, text: scheduledDate),
                const Spacer(),
                Text(
                  budget,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(text, style: AppTypography.labelSmall),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// RATING STARS
// ──────────────────────────────────────────────────────────────
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.interactive = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating.floor();
        final half = index == rating.floor() && rating % 1 >= 0.5;
        return GestureDetector(
          onTap: interactive ? () => onChanged?.call(index + 1) : null,
          child: Icon(
            filled
                ? Icons.star_rounded
                : half
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: AppColors.badgeGold,
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EMPTY STATE
// Shown when a list has no items.
// ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title,
                style: AppTypography.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTypography.bodySmall, textAlign: TextAlign.center),
            if (buttonText != null) ...[
              const SizedBox(height: 24),
              DoerButton(
                label: buttonText!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CONVERSATION TILE
// A single chat in the conversations list.
// ──────────────────────────────────────────────────────────────
class ConversationTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String jobTitle;
  final bool unread;
  final VoidCallback? onTap;

  const ConversationTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.jobTitle,
    this.unread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: unread
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(time, style: AppTypography.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: unread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      jobTitle,
                      style: AppTypography.labelSmall.copyWith(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// VERIFICATION STATUS CARD
// Shows NIC / qualification / background check status.
// ──────────────────────────────────────────────────────────────
class VerificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final VoidCallback? onTap;

  const VerificationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = VerificationStatus.color(status);
    final isApproved = status == VerificationStatus.approved;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isApproved ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.headlineSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                VerificationStatus.label(status),
                style: AppTypography.labelSmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EARNINGS SUMMARY CARD
// Shows total earnings, pending, and this month.
// ──────────────────────────────────────────────────────────────
class EarningsSummaryCard extends StatelessWidget {
  final String totalEarnings;
  final String pendingPayout;
  final String thisMonth;

  const EarningsSummaryCard({
    super.key,
    required this.totalEarnings,
    required this.pendingPayout,
    required this.thisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalEarnings,
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _EarningsMetric(
                  label: 'Pending',
                  value: pendingPayout,
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.3)),
              Expanded(
                child: _EarningsMetric(
                  label: 'This Month',
                  value: thisMonth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsMetric extends StatelessWidget {
  final String label;
  final String value;
  const _EarningsMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
