import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/socket_service.dart';
import '../../video/video_call_screen.dart';

// ── Conversations List ──
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text('Messages', style: AppTypography.displaySmall),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                  ? const EmptyState(icon: '💬', title: 'No messages yet',
                      subtitle: 'Conversations with clients will appear here.')
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final other = conv['otherUser'];
                          final last = conv['lastMessage'];
                          return ConversationTile(
                            name: other?['name'] ?? 'User',
                            lastMessage: last?['content'] ?? '',
                            time: _timeAgo(last?['createdAt']),
                            jobTitle: conv['jobTitle'] ?? '',
                            unread: false,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  jobId: conv['jobId'],
                                  clientName: other?['name'] ?? 'User',
                                  jobTitle: conv['jobTitle'] ?? '',
                                  otherUserId: other?['id'],
                                ),
                              ));
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}

// ── Chat Screen ──
class ChatScreen extends StatefulWidget {
  final String jobId;
  final String clientName;
  final String jobTitle;

  final String? otherUserId;
  const ChatScreen({super.key, required this.jobId, required this.clientName, required this.jobTitle, this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<_Message> _messages = [];
  bool _isLoading = true;
  String? _myUserId;

  String? _myBackendId;

  @override
  void initState() {
    super.initState();
    _myUserId = AuthService().currentUser?.email;
    _fetchMessages();
    _listenForRealTimeMessages();
  }

  void _listenForRealTimeMessages() {
    SocketService().joinJob(widget.jobId);
    SocketService().onNewMessage = (data) {
      if (!mounted) return;
      final senderId = data['sender']?['id'] ?? data['senderId'];
      if (senderId == _myBackendId) return; // Don't duplicate own messages
      setState(() {
        _messages.add(_Message(
          data['content'] ?? '',
          false,
          _formatTime(data['createdAt']),
        ));
      });
      _scrollToBottom();
    };
  }

  Future<void> _fetchMessages() async {
    try {
      final list = await ApiService().getMessages(widget.jobId);
      // We need to get our backend user ID to determine isMe
      final meData = await ApiService().getMe();
      final myId = meData['user']?['id'];
      _myBackendId = myId;
      setState(() {
        _messages = list.map((m) {
          final senderId = m['sender']?['id'] ?? m['senderId'];
          return _Message(
            m['content'] ?? '',
            senderId == myId,
            _formatTime(m['createdAt']),
          );
        }).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    setState(() { _messages.add(_Message(text, true, 'Now')); });
    _scrollToBottom();
    try {
      await ApiService().sendMessage(widget.jobId, text);
    } catch (_) {}
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  void dispose() {
    SocketService().leaveJob(widget.jobId);
    SocketService().onNewMessage = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.surfaceVariant,
            child: Text(widget.clientName[0].toUpperCase(),
              style: AppTypography.headlineSmall.copyWith(color: AppColors.primary))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.clientName, style: AppTypography.headlineSmall),
            Text(widget.jobTitle, style: AppTypography.labelSmall),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => VideoCallScreen(
                  channelName: widget.jobId,
                  remoteName: widget.clientName,
                  targetUserId: widget.otherUserId,
                ),
              ));
            },
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
              ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SafeArea(top: false, child: Row(children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Type a message...', border: InputBorder.none,
                  enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  filled: false, contentPadding: EdgeInsets.symmetric(horizontal: 4)),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
            ),
          ])),
        ),
      ]),
    );
  }
}

class _Message {
  final String text;
  final bool isMe;
  final String time;
  const _Message(this.text, this.isMe, this.time);
}

class _MessageBubble extends StatelessWidget {
  final _Message message;
  const _MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16)),
          border: message.isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(message.text, style: AppTypography.bodyMedium.copyWith(
            color: message.isMe ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(message.time, style: AppTypography.labelSmall.copyWith(
            color: message.isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textTertiary,
            fontSize: 9)),
        ]),
      ),
    );
  }
}
