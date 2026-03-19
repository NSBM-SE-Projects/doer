import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

// ──────────────────────────────────────────────────────────────
// CONVERSATIONS LIST
// Shows all active chat threads. Each conversation is tied to
// a specific job (job-scoped messaging from the Doer spec).
// Shows: worker avatar, name, last message, time, job title tag.
// Unread conversations have a subtle gold tint + dot indicator.
// ──────────────────────────────────────────────────────────────
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: ListView(
        children: [
          ConversationTile(
            name: 'Saman Fernando',
            lastMessage: 'I\'m on my way, should be there in 15 minutes',
            time: '2m ago',
            jobTitle: 'Fix kitchen sink leak',
            unread: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
          const Divider(indent: 76, height: 0),
          ConversationTile(
            name: 'Nimal Perera',
            lastMessage: 'The wiring is done. Please check and confirm.',
            time: '1h ago',
            jobTitle: 'Rewire living room',
            onTap: () {},
          ),
          const Divider(indent: 76, height: 0),
          ConversationTile(
            name: 'Kumari Silva',
            lastMessage: 'Thank you for the review!',
            time: 'Yesterday',
            jobTitle: 'Deep clean apartment',
            onTap: () {},
          ),
        ],
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
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Mock conversation data
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Hi, I saw your job posting for the kitchen sink repair.',
      isMe: false,
      time: '10:30 AM',
    ),
    _ChatMessage(
      text: 'Yes! The sink has been leaking for about a week now.',
      isMe: true,
      time: '10:31 AM',
    ),
    _ChatMessage(
      text: 'Can you send me a photo of the leak area? I want to check what tools I need to bring.',
      isMe: false,
      time: '10:32 AM',
    ),
    _ChatMessage(
      text: 'Sure, here\'s a photo of under the sink',
      isMe: true,
      time: '10:33 AM',
      isImage: true,
    ),
    _ChatMessage(
      text: 'I see, looks like the seal needs replacing. I have the parts. I can come today at 2 PM. Will that work?',
      isMe: false,
      time: '10:35 AM',
    ),
    _ChatMessage(
      text: 'Perfect, 2 PM works for me!',
      isMe: true,
      time: '10:36 AM',
    ),
    _ChatMessage(
      text: 'Great! I\'m on my way, should be there in 15 minutes',
      isMe: false,
      time: '1:45 PM',
    ),
  ];

  @override
  void dispose() {
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
              child: Text('S',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saman Fernando',
                      style:
                          AppTypography.headlineSmall.copyWith(fontSize: 15)),
                  Text('Fix kitchen sink leak',
                      style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.videocam_outlined, size: 22),
              onPressed: () {}),
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
              color: AppColors.primary.withOpacity(0.06),
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
