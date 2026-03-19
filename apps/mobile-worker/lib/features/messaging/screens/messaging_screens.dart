import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// MESSAGING SCREENS
// ConversationsScreen: list of all chats with clients.
// ChatScreen: individual conversation view.
// ──────────────────────────────────────────────────────────────

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  static const _conversations = [
    _ConvData('Nimal Jayawardena', 'Ok, see you at 2 PM then.', '2:30 PM',
        'Fix kitchen plumbing', true),
    _ConvData('Priya Fernando', 'Can you bring your own tools?', '11:15 AM',
        'Install ceiling fan', false),
    _ConvData('Suresh Perera', 'Thanks for the great work!', 'Yesterday',
        'Bathroom repair', false),
  ];

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
            _conversations.isEmpty
                ? const Expanded(
                    child: EmptyState(
                      icon: '💬',
                      title: 'No messages yet',
                      subtitle: 'Conversations with clients will appear here.',
                    ),
                  )
                : Expanded(
                    child: ListView.separated(
                      itemCount: _conversations.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        return ConversationTile(
                          name: conv.name,
                          lastMessage: conv.lastMessage,
                          time: conv.time,
                          jobTitle: conv.jobTitle,
                          unread: conv.unread,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  clientName: conv.name,
                                  jobTitle: conv.jobTitle,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ConvData {
  final String name;
  final String lastMessage;
  final String time;
  final String jobTitle;
  final bool unread;

  const _ConvData(
      this.name, this.lastMessage, this.time, this.jobTitle, this.unread);
}

// ──────────────────────────────────────────────────────────────
// CHAT SCREEN
// Individual message thread with a client.
// ──────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String clientName;
  final String jobTitle;

  const ChatScreen({
    super.key,
    required this.clientName,
    required this.jobTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_Message> _messages = [
    _Message('Hi, are you available this afternoon?', false, '1:45 PM'),
    _Message('Yes, I can be there by 2 PM.', true, '1:47 PM'),
    _Message('Great! The kitchen tap is leaking quite badly.', false,
        '1:48 PM'),
    _Message(
        'No problem, I\'ll bring the necessary tools. See you then.', true, '1:50 PM'),
    _Message('Ok, see you at 2 PM then.', false, '2:30 PM'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text, true, 'Now'));
      _messageController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(
                widget.clientName[0].toUpperCase(),
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.clientName, style: AppTypography.headlineSmall),
                Text(
                  widget.jobTitle,
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _MessageBubble(message: msg);
              },
            ),
          ),

          // Input bar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(color: AppColors.borderLight)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTypography.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
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
      alignment:
          message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
          border: message.isMe
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: AppTypography.bodyMedium.copyWith(
                color: message.isMe
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: AppTypography.labelSmall.copyWith(
                color: message.isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
