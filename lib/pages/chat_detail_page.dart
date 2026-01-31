import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/pages/home/contact_info_page.dart';
import 'package:hosla/providers/chat_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';

/// Modern chat detail page with enhanced UI/UX
class ChatDetailPage extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatDetailPage({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _isTyping = false;
  bool _showScrollToBottom = false;

  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

  @override
  void initState() {
    super.initState();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );

    // Mark messages as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatMessagesProvider(widget.chat.id).notifier)
          .markMessagesAsRead();
    });

    // Listen to text changes
    _messageController.addListener(_onTextChanged);

    // Listen to scroll position
    _scrollController.addListener(_onScroll);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final showButton =
        _scrollController.offset <
        _scrollController.position.maxScrollExtent - 200;
    if (showButton != _showScrollToBottom) {
      setState(() => _showScrollToBottom = showButton);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chat.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E11)
          : const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Chat background pattern
          Positioned.fill(
            child: CustomPaint(painter: _ChatBackgroundPainter(isDark: isDark)),
          ),

          // Main content
          Column(
            children: [
              // Custom App Bar
              _buildAppBar(context, isDark),

              // Messages
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(context)
                    : _buildMessagesList(messages, isDark),
              ),

              // Input area
              _buildInputArea(context, isDark),
            ],
          ),

          // Scroll to bottom button
          if (_showScrollToBottom)
            Positioned(
              bottom: 90,
              right: 16,
              child: _buildScrollToBottomButton(context),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D21) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),

            // Avatar with online indicator
            GestureDetector(
              onTap: _viewContactInfo,
              child: Stack(
                children: [
                  Hero(
                    tag: 'chat_avatar_${widget.chat.id}',
                    child: ProfilePic(
                      radius: 20,
                      imageUrl: widget.chat.avatarUrl ?? '',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: ThemeColors.successColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1A1D21)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Name and status
            Expanded(
              child: GestureDetector(
                onTap: _viewContactInfo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.chat.name,
                      style: TextThemes.getBodyMediumStyle(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (_isTyping) ...[
                          _buildTypingIndicator(),
                          const SizedBox(width: 4),
                          Text(
                            'typing...',
                            style: TextThemes.getBodySmallStyle(context)
                                .copyWith(
                                  color: ThemeColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                          ),
                        ] else
                          Text(
                            _getOnlineStatus(),
                            style: TextThemes.getBodySmallStyle(context)
                                .copyWith(
                                  color: ThemeColors.successColor,
                                  fontSize: 12,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            _buildActionButton(Icons.videocam_rounded, () {}, isDark),
            _buildActionButton(Icons.call_rounded, () {}, isDark),
            _buildActionButton(
              Icons.more_vert_rounded,
              _showChatOptions,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.only(left: index == 0 ? 0 : 2),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: ThemeColors.primaryColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildMessagesList(List<Message> messages, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == 'current_user';

        // Date separator
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

        // Check if this is the first message from sender in a sequence
        final showTail =
            index == messages.length - 1 ||
            messages[index + 1].senderId != message.senderId ||
            !_isSameDay(message.timestamp, messages[index + 1].timestamp);

        return Column(
          children: [
            if (showDateSeparator) _buildDateChip(message.timestamp),
            _buildMessageBubble(message, isCurrentUser, isDark, showTail),
          ],
        );
      },
    );
  }

  Widget _buildDateChip(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _formatDate(date),
        style: TextThemes.getBodySmallStyle(context).copyWith(
          color: ThemeColors.primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isCurrentUser,
    bool isDark,
    bool showTail,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: showTail ? 8 : 2,
        left: isCurrentUser ? 60 : 0,
        right: isCurrentUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other user avatar (only show for last message in sequence)
          if (!isCurrentUser && showTail) ...[
            ProfilePic(radius: 14, imageUrl: widget.chat.avatarUrl ?? ''),
            const SizedBox(width: 8),
          ] else if (!isCurrentUser)
            const SizedBox(width: 36),

          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isCurrentUser
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ThemeColors.primaryColor,
                            ThemeColors.primaryColor.withBlue(180),
                          ],
                        )
                      : null,
                  color: isCurrentUser
                      ? null
                      : (isDark ? const Color(0xFF1E2428) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(
                      isCurrentUser || !showTail ? 18 : 4,
                    ),
                    bottomRight: Radius.circular(
                      !isCurrentUser || !showTail ? 18 : 4,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Message content
                    _buildMessageContent(message, isCurrentUser, isDark),

                    const SizedBox(height: 4),

                    // Time and status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrentUser
                                ? Colors.white.withValues(alpha: 0.7)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 14,
                            color: message.isRead
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    Message message,
    bool isCurrentUser,
    bool isDark,
  ) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 15,
            color: isCurrentUser
                ? Colors.white
                : (isDark
                      ? Colors.white.withValues(alpha: 0.95)
                      : const Color(0xFF1A1A1A)),
            height: 1.3,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: ThemeColors.getSecondaryTextColor(context),
                      size: 40,
                    ),
                  );
                },
              ),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ],
        );
      case MessageType.emoji:
        return Text(message.content, style: const TextStyle(fontSize: 40));
    }
  }

  Widget _buildInputArea(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D21) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              _buildInputIconButton(
                Icons.add_rounded,
                _showAttachmentOptions,
                isDark,
              ),

              const SizedBox(width: 8),

              // Text input
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2D31)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Emoji button
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: _buildInputIconButton(
                          Icons.emoji_emotions_outlined,
                          () {},
                          isDark,
                          size: 24,
                        ),
                      ),

                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          style: TextThemes.getBodyMediumStyle(context),
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextThemes.getBodyMediumStyle(context)
                                .copyWith(
                                  color: ThemeColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),

                      // Camera button (hide when typing)
                      if (!_hasText)
                        Padding(
                          padding: const EdgeInsets.only(right: 4, bottom: 4),
                          child: _buildInputIconButton(
                            Icons.camera_alt_outlined,
                            () {},
                            isDark,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send / Voice button
              ScaleTransition(
                scale: _sendButtonScale,
                child: GestureDetector(
                  onTapDown: (_) => _sendButtonController.forward(),
                  onTapUp: (_) {
                    _sendButtonController.reverse();
                    if (_hasText) {
                      _sendMessage();
                    }
                  },
                  onTapCancel: () => _sendButtonController.reverse(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeColors.primaryColor,
                          ThemeColors.primaryColor.withBlue(180),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ThemeColors.primaryColor.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _hasText ? Icons.send_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputIconButton(
    IconData icon,
    VoidCallback onTap,
    bool isDark, {
    double size = 28,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isDark ? Colors.white60 : Colors.black45,
            size: size,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton(BuildContext context) {
    return GestureDetector(
      onTap: _scrollToBottom,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: ThemeColors.getSecondaryTextColor(context),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: ThemeColors.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextThemes.getTitleStyle(
              context,
            ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to ${widget.chat.name}!',
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              _messageController.text = '👋 Hey!';
              _hasText = true;
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: ThemeColors.primaryColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '👋 Say Hello',
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  color: ThemeColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    ref
        .read(chatMessagesProvider(widget.chat.id).notifier)
        .sendMessage(text, MessageType.text);

    _messageController.clear();
    setState(() => _hasText = false);

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _showMessageOptions(Message message) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeColors.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionTile(Icons.copy_rounded, 'Copy', () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Message copied')));
              }),
              _buildOptionTile(Icons.reply_rounded, 'Reply', () {
                Navigator.pop(context);
              }),
              _buildOptionTile(Icons.forward_rounded, 'Forward', () {
                Navigator.pop(context);
              }),
              _buildOptionTile(Icons.star_outline_rounded, 'Star', () {
                Navigator.pop(context);
              }),
              _buildOptionTile(Icons.delete_outline_rounded, 'Delete', () {
                Navigator.pop(context);
              }, isDestructive: true),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : ThemeColors.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      onTap: onTap,
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeColors.getBorderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      Icons.camera_alt_rounded,
                      'Camera',
                      const Color(0xFFE91E63),
                      () => Navigator.pop(context),
                    ),
                    _buildAttachmentOption(
                      Icons.photo_rounded,
                      'Gallery',
                      const Color(0xFF9C27B0),
                      () => Navigator.pop(context),
                    ),
                    _buildAttachmentOption(
                      Icons.insert_drive_file_rounded,
                      'Document',
                      const Color(0xFF3F51B5),
                      () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      Icons.location_on_rounded,
                      'Location',
                      const Color(0xFF4CAF50),
                      () => Navigator.pop(context),
                    ),
                    _buildAttachmentOption(
                      Icons.person_rounded,
                      'Contact',
                      const Color(0xFF2196F3),
                      () => Navigator.pop(context),
                    ),
                    _buildAttachmentOption(
                      Icons.headphones_rounded,
                      'Audio',
                      const Color(0xFFFF9800),
                      () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextThemes.getBodySmallStyle(context).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ThemeColors.getBorderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _buildOptionTile(
                Icons.person_outline_rounded,
                'View Profile',
                () {
                  Navigator.pop(context);
                  _viewContactInfo();
                },
              ),
              _buildOptionTile(
                widget.chat.isMuted
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_outlined,
                widget.chat.isMuted ? 'Unmute' : 'Mute Notifications',
                () => Navigator.pop(context),
              ),
              _buildOptionTile(
                Icons.wallpaper_rounded,
                'Wallpaper',
                () => Navigator.pop(context),
              ),
              _buildOptionTile(
                Icons.search_rounded,
                'Search',
                () => Navigator.pop(context),
              ),
              _buildOptionTile(
                Icons.delete_sweep_outlined,
                'Clear Chat',
                () => Navigator.pop(context),
                isDestructive: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _viewContactInfo() {
    final user = User(
      id: widget.chat.participantIds.isNotEmpty
          ? widget.chat.participantIds.first
          : 'user_id',
      name: widget.chat.name,
      avatarUrl: widget.chat.avatarUrl,
      bio: 'Hey there! I am using Hosla Varta',
      email: 'user@example.com',
      isOnline: true,
    );

    final mutualGroups = widget.chat.type == ChatType.group
        ? <String>[]
        : ['Study Group', 'Friends Forever', 'Weekend Warriors'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContactInfoPage(user: user, mutualGroups: mutualGroups),
      ),
    );
  }

  String _getOnlineStatus() {
    if (widget.chat.type == ChatType.group) {
      return '${widget.chat.participantIds.length} participants';
    }
    return 'Online';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatMessageTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Today';
    if (messageDate == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Background pattern painter for chat
class _ChatBackgroundPainter extends CustomPainter {
  final bool isDark;

  _ChatBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const radius = 2.0;

    for (double y = 0; y < size.height; y += spacing) {
      for (
        double x = (y ~/ spacing).isEven ? 0 : spacing / 2;
        x < size.width;
        x += spacing
      ) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
