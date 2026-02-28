import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/pages/home/contact_info_page.dart';
import 'package:hosla/providers/chat_provider.dart';
import 'package:hosla/widgets/glass_app_bar.dart';
import 'package:hosla/widgets/profile_pic.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ─────────────────────────────────────────────────────────────────────────────
// CHAT DETAIL PAGE — Complete Redesign
//
// Design principles:
//   • Glassmorphic AppBar with avatar + name + online status
//   • Subtle dotted background pattern
//   • Clean message bubbles with clear sender/receiver distinction
//   • Minimal, functional input area
//   • Smooth scrolling, date separators, read receipts
//   • Consistent with Hosla design system (teal, Quicksand, rounded)
// ─────────────────────────────────────────────────────────────────────────────

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
  final ImagePicker _picker = ImagePicker();
  bool _hasText = false;
  bool _showScrollToBottom = false;
  File? _pendingImage;

  late final AnimationController _sendBtnController;
  late final Animation<double> _sendBtnScale;

  @override
  void initState() {
    super.initState();
    _sendBtnController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _sendBtnScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatMessagesProvider(widget.chat.id).notifier)
          .markMessagesAsRead();
    });

    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onTextChanged() {
    final has = _messageController.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show =
        _scrollController.offset <
        _scrollController.position.maxScrollExtent - 200;
    if (show != _showScrollToBottom) setState(() => _showScrollToBottom = show);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chat.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: GlassAppBar(
        titleText: null,
        title: _AppBarTitle(chat: widget.chat, onTap: _viewContactInfo),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: ThemeColors.getNavBarIconColor(context),
            ),
            onPressed: _showChatOptions,
          ),
          const SizedBox(width: 2),
        ],
      ),
      body: Stack(
        children: [
          // Subtle background pattern
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter(isDark: isDark)),
          ),

          Column(
            children: [
              // Space for glass app bar
              SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              ),

              // ── Messages ──
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[i];
                          final isMe = msg.senderId == 'current_user';

                          // Date separator
                          bool showDate =
                              i == 0 ||
                              !_sameDay(
                                msg.timestamp,
                                messages[i - 1].timestamp,
                              );

                          // Tail (last in sender sequence)
                          final showTail =
                              i == messages.length - 1 ||
                              messages[i + 1].senderId != msg.senderId ||
                              !_sameDay(
                                msg.timestamp,
                                messages[i + 1].timestamp,
                              );

                          return Column(
                            children: [
                              if (showDate) _DateChip(date: msg.timestamp),
                              _MessageBubble(
                                message: msg,
                                isCurrentUser: isMe,
                                isDark: isDark,
                                showTail: showTail,
                                avatarUrl: widget.chat.avatarUrl ?? '',
                                onLongPress: () => _showMessageOptions(msg),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // ── Input area ──
              _InputBar(
                controller: _messageController,
                focusNode: _focusNode,
                hasText: _hasText,
                pendingImage: _pendingImage,
                sendBtnScale: _sendBtnScale,
                onSend: _sendMessage,
                onSendBtnDown: () => _sendBtnController.forward(),
                onSendBtnUp: () => _sendBtnController.reverse(),
                onAttach: _showAttachmentOptions,
                onCamera: _pickFromCamera,
                onGallery: _pickFromGallery,
                onClearImage: _clearPendingImage,
              ),
            ],
          ),

          // Scroll-to-bottom
          if (_showScrollToBottom)
            Positioned(
              bottom: 90,
              right: 16,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ThemeColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ThemeColors.getBorderColor(
                        context,
                      ).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ThemeColors.getSecondaryTextColor(context),
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────── Empty state ───────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
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
            OutlinedButton(
              onPressed: () {
                _messageController.text = '👋 Hey!';
                setState(() => _hasText = true);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeColors.primaryColor,
                side: const BorderSide(color: ThemeColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                '👋 Say Hello',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── Actions ───────────────

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
    if (text.isEmpty && _pendingImage == null) return;
    HapticFeedback.lightImpact();

    if (_pendingImage != null) {
      // Send as image message with optional caption
      ref
          .read(chatMessagesProvider(widget.chat.id).notifier)
          .sendMessage(text, MessageType.image, imageUrl: _pendingImage!.path);
    } else {
      ref
          .read(chatMessagesProvider(widget.chat.id).notifier)
          .sendMessage(text, MessageType.text);
    }
    _messageController.clear();
    setState(() {
      _hasText = false;
      _pendingImage = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickFromCamera() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (xFile != null) {
      setState(() => _pendingImage = File(xFile.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (xFile != null) {
      setState(() => _pendingImage = File(xFile.path));
    }
  }

  void _clearPendingImage() {
    setState(() => _pendingImage = null);
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactInfoPage(
          user: user,
          mutualGroups: widget.chat.type == ChatType.group
              ? <String>[]
              : ['Study Group', 'Friends Forever'],
        ),
      ),
    );
  }

  // ─────────────── Bottom sheets ───────────────

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),
              const SizedBox(height: 12),
              _tile(
                Icons.person_outline_rounded,
                'View Profile',
                onTap: () {
                  Navigator.pop(context);
                  _viewContactInfo();
                },
              ),
              _tile(
                widget.chat.isMuted
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_outlined,
                widget.chat.isMuted ? 'Unmute' : 'Mute Notifications',
              ),
              _tile(Icons.wallpaper_rounded, 'Wallpaper'),
              _tile(Icons.search_rounded, 'Search Messages'),
              _tile(
                Icons.delete_sweep_outlined,
                'Clear Chat',
                isDestructive: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(Message message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),
              const SizedBox(height: 12),
              _tile(
                Icons.copy_rounded,
                'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(context);
                },
              ),
              _tile(Icons.reply_rounded, 'Reply'),
              _tile(Icons.forward_rounded, 'Forward'),
              _tile(Icons.star_outline_rounded, 'Star'),
              _tile(
                Icons.delete_outline_rounded,
                'Delete',
                isDestructive: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachOption(
                    Icons.camera_alt_rounded,
                    'Camera',
                    const Color(0xFFE91E63),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                  _attachOption(
                    Icons.photo_rounded,
                    'Gallery',
                    const Color(0xFF9C27B0),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                  _attachOption(
                    Icons.insert_drive_file_rounded,
                    'Document',
                    const Color(0xFF3F51B5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachOption(
                    Icons.location_on_rounded,
                    'Location',
                    const Color(0xFF4CAF50),
                  ),
                  _attachOption(
                    Icons.person_rounded,
                    'Contact',
                    const Color(0xFF2196F3),
                  ),
                  _attachOption(
                    Icons.headphones_rounded,
                    'Audio',
                    const Color(0xFFFF9800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────── Sheet helpers ───────────────

  Widget _handle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ThemeColors.getSecondaryTextColor(
            context,
          ).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? ThemeColors.errorColor
            : ThemeColors.primaryColor,
      ),
      title: Text(
        label,
        style: TextThemes.getBodyMediumStyle(context).copyWith(
          color: isDestructive
              ? ThemeColors.errorColor
              : ThemeColors.getTextColor(context),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }

  Widget _attachOption(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTRACTED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// AppBar title with avatar + name + status — keeps GlassAppBar lightweight.
class _AppBarTitle extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  const _AppBarTitle({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isGroup = chat.type == ChatType.group;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Hero(
            tag: 'chat_avatar_${chat.id}',
            child: Stack(
              children: [
                ProfilePic(radius: 20, imageUrl: chat.avatarUrl ?? ''),
                if (!isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: ThemeColors.successColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ThemeColors.getBackgroundColor(context),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chat.name,
                  style: TextThemes.getBodyMediumStyle(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ThemeColors.getTextColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  isGroup
                      ? '${chat.participantIds.length} participants'
                      : 'Online',
                  style: TextThemes.getBodySmallStyle(context).copyWith(
                    color: ThemeColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Date separator chip between message groups.
class _DateChip extends StatelessWidget {
  final DateTime date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: ThemeColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          _format(date),
          style: TextThemes.getBodySmallStyle(context).copyWith(
            color: ThemeColors.getSecondaryTextColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _format(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final md = DateTime(d.year, d.month, d.day);
    if (md == today) return 'Today';
    if (md == yesterday) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}

/// Single message bubble with sender/receiver distinction.
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final bool isDark;
  final bool showTail;
  final String avatarUrl;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.isDark,
    required this.showTail,
    required this.avatarUrl,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: showTail ? 6 : 2,
        bottom: showTail ? 6 : 2,
        left: isCurrentUser ? 60 : 0,
        right: isCurrentUser ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showTail) ...[
            ProfilePic(radius: 14, imageUrl: avatarUrl),
            const SizedBox(width: 8),
          ] else if (!isCurrentUser)
            const SizedBox(width: 36),

          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? ThemeColors.primaryColor
                      : ThemeColors.getCardColor(context),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(
                      isCurrentUser || !showTail ? 16 : 4,
                    ),
                    bottomRight: Radius.circular(
                      !isCurrentUser || !showTail ? 16 : 4,
                    ),
                  ),
                  border: isCurrentUser
                      ? null
                      : Border.all(
                          color: ThemeColors.getBorderColor(
                            context,
                          ).withValues(alpha: 0.12),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _content(context),
                    const SizedBox(height: 4),
                    _timeRow(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final textColor = isCurrentUser
        ? Colors.black
        : (isDark
              ? const Color(0xFFF5F5F5)
              : ThemeColors.getTextColor(context));

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor,
            height: 1.4,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                message.imageUrl ?? '',
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: ThemeColors.getSecondaryTextColor(context),
                    size: 36,
                  ),
                ),
              ),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ],
          ],
        );
      case MessageType.emoji:
        return Text(message.content, style: const TextStyle(fontSize: 40));
    }
  }

  Widget _timeRow(BuildContext context) {
    final timeColor = isCurrentUser
        ? Colors.black.withValues(alpha: 0.5)
        : ThemeColors.getSecondaryTextColor(context).withValues(alpha: 0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _fmtTime(message.timestamp),
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: timeColor,
          ),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
            size: 14,
            color: message.isRead
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.4),
          ),
        ],
      ],
    );
  }

  String _fmtTime(DateTime ts) {
    final h = ts.hour;
    final m = ts.minute;
    final p = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${m.toString().padLeft(2, '0')} $p';
  }
}

/// Clean Hosla-style input bar.
///
/// Layout:
///   ┌─────────────────────────────────────────────┐
///   │  [image preview strip — if image pending]   │
///   ├─────────────────────────────────────────────┤
///   │  📎   [ message input ............. 📷 ]  ➤ │
///   └─────────────────────────────────────────────┘
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final File? pendingImage;
  final Animation<double> sendBtnScale;
  final VoidCallback onSend;
  final VoidCallback onSendBtnDown;
  final VoidCallback onSendBtnUp;
  final VoidCallback onAttach;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClearImage;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.pendingImage,
    required this.sendBtnScale,
    required this.onSend,
    required this.onSendBtnDown,
    required this.onSendBtnUp,
    required this.onAttach,
    required this.onCamera,
    required this.onGallery,
    required this.onClearImage,
  });

  bool get _canSend => hasText || pendingImage != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.getBackgroundColor(context),
        border: Border(
          top: BorderSide(
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Image preview strip ──
              if (pendingImage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ThemeColors.getBorderColor(
                        context,
                      ).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          pendingImage!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Photo attached',
                          style: TextThemes.getBodyMediumStyle(context)
                              .copyWith(
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ),
                                fontSize: 13,
                              ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onClearImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ThemeColors.getBorderColor(
                              context,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: ThemeColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Main input row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach button
                  GestureDetector(
                    onTap: onAttach,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ThemeColors.getCardColor(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ThemeColors.getBorderColor(
                            context,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: ThemeColors.getSecondaryTextColor(context),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Input container — pill-shaped, no fill
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        maxHeight: 140,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: ThemeColors.getBorderColor(
                            context,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: TextThemes.getBodyMediumStyle(
                          context,
                        ).copyWith(fontSize: 15),
                        cursorColor: ThemeColors.primaryColor,
                        decoration: InputDecoration(
                          hintText: pendingImage != null
                              ? 'Add a caption…'
                              : 'Type a message…',
                          hintStyle: TextThemes.getBodyMediumStyle(context)
                              .copyWith(
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ).withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        minLines: 1,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) {
                          if (_canSend) onSend();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Camera button (separate circular icon)
                  if (!hasText)
                    GestureDetector(
                      onTap: onCamera,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ThemeColors.getCardColor(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ThemeColors.getBorderColor(
                              context,
                            ).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: ThemeColors.getSecondaryTextColor(context),
                          size: 20,
                        ),
                      ),
                    ),
                  if (!hasText) const SizedBox(width: 8),

                  // ── Send / Mic button ──
                  ScaleTransition(
                    scale: sendBtnScale,
                    child: GestureDetector(
                      onTapDown: (_) => onSendBtnDown(),
                      onTapUp: (_) {
                        onSendBtnUp();
                        if (_canSend) onSend();
                      },
                      onTapCancel: onSendBtnUp,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _canSend
                              ? ThemeColors.primaryColor
                              : ThemeColors.getCardColor(context),
                          shape: BoxShape.circle,
                          border: _canSend
                              ? null
                              : Border.all(
                                  color: ThemeColors.getBorderColor(
                                    context,
                                  ).withValues(alpha: 0.25),
                                ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            _canSend
                                ? Icons.arrow_upward_rounded
                                : Icons.mic_none_rounded,
                            key: ValueKey(_canSend ? 'send' : 'mic'),
                            color: _canSend
                                ? Colors.black
                                : ThemeColors.getSecondaryTextColor(context),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle dot pattern background for the chat area.
class _DotPatternPainter extends CustomPainter {
  final bool isDark;
  _DotPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const radius = 1.5;

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
