import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────
// SPACING & SIZING
// ──────────────────────────────────────────────────────────────
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
}

class AppSizing {
  static const double buttonHeight = 56;
  static const double inputHeight = 52;
  static const double bottomNavHeight = 64;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
}

// ──────────────────────────────────────────────────────────────
// SERVICE CATEGORIES
// The 8 home service types Doer supports.
// ──────────────────────────────────────────────────────────────
class ServiceCategory {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final Color iconBgColor;
  final int workerCount;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.iconBgColor,
    this.workerCount = 0,
  });
}

class AppCategories {
  static const List<ServiceCategory> all = [
    ServiceCategory(
      id: 'plumbing',
      name: 'Plumbing',
      icon: '🔧',
      color: Color(0xFFFF9800),
      iconBgColor: AppColors.categoryPlumbing,
    ),
    ServiceCategory(
      id: 'electrical',
      name: 'Electrical',
      icon: '⚡',
      color: Color(0xFF4CAF50),
      iconBgColor: AppColors.categoryElectrical,
    ),
    ServiceCategory(
      id: 'cleaning',
      name: 'Cleaning',
      icon: '🧹',
      color: Color(0xFF2196F3),
      iconBgColor: AppColors.categoryCleaning,
    ),
    ServiceCategory(
      id: 'painting',
      name: 'Painting',
      icon: '🎨',
      color: Color(0xFFE53935),
      iconBgColor: AppColors.categoryPainting,
    ),
    ServiceCategory(
      id: 'gardening',
      name: 'Gardening',
      icon: '🌿',
      color: Color(0xFF66BB6A),
      iconBgColor: AppColors.categoryGardening,
    ),
    ServiceCategory(
      id: 'moving',
      name: 'Moving',
      icon: '📦',
      color: Color(0xFF9C27B0),
      iconBgColor: AppColors.categoryMoving,
    ),
    ServiceCategory(
      id: 'carpentry',
      name: 'Carpentry',
      icon: '🪚',
      color: Color(0xFF795548),
      iconBgColor: AppColors.categoryCarpentry,
    ),
    ServiceCategory(
      id: 'appliance',
      name: 'Appliance',
      icon: '🔌',
      color: Color(0xFF00BCD4),
      iconBgColor: AppColors.categoryAppliance,
    ),
  ];
}

// ──────────────────────────────────────────────────────────────
// JOB STATUSES
// posted → applications_received → worker_accepted → in_progress
// → completed → reviewed → closed  |  posted → cancelled
// ──────────────────────────────────────────────────────────────
class JobStatus {
  static const String posted = 'posted';
  static const String applicationsReceived = 'applications_received';
  static const String workerAccepted = 'worker_accepted';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String reviewed = 'reviewed';
  static const String closed = 'closed';
  static const String cancelled = 'cancelled';

  static String label(String status) {
    switch (status) {
      case posted:
        return 'Posted';
      case applicationsReceived:
        return 'Applications Received';
      case workerAccepted:
        return 'Accepted';
      case inProgress:
        return 'In Progress';
      case completed:
        return 'Completed';
      case reviewed:
        return 'Reviewed';
      case closed:
        return 'Closed';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case posted:
        return AppColors.info;
      case applicationsReceived:
        return AppColors.primary;
      case workerAccepted:
        return AppColors.primaryDark;
      case inProgress:
        return AppColors.warning;
      case completed:
        return AppColors.success;
      case reviewed:
        return AppColors.success;
      case closed:
        return AppColors.textTertiary;
      case cancelled:
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }
}

// ──────────────────────────────────────────────────────────────
// WORKER BADGE LEVELS
// trainee → bronze → silver → gold → platinum
// Matching algorithm weights: Bronze=0.25, Silver=0.50, Gold=0.75, Platinum=1.0
// ──────────────────────────────────────────────────────────────
class BadgeLevel {
  static const String trainee = 'trainee';
  static const String bronze = 'bronze';
  static const String silver = 'silver';
  static const String gold = 'gold';
  static const String platinum = 'platinum';

  static String label(String level) {
    switch (level) {
      case trainee:
        return 'Trainee';
      case bronze:
        return 'Bronze';
      case silver:
        return 'Silver';
      case gold:
        return 'Gold';
      case platinum:
        return 'Platinum';
      default:
        return level;
    }
  }

  static Color color(String level) {
    switch (level) {
      case trainee:
        return AppColors.textTertiary;
      case bronze:
        return AppColors.badgeBronze;
      case silver:
        return AppColors.badgeSilver;
      case gold:
        return AppColors.badgeGold;
      case platinum:
        return AppColors.badgePlatinum;
      default:
        return AppColors.textTertiary;
    }
  }

  static IconData icon(String level) {
    switch (level) {
      case trainee:
        return Icons.school_outlined;
      case bronze:
        return Icons.workspace_premium_outlined;
      case silver:
        return Icons.workspace_premium;
      case gold:
        return Icons.workspace_premium;
      case platinum:
        return Icons.diamond_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

// ──────────────────────────────────────────────────────────────
// WORKER VERIFICATION STATUS
// Workers must complete verification to unlock higher badge levels.
// ──────────────────────────────────────────────────────────────
class VerificationStatus {
  static const String pending = 'pending';
  static const String submitted = 'submitted';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Not Submitted';
      case submitted:
        return 'Under Review';
      case approved:
        return 'Verified';
      case rejected:
        return 'Rejected';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case pending:
        return AppColors.textTertiary;
      case submitted:
        return AppColors.warning;
      case approved:
        return AppColors.success;
      case rejected:
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }
}
