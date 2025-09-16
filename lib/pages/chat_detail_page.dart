import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/providers/chat_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

/// Detailed chat screen with message bubbles and input functionality
class ChatDetailPage extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatDetailPage({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatMessagesProvider(widget.chat.id).notifier)
          .markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chat.id));

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyMessagesState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = message.senderId == 'current_user';

                      // Show date separator if needed
                      bool showDateSeparator = false;
                      if (index == 0) {
                        showDateSeparator = true;
                      } else {
                        final prevMessage = messages[index - 1];
                        showDateSeparator = !_isSameDay(
                          message.timestamp,
                          prevMessage.timestamp,
                        );
                      }

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _buildDateSeparator(message.timestamp),
                          _buildMessageBubble(message, isCurrentUser),
                        ],
                      );
                    },
                  ),
          ),

          // Message input bar
          _buildMessageInputBar(),
        ],
      ),
    );
  }

  /// Build app bar with chat info
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ThemeColors.getNavBarColor(context),
      elevation: 1,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: ThemeColors.getNavBarIconColor(context),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          ProfilePic(radius: 18, imageUrl: widget.chat.avatarUrl ?? ''),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.name,
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  _getOnlineStatus(),
                  style: TextThemes.getBodySmallStyle(context).copyWith(
                    fontSize: 12,
                    color: ThemeColors.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.videocam,
            color: ThemeColors.getNavBarIconColor(context),
          ),
          onPressed: () {
            // TODO: Implement video call
          },
        ),
        IconButton(
          icon: Icon(
            Icons.call,
            color: ThemeColors.getNavBarIconColor(context),
          ),
          onPressed: () {
            // TODO: Implement voice call
          },
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: ThemeColors.getNavBarIconColor(context),
          ),
          onPressed: () => _showChatOptions(),
        ),
      ],
    );
  }

  /// Build message bubble
  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser && widget.chat.type == ChatType.group)
            ProfilePic(radius: 16, imageUrl: ''),
          if (!isCurrentUser && widget.chat.type == ChatType.group)
            const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? ThemeColors.primaryColor
                    : ThemeColors.getCardColor(context),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.getOverlayColor(context, opacity: 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group chat sender name
                  if (!isCurrentUser && widget.chat.type == ChatType.group)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Alice Johnson', // TODO: Get actual sender name
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: ThemeColors.getSecondaryTextColor(context),
                        ),
                      ),
                    ),

                  // Message content
                  _buildMessageContent(message, isCurrentUser),

                  const SizedBox(height: 4),

                  // Timestamp and read status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          fontSize: 11,
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.8)
                              : ThemeColors.getSecondaryTextColor(context),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? Colors.white
                              : Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build message content based on type
  Widget _buildMessageContent(Message message, bool isCurrentUser) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextThemes.getBodyMediumStyle(context).copyWith(
            color: isCurrentUser
                ? Colors.white
                : ThemeColors.getTextColor(context),
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.imageUrl ?? '',
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: ThemeColors.getBorderColor(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                  );
                },
              ),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ],
        );
      case MessageType.emoji:
        return Text(message.content, style: const TextStyle(fontSize: 24));
    }
  }

  /// Build date separator
  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeColors.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDate(date),
                style: TextThemes.getBodySmallStyle(
                  context,
                ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  /// Build message input bar
  Widget _buildMessageInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attach button
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
            onPressed: _showAttachmentOptions,
          ),

          // Text input field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ThemeColors.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Emoji button
          IconButton(
            icon: Icon(
              Icons.emoji_emotions_outlined,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
            onPressed: _showEmojiPicker,
          ),

          // Send button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: ThemeColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  /// Build empty messages state
  Widget _buildEmptyMessagesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: ThemeColors.getSecondaryTextColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextThemes.getBodyLargeStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextThemes.getBodySmallStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  /// Get online status text
  String _getOnlineStatus() {
    if (widget.chat.type == ChatType.group) {
      return '${widget.chat.participantIds.length} participants';
    }

    // TODO: Implement actual online status check
    return 'Online'; // Dummy status
  }

  /// Send a message
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatMessagesProvider(widget.chat.id).notifier)
        .sendMessage(text, MessageType.text);

    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Show attachment options
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera,
                color: ThemeColors.primaryColor,
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open camera
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: ThemeColors.primaryColor,
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open gallery
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file,
                color: ThemeColors.primaryColor,
              ),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open document picker
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.location_on,
                color: ThemeColors.primaryColor,
              ),
              title: const Text('Location'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share location
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show emoji picker (placeholder)
  void _showEmojiPicker() {
    // TODO: Implement emoji picker
    SnackBarWidget.show(context, 'Emoji picker coming soon!');
  }

  /// Show chat options menu
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Chat Info'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show chat info
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: Text(widget.chat.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Toggle mute
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Starred Messages'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show starred messages
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Clear chat history
              },
            ),
            if (widget.chat.type == ChatType.group)
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Leave Group',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Leave group
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Format message timestamp
  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Format date for separator
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
