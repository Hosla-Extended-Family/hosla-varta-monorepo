import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/pages/chat_detail_page.dart';
import 'package:hosla/pages/home/new_group_chat_page.dart';
import 'package:hosla/providers/chat_provider.dart';
import 'package:hosla/providers/friend_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/glass_app_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEW CHAT PAGE
//
// Lets the user pick a friend to start a 1-on-1 conversation.
//
// Design tokens:
//   • GlassAppBar, pill-shaped search bar (radius 30)
//   • Rounded card sections, Quicksand font, teal accents
//   • Consistent with Feed, Events, Chat pages
// ─────────────────────────────────────────────────────────────────────────────

class NewChatPage extends ConsumerStatefulWidget {
  const NewChatPage({super.key});

  @override
  ConsumerState<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends ConsumerState<NewChatPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isStartingChat = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final currentUserId = ref.watch(currentUserProfileProvider)?.id ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: const GlassAppBar(titleText: 'New Chat'),
      body: Column(
        children: [
          // Spacer for glass app bar
          SizedBox(
            height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          ),

          // ── Search bar ──
          _buildSearchBar(),

          // ── Quick actions ──
          _buildQuickActions(),

          // ── Friends list ──
          Expanded(
            child: friendsAsync.when(
              data: (friends) => _buildFriendsList(friends, currentUserId),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: ThemeColors.primaryColor,
                ),
              ),
              error: (e, _) => _buildErrorState(),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── SEARCH BAR ─────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.3),
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
                  hintText: 'Search friends…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintStyle: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(
                  Icons.close_rounded,
                  color: ThemeColors.getSecondaryTextColor(context),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── QUICK ACTIONS ──────────────────────────

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.group_add_rounded,
            label: 'New Group',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewGroupChatPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: ThemeColors.primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────── FRIENDS LIST ───────────────────────────

  Widget _buildFriendsList(List<FriendshipEdge> friends, String currentUserId) {
    final filtered = _searchQuery.isEmpty
        ? friends
        : friends.where((edge) {
            final other = edge.otherParty(currentUserId);
            return other?.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false;
          }).toList();

    if (friends.isEmpty) return _buildEmptyState();
    if (filtered.isEmpty) return _buildNoResultsState();

    // Sort alphabetically
    filtered.sort((a, b) {
      final nameA = a.otherParty(currentUserId)?.name ?? '';
      final nameB = b.otherParty(currentUserId)?.name ?? '';
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });

    // Group by first letter
    final grouped = <String, List<FriendshipEdge>>{};
    for (final edge in filtered) {
      final name = edge.otherParty(currentUserId)?.name ?? '?';
      final letter = name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(edge);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: sortedKeys.length,
      itemBuilder: (context, sectionIndex) {
        final letter = sortedKeys[sectionIndex];
        final edges = grouped[letter]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Text(
                letter,
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.primaryColor,
                  fontSize: 13,
                ),
              ),
            ),
            // Contacts
            ...edges.map((edge) {
              final other = edge.otherParty(currentUserId);
              if (other == null) return const SizedBox.shrink();
              return _contactTile(other);
            }),
          ],
        );
      },
    );
  }

  Widget _contactTile(FriendUserSummary user) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startChat(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeColors.getSurfaceColor(context),
                  border: Border.all(
                    color: ThemeColors.getBorderColor(
                      context,
                    ).withValues(alpha: 0.2),
                  ),
                ),
                child: ClipOval(
                  child:
                      user.profilePicUrl != null &&
                          user.profilePicUrl!.isNotEmpty
                      ? Image.network(
                          user.profilePicUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _defaultAvatar(user.name),
                        )
                      : _defaultAvatar(user.name),
                ),
              ),
              const SizedBox(width: 14),

              // Name
              Expanded(
                child: Text(
                  user.name,
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),

              // Message icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: ThemeColors.primaryColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      color: ThemeColors.primaryColor.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: ThemeColors.primaryColor,
          ),
        ),
      ),
    );
  }

  // ───────────────────── EMPTY / ERROR ──────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: ThemeColors.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No friends yet',
              style: TextThemes.getTitleStyle(
                context,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to start chatting with them',
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: ThemeColors.getSecondaryTextColor(
                context,
              ).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextThemes.getBodyMediumStyle(context).copyWith(
                color: ThemeColors.getSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: ThemeColors.getSecondaryTextColor(
                context,
              ).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load friends',
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(friendsListProvider.notifier).refresh(),
              child: const Text(
                'Retry',
                style: TextStyle(color: ThemeColors.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── ACTIONS ────────────────────────────────

  Future<void> _startChat(FriendUserSummary user) async {
    if (_isStartingChat) return;
    _isStartingChat = true;

    try {
      final service = ref.read(chatServiceProvider);
      final chat = await service.getOrCreateDirectChat(user.id);

      if (!mounted) return;
      ref.read(chatsProvider.notifier).applyLocalUpdate(chat);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start chat: $e')),
      );
    } finally {
      _isStartingChat = false;
    }
  }
}
