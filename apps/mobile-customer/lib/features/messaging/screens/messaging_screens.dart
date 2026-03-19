import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../video/video_call_screen.dart';

// ──────────────────────────────────────────────────────────────
// CONVERSATIONS LIST
// Shows all active chat threads. Each conversation is tied to
// a specific job (job-scoped messaging from the Doer spec).
// Shows: worker avatar, name, last message, time, job title tag.
// Unread conversations have a subtle gold tint + dot indicator.
// ──────────────────────────────────────────────────────────────
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      _conversations = await ApiService().getConversations();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _timeAgo(String? d) {
    if (d == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(d));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _conversations.isEmpty
          ? const EmptyState(icon: '💬', title: 'No messages', subtitle: 'Start a conversation from a job')
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.separated(
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => const Divider(indent: 76, height: 0),
                itemBuilder: (_, i) {
                  final c = _conversations[i];
                  final other = c['otherUser'];
                  final last = c['lastMessage'];
                  return ConversationTile(
                    name: other?['name'] ?? 'Worker',
                    lastMessage: last?['content'] ?? '',
                    time: _timeAgo(last?['createdAt']),
                    jobTitle: c['jobTitle'] ?? '',
                    unread: false,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatScreen(jobId: c['jobId'], workerName: other?['name'] ?? 'Worker'),
                    )),
                  );
                },
              ),
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CHAT SCREEN
// Real-time messaging UI between customer and worker.
// From the spec: messages are persisted to DB, delivered via
// Socket.io (real-time) with FCM push notification fallback.
// Layout:
//   - Job info banner at top (which job this chat is about)
//   - Message bubbles (gold = customer, white = worker)
//   - Input bar at bottom with attachment + send button
// ──────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String? jobId;
  final String? workerName;
  const ChatScreen({super.key, this.jobId, this.workerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = true;
  String? _myUserId;

  List<_ChatMessage> _messages = [];

  String? _myBackendId;

  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      _fetchMessages();
      _listenForRealTimeMessages();
    }
  }

  void _listenForRealTimeMessages() {
    SocketService().joinJob(widget.jobId!);
    SocketService().onNewMessage = (data) {
      if (!mounted) return;
      final senderId = data['sender']?['id'] ?? data['senderId'];
      if (senderId == _myBackendId) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: data['content'] ?? '',
          isMe: false,
          time: _formatTime(data['createdAt']),
        ));
      });
    };
  }

  Future<void> _fetchMessages() async {
    try {
      final meData = await ApiService().getMe();
      _myUserId = meData['user']?['id'];
      _myBackendId = _myUserId;
      final list = await ApiService().getMessages(widget.jobId!);
      setState(() {
        _messages = list.map((m) => _ChatMessage(
          text: m['content'] ?? '',
          isMe: m['sender']?['id'] == _myUserId,
          time: _formatTime(m['createdAt']),
        )).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  Future<void> _sendMessageToApi() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.jobId == null) return;
    _messageController.clear();
    setState(() => _messages.add(_ChatMessage(text: text, isMe: true, time: 'Now')));
    try { await ApiService().sendMessage(widget.jobId!, text); } catch (_) {}
  }

  @override
  void dispose() {
    if (widget.jobId != null) {
      SocketService().leaveJob(widget.jobId!);
      SocketService().onNewMessage = null;
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(
                  (widget.workerName ?? 'W').isNotEmpty ? (widget.workerName ?? 'W')[0].toUpperCase() : 'W',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.workerName ?? 'Worker',
                      style:
                          AppTypography.headlineSmall.copyWith(fontSize: 15)),
                  Text(widget.jobId ?? '',
                      style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.videocam_outlined, size: 22),
              onPressed: () {
                if (widget.jobId != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => VideoCallScreen(
                      channelName: widget.jobId!,
                      remoteName: widget.workerName ?? 'Worker',
                    ),
                  ));
                }
              }),
          IconButton(
              icon: const Icon(Icons.info_outline_rounded, size: 22),
              onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Job info banner
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.work_outline_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Fix kitchen sink leak · In Progress',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.primary)),
                ),
                Text('Rs. 4,500',
                    style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Attachment button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: AppTypography.bodyMedium,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          isDense: true,
                          filled: false,
                          hintStyle: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        setState(() {
                          _messages.add(_ChatMessage(
                            text: _messageController.text.trim(),
                            isMe: true,
                            time: 'Now',
                          ));
                          _messageController.clear();
                        });
                      }
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.send_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data class for a single message
class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final bool isImage;

  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.isImage = false,
  });
}

// Single message bubble widget
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      // Customer messages right, worker messages left
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: message.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: message.isImage
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // Gold for customer, white for worker
                color: message.isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 16),
                ),
                border:
                    message.isMe ? null : Border.all(color: AppColors.border),
              ),
              child: message.isImage
                  ? Container(
                      width: 180,
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Icon(Icons.image_outlined,
                              size: 36, color: AppColors.textTertiary)),
                    )
                  : Text(
                      message.text,
                      style: AppTypography.bodyMedium.copyWith(
                        color: message.isMe
                            ? Colors.white
                            : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
            ),
            const SizedBox(height: 3),
            Text(message.time,
                style: AppTypography.labelSmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
