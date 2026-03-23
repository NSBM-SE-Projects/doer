import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
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
  final String jobId;
  final String workerName;
  final String jobTitle;
  const RateReviewScreen({
    super.key,
    required this.jobId,
    required this.workerName,
    required this.jobTitle,
  });

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _rating = 0;
  bool _submitting = false;
  final _reviewController = TextEditingController();
  final List<File> _photos = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _submitting = true);
    try {
      // Upload photos if any
      List<String>? photoUrls;
      if (_photos.isNotEmpty) {
        try {
          final base64Images = <String>[];
          for (final photo in _photos) {
            final bytes = await photo.readAsBytes();
            base64Images.add('data:image/jpeg;base64,${base64Encode(bytes)}');
          }
          photoUrls = await ApiService().uploadImages(base64Images, folder: 'doer/reviews');
        } catch (_) {
          // Continue without photos if upload fails
        }
      }

      await ApiService().reviewJob(
        widget.jobId,
        rating: _rating,
        comment: _reviewController.text.trim().isNotEmpty
            ? _reviewController.text.trim()
            : null,
        photoUrls: photoUrls,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
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
              child: Text(
                  widget.workerName.isNotEmpty ? widget.workerName[0].toUpperCase() : '?',
                  style: AppTypography.displaySmall
                      .copyWith(color: AppColors.primary)),
            ),
            const SizedBox(height: 14),
            Text(widget.workerName, style: AppTypography.headlineLarge),
            const SizedBox(height: 4),
            Text(widget.jobTitle, style: AppTypography.bodySmall),

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
            if (_photos.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_photos[i], width: 80, height: 80, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            GestureDetector(
              onTap: () async {
                final source = await showModalBottomSheet<ImageSource>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt_rounded),
                          title: const Text('Camera'),
                          onTap: () => Navigator.pop(ctx, ImageSource.camera),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library_rounded),
                          title: const Text('Gallery'),
                          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),
                );
                if (source != null) {
                  final picked = await _picker.pickImage(source: source, imageQuality: 80);
                  if (picked != null) {
                    setState(() => _photos.add(File(picked.path)));
                  }
                }
              },
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
                    Text(_photos.isEmpty ? 'Upload work photos' : 'Add more photos',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit button (disabled until rated)
            DoerButton(
              label: _submitting ? 'Submitting...' : 'Submit Review',
              onPressed: _rating > 0 && !_submitting ? _submitReview : null,
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
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await ApiService().getNotifications();
      setState(() {
        _notifications = (data['notifications'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiService.errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService().markAllNotificationsRead();
      setState(() {
        for (var i = 0; i < _notifications.length; i++) {
          if (_notifications[i] is Map) {
            _notifications[i] = {..._notifications[i] as Map, 'isRead': true};
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.errorMessage(e))),
      );
    }
  }

  Future<void> _markRead(String id, int index) async {
    try {
      await ApiService().markNotificationRead(id);
      setState(() {
        if (_notifications[index] is Map) {
          _notifications[index] = {..._notifications[index] as Map, 'isRead': true};
        }
      });
    } catch (_) {}
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    return timeago.format(dt);
  }

  IconData _iconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('complet')) return Icons.check_circle_outline_rounded;
    if (lower.contains('message')) return Icons.chat_bubble_outline_rounded;
    if (lower.contains('match') || lower.contains('worker')) return Icons.person_add_outlined;
    if (lower.contains('payment') || lower.contains('escrow')) return Icons.payment_outlined;
    if (lower.contains('rate') || lower.contains('review')) return Icons.star_outline_rounded;
    return Icons.notifications_outlined;
  }

  Color _iconColorForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('complet')) return AppColors.success;
    if (lower.contains('message')) return AppColors.primary;
    if (lower.contains('match') || lower.contains('worker')) return AppColors.info;
    if (lower.contains('payment') || lower.contains('escrow')) return AppColors.warning;
    if (lower.contains('rate') || lower.contains('review')) return AppColors.badgeGold;
    return AppColors.textSecondary;
  }

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
            onPressed: _markAllRead,
            child: Text('Mark all read',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary)),
          ),
        ],
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
                          _fetchNotifications();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Text('No notifications yet',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final title = n['title'] ?? 'Notification';
                        final body = n['body'] ?? '';
                        final isRead = n['isRead'] == true;
                        final createdAt = n['createdAt']?.toString();
                        final id = n['id']?.toString() ?? '';
                        return GestureDetector(
                          onTap: () {
                            if (!isRead && id.isNotEmpty) {
                              _markRead(id, index);
                            }
                          },
                          child: _NotifItem(
                            icon: _iconForTitle(title),
                            iconColor: _iconColorForTitle(title),
                            title: title,
                            subtitle: body,
                            time: _timeAgo(createdAt),
                            unread: !isRead,
                          ),
                        );
                      },
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
