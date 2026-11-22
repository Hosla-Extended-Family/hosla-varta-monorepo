import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/providers/chat_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/pages/chat_detail_page.dart';
import 'package:hosla/widgets/glass_app_bar.dart';
import 'package:hosla/pages/home/new_chat_page.dart';
import 'package:hosla/pages/home/new_group_chat_page.dart';
import 'package:hosla/widgets/new_chat_fab.dart';
import 'package:hosla/widgets/profile_pic.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHATS PAGE — Complete Redesign
//
// Design principles:
//   • Clean, calm chat list consistent with Feed & Events pages
//   • GlassAppBar with consistent blur/opacity/radius
//   • Rounded card-style chat items with clear unread indicators
//   • Proper spacing, avatars, timestamps, message previews
//   • Extended FAB matching CreatePostFab / CreateEventFab pattern
// ─────────────────────────────────────────────────────────────────────────────

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  Set<String>? _matchingChatIds;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      final trimmed = query.trim().toLowerCase();
      if (!mounted) return;

      if (trimmed.isEmpty) {
        setState(() {
          _searchQuery = '';
          _matchingChatIds = null;
        });
        return;
      }

      final chatService = ref.read(chatServiceProvider);
      final chatsAsync = ref.read(chatsProvider);
      final chats = chatsAsync.value ?? [];
      final matching = <String>{};

      for (final chat in chats) {
        if (chat.name.toLowerCase().contains(trimmed)) {
          matching.add(chat.id);
          continue;
        }
        if (chat.lastMessage?.content.toLowerCase().contains(trimmed) == true) {
          matching.add(chat.id);
          continue;
        }
        // Deep search through stored messages in local store
        try {
          final msgs = await chatService.getChatMessages(chat.id);
          if (msgs.any((m) => m.content.toLowerCase().contains(trimmed))) {
            matching.add(chat.id);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _searchQuery = trimmed;
          _matchingChatIds = matching;
        });
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _matchingChatIds = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsProvider);
    final chats =
        chatsAsync.whenOrNull(data: (list) => list) ?? const <Chat>[];
    final isLoading = chatsAsync.isLoading;
    final filteredChats = _filterChats(chats);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        titleText: 'Chats',
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: ThemeColors.getNavBarIconColor(context),
            ),
            onPressed: () => _showMoreOptions(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: NewChatFab(
        onPressed: () => _openNewChat(context),
      ),
      body: Column(
        children: [
          // Spacer for glass app bar
          SizedBox(
            height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          ),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: ThemeColors.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: ThemeColors.getBorderColor(
                    context,
                  ).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: ThemeColors.getSecondaryTextColor(context),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextThemes.getBodyMediumStyle(context),
                      decoration: InputDecoration(
                        hintText: 'Search chats…',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: TextThemes.getBodyMediumStyle(context)
                            .copyWith(
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Icon(
                        Icons.close_rounded,
                        color: ThemeColors.getSecondaryTextColor(context),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Chat list ──
          Expanded(
            child: RefreshIndicator(
              color: ThemeColors.primaryColor,
              onRefresh: () => ref.read(chatsProvider.notifier).loadChats(),
              child: isLoading && chats.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : chats.isEmpty
                  ? _buildEmptyState()
                  : filteredChats.isEmpty
                  ? _buildNoResultsState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                      itemCount: filteredChats.length,
                      itemBuilder: (_, i) => _ChatListItem(
                        chat: filteredChats[i],
                        onTap: () => _openChat(filteredChats[i]),
                        onLongPress: () => _showChatOptions(filteredChats[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Empty states ─────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: ThemeColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No chats yet',
              style: TextThemes.getTitleStyle(
                context,
              ).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with someone!',
              textAlign: TextAlign.center,
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: ThemeColors.getDisabledColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No chats found',
            style: TextThemes.getBodyLargeStyle(context).copyWith(
              color: ThemeColors.getSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching with different keywords',
            style: TextThemes.getBodySmallStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  // ───────────────── Helpers ─────────────────

  List<Chat> _filterChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) return chats;
    if (_matchingChatIds != null) {
      return chats.where((c) => _matchingChatIds!.contains(c.id)).toList();
    }
    final q = _searchQuery.toLowerCase();
    return chats.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.lastMessage?.content.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _openChat(Chat chat) {
    ref.read(chatsProvider.notifier).markChatAsRead(chat.id);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
    );
  }

  // ───────────────── Bottom sheets ─────────────────

  void _showChatOptions(Chat chat) {
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
              _handle(context),
              const SizedBox(height: 12),
              _sheetTile(
                chat.isMuted
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                chat.isMuted ? 'Unmute' : 'Mute',
              ),
              _sheetTile(Icons.archive_rounded, 'Archive Chat'),
              _sheetTile(
                Icons.delete_outline_rounded,
                'Delete Chat',
                isDestructive: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
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
              _handle(context),
              const SizedBox(height: 12),
              _sheetTile(
                Icons.group_add_rounded,
                'New Group',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewGroupChatPage()),
                  );
                },
              ),
              _sheetTile(Icons.star_outline_rounded, 'Starred Messages'),
              _sheetTile(Icons.settings_rounded, 'Chat Settings'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openNewChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewChatPage()),
    );
  }

  Widget _handle(BuildContext context) {
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

  Widget _sheetTile(
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT LIST ITEM — Extracted reusable widget
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatListItem extends ConsumerWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatListItem({
    required this.chat,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = chat.unreadCount > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onlineUsers = ref.watch(onlineUsersProvider);
    final profileUser = ref.watch(currentUserProfileProvider);
    final myId = profileUser?.id ?? '';
    final otherUserId = chat.participantIds.firstWhere(
      (id) => id != myId,
      orElse: () => '',
    );
    final isOnline = chat.type == ChatType.individual &&
        otherUserId.isNotEmpty &&
        onlineUsers.contains(otherUserId);

    final lastMsg = chat.lastMessage;
    final isSentByMe = lastMsg != null &&
        ((myId.isNotEmpty && lastMsg.senderId == myId) ||
            lastMsg.senderId == 'current_user' ||
            lastMsg.senderId.isEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasUnread
                  ? ThemeColors.primaryColor.withValues(
                      alpha: isDark ? 0.06 : 0.04,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // ── Avatar with online dot ──
                _Avatar(
                  imageUrl: chat.avatarUrl ?? '',
                  isOnline: isOnline,
                  isGroup: chat.type == ChatType.group,
                ),
                const SizedBox(width: 14),

                // ── Name + last message ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              style: TextThemes.getBodyMediumStyle(context)
                                  .copyWith(
                                    fontWeight: hasUnread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(chat.lastActivity),
                            style: TextThemes.getBodySmallStyle(context)
                                .copyWith(
                                  color: hasUnread
                                      ? ThemeColors.primaryColor
                                      : ThemeColors.getSecondaryTextColor(
                                          context,
                                        ),
                                  fontSize: 12,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Read receipts for sent messages
                          if (isSentByMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                lastMsg.isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 15,
                                color: lastMsg.isRead
                                    ? ThemeColors.primaryColor
                                    : ThemeColors.getSecondaryTextColor(
                                        context,
                                      ),
                              ),
                            ),

                          // Preview text
                          Expanded(
                            child: Text(
                              _previewText(chat),
                              style: TextThemes.getBodySmallStyle(context)
                                  .copyWith(
                                    color: hasUnread
                                        ? ThemeColors.getTextColor(context)
                                        : ThemeColors.getSecondaryTextColor(
                                            context,
                                          ),
                                    fontWeight: hasUnread
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Unread badge
                          if (hasUnread)
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeColors.primaryColor,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  chat.unreadCount > 99
                                      ? '99+'
                                      : '${chat.unreadCount}',
                                  style: const TextStyle(
                                    fontFamily: 'Quicksand',
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                          // Muted
                          if (chat.isMuted)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.volume_off_rounded,
                                size: 14,
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _previewText(Chat chat) {
    if (chat.lastMessage == null) return 'No messages yet';
    final m = chat.lastMessage!;
    return switch (m.type) {
      MessageType.text => m.content,
      MessageType.image => '📷 Photo',
      MessageType.emoji => m.content,
    };
  }

  String _formatTimestamp(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inDays > 6) return '${ts.day}/${ts.month}';
    if (diff.inDays > 1) return '${diff.inDays}d';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar — CircleAvatar with optional online indicator
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String imageUrl;
  final bool isOnline;
  final bool isGroup;

  const _Avatar({
    required this.imageUrl,
    this.isOnline = false,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ThemeColors.primaryColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ProfilePic(radius: 26, imageUrl: imageUrl),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: ThemeColors.successColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ThemeColors.getBackgroundColor(context),
                  width: 2.5,
                ),
              ),
            ),
          ),
        if (isGroup)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ThemeColors.getBackgroundColor(context),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.group_rounded,
                size: 9,
                color: Colors.black,
              ),
            ),
          ),
      ],
    );
  }
}
