import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/providers/chat_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';
import 'package:hosla/pages/chat_detail_page.dart';

/// Chat page displaying list of recent chats with WhatsApp-like UI
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatsProvider);
    final filteredChats = _filterChats(chats);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
        title: Text(
          'Chats',
          style: TextThemes.getTitleStyle(context).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ThemeColors.getTextColor(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: ThemeColors.getNavBarIconColor(context),
            ),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar at the top
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeColors.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: ThemeColors.getSecondaryTextColor(context),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextThemes.getBodyMediumStyle(context),
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: TextThemes.getBodyMediumStyle(context)
                            .copyWith(
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: Icon(
                        Icons.clear,
                        color: ThemeColors.getSecondaryTextColor(context),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Chat list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(chatsProvider.notifier).loadChats();
              },
              child: chats.isEmpty
                  ? _buildEmptyState()
                  : filteredChats.isEmpty
                  ? _buildNoResultsState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filteredChats.length,
                      separatorBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          color: ThemeColors.getSecondaryTextColor(
                            context,
                          ).withValues(alpha: 0.1),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        return _buildChatTile(chat);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatOptions(context),
        backgroundColor: ThemeColors.primaryColor,
        child: Icon(Icons.chat, color: ThemeColors.getCardColor(context)),
      ),
    );
  }

  /// Build individual chat tile
  Widget _buildChatTile(Chat chat) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openChatDetail(chat),
        onLongPress: () => _showChatOptions(chat),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ThemeColors.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ProfilePic(
                      radius: 30,
                      imageUrl: chat.avatarUrl ?? '',
                    ),
                  ),
                  if (chat.type == ChatType.individual && _isUserOnline(chat))
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: ThemeColors.getSuccessColor(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ThemeColors.getBackgroundColor(context),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Chat info
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
                                  fontWeight: chat.unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTimestamp(chat.lastActivity),
                          style: TextThemes.getBodySmallStyle(context).copyWith(
                            color: chat.unreadCount > 0
                                ? ThemeColors.primaryColor
                                : ThemeColors.getSecondaryTextColor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Message status indicator (for sent messages)
                        if (chat.lastMessage?.senderId == 'current_user')
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              chat.lastMessage?.isRead == true
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 18,
                              color: chat.lastMessage?.isRead == true
                                  ? ThemeColors.primaryColor
                                  : ThemeColors.getSecondaryTextColor(context),
                            ),
                          ),

                        // Last message preview
                        Expanded(
                          child: Text(
                            _getLastMessagePreview(chat),
                            style: TextThemes.getBodySmallStyle(context)
                                .copyWith(
                                  color: chat.unreadCount > 0
                                      ? ThemeColors.getTextColor(context)
                                      : ThemeColors.getSecondaryTextColor(
                                          context,
                                        ),
                                  fontWeight: chat.unreadCount > 0
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Unread count badge
                        if (chat.unreadCount > 0)
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ThemeColors.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeColors.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                chat.unreadCount > 99
                                    ? '99+'
                                    : '${chat.unreadCount}',
                                style: TextThemes.getBodySmallStyle(context)
                                    .copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),

                        // Muted indicator
                        if (chat.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.volume_off,
                              size: 16,
                              color: ThemeColors.getSecondaryTextColor(context),
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
    );
  }

  /// Build no search results state
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
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
          const SizedBox(height: 8),
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

  /// Build empty state when no chats available
  Widget _buildEmptyState() {
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
              Icons.chat_bubble_outline,
              size: 64,
              color: ThemeColors.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No chats yet',
            style: TextThemes.getBodyLargeStyle(context).copyWith(
              color: ThemeColors.getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone!',
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showNewChatOptions(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Start New Chat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Filter chats based on search query
  List<Chat> _filterChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      return chat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (chat.lastMessage?.content.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
    }).toList();
  }

  /// Check if user is online (dummy implementation)
  bool _isUserOnline(Chat chat) {
    // TODO: Implement actual online status check
    return chat.participantIds.length == 2; // Dummy logic
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays}d';
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  /// Get last message preview text
  String _getLastMessagePreview(Chat chat) {
    if (chat.lastMessage == null) return 'No messages yet';

    final message = chat.lastMessage!;
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.emoji:
        return message.content;
    }
  }

  /// Open chat detail page
  void _openChatDetail(Chat chat) {
    // Mark chat as read when opening
    ref.read(chatsProvider.notifier).markChatAsRead(chat.id);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatDetailPage(chat: chat)),
    );
  }

  /// Show chat options on long press
  void _showChatOptions(Chat chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                chat.isMuted ? Icons.volume_up : Icons.volume_off,
                color: ThemeColors.primaryColor,
              ),
              title: Text(chat.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement toggle mute
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Chat',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete chat
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show more options menu
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.group_add, color: ThemeColors.primaryColor),
              title: const Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create group page
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: ThemeColors.primaryColor),
              title: const Text('Starred Messages'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to starred messages
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: ThemeColors.primaryColor),
              title: const Text('Chat Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to chat settings
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show new chat options
  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_add, color: ThemeColors.primaryColor),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to contacts/new chat page
              },
            ),
            ListTile(
              leading: Icon(Icons.group_add, color: ThemeColors.primaryColor),
              title: const Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create group page
              },
            ),
            ListTile(
              leading: Icon(
                Icons.qr_code_scanner,
                color: ThemeColors.primaryColor,
              ),
              title: const Text('Scan QR Code'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open QR scanner
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
