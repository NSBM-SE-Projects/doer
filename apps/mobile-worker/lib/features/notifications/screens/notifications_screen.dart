import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_NotifData> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await ApiService().getNotifications();
      final list = data['notifications'] as List;
      setState(() {
        _notifications = list.map((n) => _NotifData.fromJson(n)).toList();
        _unreadCount = data['unreadCount'] ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final n in _notifications) { n.isRead = true; }
      _unreadCount = 0;
    });
    try { await ApiService().markAllNotificationsRead(); } catch (_) {}
  }

  Future<void> _markRead(String id) async {
    setState(() {
      final n = _notifications.firstWhere((n) => n.id == id);
      n.isRead = true;
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    });
    try { await ApiService().markNotificationRead(id); } catch (_) {}
  }

  List<_NotifData> get _todayNotifs =>
      _notifications.where((n) => n.isToday).toList();

  List<_NotifData> get _earlierNotifs =>
      _notifications.where((n) => !n.isToday).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Notifications', style: AppTypography.displaySmall)),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: Text('Mark all read',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? _EmptyNotifications()
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              if (_todayNotifs.isNotEmpty) ...[
                                _SectionLabel(label: 'Today'),
                                ..._todayNotifs.map((n) => _NotifTile(data: n, onTap: () => _markRead(n.id))),
                              ],
                              if (_earlierNotifs.isNotEmpty) ...[
                                _SectionLabel(label: 'Earlier'),
                                ..._earlierNotifs.map((n) => _NotifTile(data: n, onTap: () => _markRead(n.id))),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(label, style: AppTypography.labelMedium.copyWith(
        color: AppColors.textTertiary, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final _NotifData data;
  final VoidCallback onTap;
  const _NotifTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: data.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: data.type.bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(data.type.icon, color: data.type.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(data.title,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: data.isRead ? FontWeight.w600 : FontWeight.w700))),
                    const SizedBox(width: 8),
                    Text(data.timeAgo, style: AppTypography.labelSmall),
                  ]),
                  const SizedBox(height: 4),
                  Text(data.body, style: AppTypography.bodySmall.copyWith(
                    color: data.isRead ? AppColors.textTertiary : AppColors.textSecondary, height: 1.5)),
                ],
              ),
            ),
            if (!data.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.notifications_none_rounded, size: 36, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),
        Text('No notifications yet', style: AppTypography.headlineMedium),
        const SizedBox(height: 6),
        Text('We\'ll notify you about new jobs,\napplication updates, and payments.',
          style: AppTypography.bodySmall, textAlign: TextAlign.center),
      ]),
    );
  }
}

enum _NotifType {
  jobMatch, applicationUpdate, payment, system;

  IconData get icon {
    switch (this) {
      case jobMatch: return Icons.work_outline_rounded;
      case applicationUpdate: return Icons.how_to_reg_outlined;
      case payment: return Icons.payments_outlined;
      case system: return Icons.info_outline_rounded;
    }
  }
  Color get iconColor {
    switch (this) {
      case jobMatch: return AppColors.primary;
      case applicationUpdate: return AppColors.success;
      case payment: return AppColors.info;
      case system: return AppColors.warning;
    }
  }
  Color get bgColor {
    switch (this) {
      case jobMatch: return AppColors.primary.withValues(alpha: 0.1);
      case applicationUpdate: return AppColors.successLight;
      case payment: return AppColors.infoLight;
      case system: return AppColors.warningLight;
    }
  }
}

class _NotifData {
  final String id;
  final _NotifType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  _NotifData({required this.id, required this.type, required this.title,
    required this.body, required this.createdAt, required this.isRead});

  factory _NotifData.fromJson(Map<String, dynamic> json) {
    final title = json['title'] ?? '';
    _NotifType type = _NotifType.system;
    if (title.toString().toLowerCase().contains('job') || title.toString().toLowerCase().contains('assign')) {
      type = _NotifType.jobMatch;
    } else if (title.toString().toLowerCase().contains('payment') || title.toString().toLowerCase().contains('earn')) {
      type = _NotifType.payment;
    } else if (title.toString().toLowerCase().contains('application') || title.toString().toLowerCase().contains('accept')) {
      type = _NotifType.applicationUpdate;
    }
    return _NotifData(
      id: json['id'] ?? '',
      type: type,
      title: title,
      body: json['body'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  bool get isToday => DateTime.now().difference(createdAt).inHours < 24;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
