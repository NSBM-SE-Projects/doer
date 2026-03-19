import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

// ──────────────────────────────────────────────────────────────
// DOER BUTTON
// The main button used everywhere. Two modes:
//   - Filled (gold bg, white text) → primary actions like "Sign In"
//   - Outlined (border only) → secondary actions like "Cancel"
// Also supports loading spinner and optional icon.
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
// SEARCH BAR
// Two modes:
//   - Tap mode (onTap set) → looks like a search bar but navigates
//     to search screen when tapped (used on home screen)
//   - Input mode (controller set) → actual text field for typing
//     (used on search screen)
// ──────────────────────────────────────────────────────────────
class DoerSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const DoerSearchBar({
    super.key,
    this.hint = 'Search for a service...',
    this.onTap,
    this.controller,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: onTap != null
                  ? Text(hint,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textTertiary))
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      autofocus: autofocus,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: hint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
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
// CATEGORY CHIP
// Displays a service category. Two modes:
//   - compact: small icon + name below (used in horizontal scroll)
//   - expanded: icon + name + worker count in a row (used in lists)
// ──────────────────────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback? onTap;
  final bool compact;

  const CategoryChip({
    super.key,
    required this.category,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: category.iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(category.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: category.iconBgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: AppTypography.headlineSmall),
                  if (category.workerCount > 0)
                    Text(
                      '${category.workerCount} workers nearby',
                      style: AppTypography.labelSmall,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// WORKER CARD
// Shows a worker's name, skill, badge, rating, and distance.
// Used on: Home screen, Browse Workers, Search results, Category detail.
// ──────────────────────────────────────────────────────────────
class WorkerCard extends StatelessWidget {
  final String name;
  final String skill;
  final String badge;
  final double rating;
  final double distance;
  final String? imageUrl;
  final VoidCallback? onTap;

  const WorkerCard({
    super.key,
    required this.name,
    required this.skill,
    required this.badge,
    required this.rating,
    required this.distance,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.headlineSmall),
                      Text(skill, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                _BadgePill(badge: badge),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 16, color: AppColors.badgeGold),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
                Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 2),
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: AppTypography.labelMedium,
                ),
                const Spacer(),
                Text(
                  'View profile',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
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

// Badge pill shown inside WorkerCard
class _BadgePill extends StatelessWidget {
  final String badge;
  const _BadgePill({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BadgeLevel.color(badge).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(BadgeLevel.icon(badge),
              size: 12, color: BadgeLevel.color(badge)),
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
// SECTION HEADER
// "Top rated near you" .............. "See all"
// Used on home screen to label each section with an action link.
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
// Small colored badge showing job status like "In Progress", "Completed".
// Color comes from JobStatus.color() in app_constants.dart.
// ──────────────────────────────────────────────────────────────
class JobStatusPill extends StatelessWidget {
  final String status;
  const JobStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: JobStatus.color(status).withOpacity(0.12),
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
// JOB CARD
// Shows a job summary: title, category, status, budget, date.
// Optionally shows assigned worker name.
// Used in: My Jobs list, Home screen recent jobs.
// ──────────────────────────────────────────────────────────────
class JobCard extends StatelessWidget {
  final String title;
  final String category;
  final String categoryIcon;
  final String status;
  final String budget;
  final String date;
  final String? workerName;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.title,
    required this.category,
    required this.categoryIcon,
    required this.status,
    required this.budget,
    required this.date,
    this.workerName,
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
                Text(categoryIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: AppTypography.headlineSmall),
                ),
                JobStatusPill(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(icon: Icons.category_outlined, text: category),
                const SizedBox(width: 10),
                _InfoChip(
                    icon: Icons.account_balance_wallet_outlined, text: budget),
                const SizedBox(width: 10),
                _InfoChip(icon: Icons.schedule_outlined, text: date),
              ],
            ),
            if (workerName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Text(
                      workerName![0].toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(workerName!, style: AppTypography.labelMedium),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Small icon + text used inside JobCard
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
// Shows 1-5 stars. Two modes:
//   - Display: just shows the rating (e.g. 4.5 stars)
//   - Interactive: user can tap to rate (used in review screen)
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
// Shown when a list has no items. E.g. "No cancelled jobs" with
// an emoji, title, subtitle, and optional action button.
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
// A single chat in the conversations list. Shows:
// worker avatar, name, last message, time, job title tag, unread dot.
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
        color: unread ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
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
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
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
