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
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.navBarColor,
        elevation: 1,
        title: Text(
          'Chats',
          style: TextThemes.title.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: ThemeColors.navBarIconColor),
            onPressed: () => _showSearchDelegate(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: ThemeColors.navBarIconColor),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(chatsProvider.notifier).loadChats();
        },
        child: Column(
          children: [
            // Search bar
            if (_searchQuery.isNotEmpty) _buildSearchBar(),
            
            // Chats list
            Expanded(
              child: chats.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        return _buildChatTile(chat);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatOptions(context),
        backgroundColor: ThemeColors.primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  /// Build search bar widget
  Widget _buildSearchBar() {
    return Container(
      margin: Constants.defaultMargin.copyWith(top: 8, bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search chats...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
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
              child: const Icon(Icons.clear, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  /// Build individual chat tile
  Widget _buildChatTile(Chat chat) {
    return InkWell(
      onTap: () => _openChatDetail(chat),
      child: Container(
        padding: Constants.defaultPadding.copyWith(top: 12, bottom: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                ProfilePic(
                  radius: 28,
                  imageUrl: chat.avatarUrl ?? '',
                ),
                if (chat.type == ChatType.individual && _isUserOnline(chat))
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            
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
                          style: TextThemes.bodyMedium.copyWith(
                            fontWeight: chat.unreadCount > 0 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimestamp(chat.lastActivity),
                        style: TextThemes.bodySmall.copyWith(
                          color: chat.unreadCount > 0 
                              ? ThemeColors.primaryColor 
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Message status indicator (for sent messages)
                      if (chat.lastMessage?.senderId == 'current_user')
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            chat.lastMessage?.isRead == true
                                ? Icons.done_all
                                : Icons.done,
                            size: 16,
                            color: chat.lastMessage?.isRead == true
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      
                      // Last message preview
                      Expanded(
                        child: Text(
                          _getLastMessagePreview(chat),
                          style: TextThemes.bodySmall.copyWith(
                            color: chat.unreadCount > 0 
                                ? Colors.black87 
                                : Colors.grey.shade600,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColors.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                            style: TextThemes.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      
                      // Muted indicator
                      if (chat.isMuted)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.volume_off,
                            size: 16,
                            color: Colors.grey,
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
    );
  }

  /// Build empty state when no chats available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextThemes.bodyLarge.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone!',
            style: TextThemes.bodySmall.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showNewChatOptions(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Start New Chat'),
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
             (chat.lastMessage?.content
                 .toLowerCase()
                 .contains(_searchQuery.toLowerCase()) ?? false);
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
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(chat: chat),
      ),
    );
  }

  /// Show search delegate
  void _showSearchDelegate(BuildContext context) {
    setState(() {
      _searchQuery = '';
    });
    _buildSearchBar();
  }

  /// Show more options menu
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create group page
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Starred Messages'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to starred messages
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to chat settings
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show new chat options
  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: Constants.defaultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to contacts/new chat page
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create group page
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Code'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open QR scanner
              },
            ),
          ],
        ),
      ),
    );
  }
}