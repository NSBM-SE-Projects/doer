import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────────────────────
// NOTIFICATIONS SCREEN
// Shows all worker notifications grouped by Today / Earlier.
// Types: job_match, application_update, payment, system.
// ──────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotifData> _notifications = [
    _NotifData(
      id: '1',
      type: _NotifType.jobMatch,
      title: 'New job near you!',
      body: '"Fix bathroom tiles" in Nugegoda — Rs. 3,200',
      time: '5 min ago',
      isRead: false,
    ),
    _NotifData(
      id: '2',
      type: _NotifType.applicationUpdate,
      title: 'Application viewed',
      body: 'Priya Fernando viewed your application for "Install ceiling fan"',
      time: '32 min ago',
      isRead: false,
    ),
    _NotifData(
      id: '3',
      type: _NotifType.payment,
      title: 'Payment received',
      body: 'Rs. 3,500 has been added to your earnings balance',
      time: '2 hr ago',
      isRead: false,
    ),
    _NotifData(
      id: '4',
      type: _NotifType.jobMatch,
      title: 'New job near you!',
      body: '"Garden maintenance" in Boralesgamuwa — Rs. 1,800',
      time: 'Yesterday',
      isRead: true,
    ),
    _NotifData(
      id: '5',
      type: _NotifType.applicationUpdate,
      title: 'You got the job!',
      body: 'Nimal Jayawardena accepted your application for "Kitchen plumbing repair"',
      time: 'Yesterday',
      isRead: true,
    ),
    _NotifData(
      id: '6',
      type: _NotifType.system,
      title: 'Verification reminder',
      body: 'Upload your NIC to unlock your Bronze badge and get more job matches',
      time: '2 days ago',
      isRead: true,
    ),
    _NotifData(
      id: '7',
      type: _NotifType.payment,
      title: 'Subscription renewed',
      body: 'Your monthly subscription of Rs. 990 has been successfully renewed',
      time: '3 days ago',
      isRead: true,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      final n = _notifications.firstWhere((n) => n.id == id);
      n.isRead = true;
    });
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<_NotifData> get _todayNotifs =>
      _notifications.where((n) => !n.time.contains('day') && !n.time.contains('Yesterday')).toList();

  List<_NotifData> get _earlierNotifs =>
      _notifications.where((n) => n.time.contains('day') || n.time.contains('Yesterday')).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Notifications',
                        style: AppTypography.displaySmall),
                  ),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: Text(
                        'Mark all read',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _notifications.isEmpty
                  ? _EmptyNotifications()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (_todayNotifs.isNotEmpty) ...[
                          _SectionLabel(label: 'Today'),
                          ..._todayNotifs.map((n) => _NotifTile(
                                data: n,
                                onTap: () => _markRead(n.id),
                              )),
                        ],
                        if (_earlierNotifs.isNotEmpty) ...[
                          _SectionLabel(label: 'Earlier'),
                          ..._earlierNotifs.map((n) => _NotifTile(
                                data: n,
                                onTap: () => _markRead(n.id),
                              )),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ──
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Single notification tile ──
class _NotifTile extends StatelessWidget {
  final _NotifData data;
  final VoidCallback onTap;
  const _NotifTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: data.isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: data.type.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(data.type.icon, color: data.type.iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: data.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(data.time, style: AppTypography.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.body,
                    style: AppTypography.bodySmall.copyWith(
                      color: data.isRead
                          ? AppColors.textTertiary
                          : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!data.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──
class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 36, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          Text('No notifications yet', style: AppTypography.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'We\'ll notify you about new jobs,\napplication updates, and payments.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Data model ──
enum _NotifType {
  jobMatch,
  applicationUpdate,
  payment,
  system;

  IconData get icon {
    switch (this) {
      case jobMatch:
        return Icons.work_outline_rounded;
      case applicationUpdate:
        return Icons.how_to_reg_outlined;
      case payment:
        return Icons.payments_outlined;
      case system:
        return Icons.info_outline_rounded;
    }
  }

  Color get iconColor {
    switch (this) {
      case jobMatch:
        return AppColors.primary;
      case applicationUpdate:
        return AppColors.success;
      case payment:
        return AppColors.info;
      case system:
        return AppColors.warning;
    }
  }

  Color get bgColor {
    switch (this) {
      case jobMatch:
        return AppColors.primary.withValues(alpha: 0.1);
      case applicationUpdate:
        return AppColors.successLight;
      case payment:
        return AppColors.infoLight;
      case system:
        return AppColors.warningLight;
    }
  }
}

class _NotifData {
  final String id;
  final _NotifType type;
  final String title;
  final String body;
  final String time;
  bool isRead;

  _NotifData({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}
