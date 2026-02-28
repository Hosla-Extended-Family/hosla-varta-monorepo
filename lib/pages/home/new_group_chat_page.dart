import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/pages/chat_detail_page.dart';
import 'package:hosla/providers/chat_provider.dart';
import 'package:hosla/providers/friend_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/glass_app_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEW GROUP CHAT PAGE
//
// Multi-step flow:
//   Step 1 — Select participants from friends list
//   Step 2 — Set group name, icon, and create
//
// Design tokens:
//   • GlassAppBar, pill-shaped search bar (radius 30)
//   • Rounded card surfaces, teal accents, Quicksand font
//   • Consistent with New Chat, Feed, Events pages
// ─────────────────────────────────────────────────────────────────────────────

class NewGroupChatPage extends ConsumerStatefulWidget {
  const NewGroupChatPage({super.key});

  @override
  ConsumerState<NewGroupChatPage> createState() => _NewGroupChatPageState();
}

class _NewGroupChatPageState extends ConsumerState<NewGroupChatPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedIds = {};
  final Map<String, FriendUserSummary> _selectedUsers = {};
  bool _isStep2 = false;

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: GlassAppBar(
        titleText: _isStep2 ? 'New Group' : 'Add Participants',
        actions: [
          if (!_isStep2 && _selectedIds.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _isStep2 = true),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next',
                      style: TextThemes.getButtonStyle(context).copyWith(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          ),
          Expanded(child: _isStep2 ? _buildStep2() : _buildStep1()),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // STEP 1 — Select Participants
  // ═════════════════════════════════════════════════════════════════

  Widget _buildStep1() {
    final friendsAsync = ref.watch(friendsListProvider);
    final currentUserId = ref.watch(currentUserProfileProvider)?.id ?? '';

    return Column(
      children: [
        // Search bar
        _buildSearchBar(),

        // Selected chips strip
        if (_selectedUsers.isNotEmpty) _buildSelectedChips(),

        // Count indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(
                'Friends',
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  color: ThemeColors.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (_selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedIds.length} selected',
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: ThemeColors.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Friends list
        Expanded(
          child: friendsAsync.when(
            data: (friends) => _buildFriendsList(friends, currentUserId),
            loading: () => const Center(
              child: CircularProgressIndicator(color: ThemeColors.primaryColor),
            ),
            error: (e, _) => _buildErrorState(),
          ),
        ),
      ],
    );
  }

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

  Widget _buildSelectedChips() {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(top: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _selectedUsers.length,
        itemBuilder: (context, index) {
          final user = _selectedUsers.values.elementAt(index);
          return GestureDetector(
            onTap: () => _toggleUser(user),
            child: SizedBox(
              width: 60,
              child: Column(
                children: [
                  Stack(
                    children: [
                      _buildSmallAvatar(user, 24),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: ThemeColors.getCardColor(context),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: ThemeColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 10,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.name.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextThemes.getBodySmallStyle(
                      context,
                    ).copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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

    if (friends.isEmpty) return _buildEmptyFriendsState();
    if (filtered.isEmpty) return _buildNoResultsState();

    filtered.sort((a, b) {
      final nameA = a.otherParty(currentUserId)?.name ?? '';
      final nameB = b.otherParty(currentUserId)?.name ?? '';
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final edge = filtered[index];
        final other = edge.otherParty(currentUserId);
        if (other == null) return const SizedBox.shrink();

        final isSelected = _selectedIds.contains(other.id);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleUser(other),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar
                  _buildSmallAvatar(other, 24),
                  const SizedBox(width: 14),

                  // Name
                  Expanded(
                    child: Text(
                      other.name,
                      style: TextThemes.getBodyMediumStyle(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),

                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ThemeColors.primaryColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? ThemeColors.primaryColor
                            : ThemeColors.getBorderColor(
                                context,
                              ).withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.black,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // STEP 2 — Group Name & Create
  // ═════════════════════════════════════════════════════════════════

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Group icon + name
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeColors.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ThemeColors.getBorderColor(
                  context,
                ).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                // Group avatar placeholder
                GestureDetector(
                  onTap: () {
                    // TODO: Pick group image
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: ThemeColors.primaryColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Group name field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Name',
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _groupNameController,
                        style: TextThemes.getBodyMediumStyle(
                          context,
                        ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                        cursorColor: ThemeColors.primaryColor,
                        decoration: InputDecoration(
                          hintText: 'Type group name…',
                          hintStyle: TextThemes.getBodyMediumStyle(context)
                              .copyWith(
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ).withValues(alpha: 0.4),
                                fontSize: 15,
                              ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Participants header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.people_rounded,
                  size: 20,
                  color: ThemeColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Participants',
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedUsers.length}',
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: ThemeColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Participant list
          Container(
            decoration: BoxDecoration(
              color: ThemeColors.getCardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ThemeColors.getBorderColor(
                  context,
                ).withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: _selectedUsers.values.toList().asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                final user = entry.value;
                final isLast = index == _selectedUsers.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _buildSmallAvatar(user, 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.name,
                              style: TextThemes.getBodyMediumStyle(context)
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _toggleUser(user),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: ThemeColors.getSecondaryTextColor(
                                context,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 54,
                        color: ThemeColors.getBorderColor(
                          context,
                        ).withValues(alpha: 0.15),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // Create button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _groupNameController.text.trim().isNotEmpty
                  ? _createGroup
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.primaryColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: ThemeColors.primaryColor.withValues(
                  alpha: 0.3,
                ),
                disabledForegroundColor: Colors.black45,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Create Group',
                style: TextThemes.getButtonStyle(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _groupNameController.text.trim().isNotEmpty
                      ? Colors.black
                      : Colors.black45,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════

  Widget _buildSmallAvatar(FriendUserSummary user, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: ThemeColors.primaryColor.withValues(alpha: 0.15),
      backgroundImage:
          user.profilePicUrl != null && user.profilePicUrl!.isNotEmpty
          ? NetworkImage(user.profilePicUrl!)
          : null,
      child: user.profilePicUrl == null || user.profilePicUrl!.isEmpty
          ? Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.85,
                color: ThemeColors.primaryColor,
              ),
            )
          : null,
    );
  }

  void _toggleUser(FriendUserSummary user) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(user.id)) {
        _selectedIds.remove(user.id);
        _selectedUsers.remove(user.id);
      } else {
        _selectedIds.add(user.id);
        _selectedUsers[user.id] = user;
      }
    });
  }

  Widget _buildEmptyFriendsState() {
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
              'Add friends to create a group chat',
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

  void _createGroup() {
    final name = _groupNameController.text.trim();
    if (name.isEmpty || _selectedIds.isEmpty) return;

    HapticFeedback.mediumImpact();

    final chat = Chat(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: ChatType.group,
      participantIds: _selectedIds.toList(),
      lastActivity: DateTime.now(),
    );

    ref.read(chatsProvider.notifier).addChat(chat);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
    );
  }
}
