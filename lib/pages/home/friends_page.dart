import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/pages/home/user_profile_view_page.dart';
import 'package:hosla/providers/friend_provider.dart';
import 'package:hosla/providers/friendship_status_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/providers/user_search_provider.dart';
import 'package:hosla/widgets/friend_button.dart';
import 'package:hosla/widgets/user_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FRIENDS PAGE — Full redesign
//
// UX structure: 3-tab layout
//   1. Discover  — search users with real-time results
//   2. Requests  — incoming/outgoing pending friend requests
//   3. Friends   — accepted friends list
//
// Design tokens:
//   • Quicksand font, primaryColor teal, soft rounded surfaces
//   • Consistent UserCard + FriendButton across all tabs
//   • Empty states, loading skeletons, error recovery
//   • Optimistic UI via friendshipStatusProvider
// ─────────────────────────────────────────────────────────────────────────────

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        ref.read(userSearchProvider.notifier).clear();
      } else {
        ref.read(userSearchProvider.notifier).search(query);
      }
    });
  }

  void _openProfile(String userId, String? name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileViewPage(userId: userId, initialName: name),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    final currentUserId = ref.watch(currentUserProfileProvider)?.id ?? '';
    final incomingCount = requestsAsync.maybeWhen(
      data: (list) => list
          .where((r) => r.receiverId == currentUserId && r.isPending())
          .length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          'Friends',
          style: TextThemes.getTitleStyle(context).copyWith(fontSize: 22),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ThemeColors.primaryColor,
          unselectedLabelColor: ThemeColors.getSecondaryTextColor(context),
          indicatorColor: ThemeColors.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            const Tab(text: 'Discover'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (incomingCount > 0) ...[
                    const SizedBox(width: 6),
                    _badge(incomingCount),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DiscoverTab(
            searchController: _searchController,
            onOpenProfile: _openProfile,
          ),
          _RequestsTab(onOpenProfile: _openProfile),
          _FriendsTab(onOpenProfile: _openProfile),
        ],
      ),
    );
  }

  Widget _badge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: ThemeColors.errorColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 1 — DISCOVER (Search Users)
// ═══════════════════════════════════════════════════════════════════

class _DiscoverTab extends ConsumerWidget {
  final TextEditingController searchController;
  final void Function(String userId, String? name) onOpenProfile;

  const _DiscoverTab({
    required this.searchController,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(userSearchProvider);
    final query = searchController.text.trim();

    return Column(
      children: [
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search people by name...',
              hintStyle: TextThemes.getBodySmallStyle(context).copyWith(
                fontSize: 15,
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                      onPressed: () {
                        searchController.clear();
                        ref.read(userSearchProvider.notifier).clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: ThemeColors.getSurfaceColor(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: ThemeColors.getBorderColor(
                    context,
                  ).withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: ThemeColors.getBorderColor(
                    context,
                  ).withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // ── Results ──
        Expanded(
          child: searchState.when(
            data: (state) {
              if (query.isEmpty) return _emptySearchPrompt(context);
              if (state.users.isEmpty) return _emptyResults(context, query);
              return _buildResultsList(context, ref, state, query);
            },
            loading: () => _searchLoading(context),
            error: (e, _) => _searchError(context, ref, query),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    WidgetRef ref,
    UserSearchState state,
    String query,
  ) {
    return NotificationListener<ScrollNotification>(
      onNotification: (info) {
        if (info.metrics.pixels > info.metrics.maxScrollExtent - 200 &&
            state.hasMore &&
            !state.isLoadingMore) {
          ref.read(userSearchProvider.notifier).loadMore(query);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 80),
        itemCount: state.users.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.users.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ThemeColors.primaryColor,
                  ),
                ),
              ),
            );
          }

          final user = state.users[index];
          return UserCard(
            name: user.name,
            avatarUrl: user.profilePicUrl,
            subtitle: user.bio,
            onTap: () => onOpenProfile(user.id, user.name),
            trailing: FriendButton(targetUserId: user.id, compact: true),
          );
        },
      ),
    );
  }

  // ── Empty / status states ──

  Widget _emptySearchPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: ThemeColors.getSecondaryTextColor(
                context,
              ).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Find people on Hosla',
              style: TextThemes.getBodyLargeStyle(
                context,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by name to discover and connect with friends.',
              textAlign: TextAlign.center,
              style: TextThemes.getBodySmallStyle(context).copyWith(
                fontSize: 14,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyResults(BuildContext context, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: ThemeColors.getSecondaryTextColor(
                context,
              ).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              textAlign: TextAlign.center,
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different name or check the spelling.',
              textAlign: TextAlign.center,
              style: TextThemes.getBodySmallStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchLoading(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (_, __) => _shimmerCard(context),
    );
  }

  Widget _searchError(BuildContext context, WidgetRef ref, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: ThemeColors.errorColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Could not load search results. Please try again.',
              textAlign: TextAlign.center,
              style: TextThemes.getBodySmallStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  ref.read(userSearchProvider.notifier).search(query),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: ThemeColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder shimmer-like card while loading.
  Widget _shimmerCard(BuildContext context) {
    final shimmerColor = ThemeColors.getBorderColor(
      context,
    ).withValues(alpha: 0.15);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: shimmerColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 32,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2 — REQUESTS (Pending Incoming / Outgoing)
// ═══════════════════════════════════════════════════════════════════

class _RequestsTab extends ConsumerWidget {
  final void Function(String userId, String? name) onOpenProfile;

  const _RequestsTab({required this.onOpenProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    final currentUserId = ref.watch(currentUserProfileProvider)?.id ?? '';

    return RefreshIndicator(
      color: ThemeColors.primaryColor,
      backgroundColor: ThemeColors.getSurfaceColor(context),
      onRefresh: () => ref.read(friendRequestsProvider.notifier).refresh(),
      child: requestsAsync.when(
        data: (requests) {
          final incoming = requests
              .where((r) => r.receiverId == currentUserId && r.isPending())
              .toList();
          final outgoing = requests
              .where((r) => r.requesterId == currentUserId && r.isPending())
              .toList();

          if (incoming.isEmpty && outgoing.isEmpty) {
            return _emptyRequests(context);
          }

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            children: [
              if (incoming.isNotEmpty) ...[
                _sectionHeader(context, 'Incoming', incoming.length),
                ...incoming.map(
                  (edge) => _requestCard(
                    context,
                    ref,
                    edge,
                    currentUserId,
                    isIncoming: true,
                  ),
                ),
              ],
              if (outgoing.isNotEmpty) ...[
                if (incoming.isNotEmpty) const SizedBox(height: 8),
                _sectionHeader(context, 'Sent', outgoing.length),
                ...outgoing.map(
                  (edge) => _requestCard(
                    context,
                    ref,
                    edge,
                    currentUserId,
                    isIncoming: false,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: ThemeColors.primaryColor),
        ),
        error: (e, _) => _errorState(context, ref),
      ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    WidgetRef ref,
    FriendshipEdge edge,
    String currentUserId, {
    required bool isIncoming,
  }) {
    final other = edge.otherParty(currentUserId);
    final userId = other?.id ?? '';

    return UserCard(
      name: other?.name ?? 'Unknown',
      avatarUrl: other?.profilePicUrl,
      subtitle: isIncoming ? 'Wants to be friends' : 'Request sent',
      onTap: userId.isNotEmpty
          ? () => onOpenProfile(userId, other?.name)
          : null,
      trailing: isIncoming
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circleAction(
                  context,
                  icon: Icons.close_rounded,
                  color: ThemeColors.getSecondaryTextColor(context),
                  bgColor: ThemeColors.getBorderColor(
                    context,
                  ).withValues(alpha: 0.12),
                  onTap: () => ref
                      .read(friendshipStatusProvider(userId).notifier)
                      .rejectRequest(),
                ),
                const SizedBox(width: 8),
                _circleAction(
                  context,
                  icon: Icons.check_rounded,
                  color: Colors.white,
                  bgColor: ThemeColors.primaryColor,
                  onTap: () => ref
                      .read(friendshipStatusProvider(userId).notifier)
                      .acceptRequest(),
                ),
              ],
            )
          : Text(
              'Pending',
              style: TextThemes.getBodySmallStyle(context).copyWith(
                color: ThemeColors.getSecondaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  Widget _circleAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextThemes.getBodySmallStyle(context).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.8,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: ThemeColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ThemeColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRequests(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    size: 64,
                    color: ThemeColors.getSecondaryTextColor(
                      context,
                    ).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextThemes.getBodyLargeStyle(
                      context,
                    ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When someone sends you a friend request, it will appear here.',
                    textAlign: TextAlign.center,
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      fontSize: 14,
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: ThemeColors.errorColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load requests',
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  ref.read(friendRequestsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: ThemeColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 3 — FRIENDS LIST
// ═══════════════════════════════════════════════════════════════════

class _FriendsTab extends ConsumerStatefulWidget {
  final void Function(String userId, String? name) onOpenProfile;

  const _FriendsTab({required this.onOpenProfile});

  @override
  ConsumerState<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<_FriendsTab> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final currentUserId = ref.watch(currentUserProfileProvider)?.id ?? '';

    return RefreshIndicator(
      color: ThemeColors.primaryColor,
      backgroundColor: ThemeColors.getSurfaceColor(context),
      onRefresh: () => ref.read(friendsListProvider.notifier).refresh(),
      child: friendsAsync.when(
        data: (friends) {
          if (friends.isEmpty) return _emptyFriends(context);
          return _buildFriendsList(context, friends, currentUserId);
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: ThemeColors.primaryColor),
        ),
        error: (e, _) => _errorState(context),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    List<FriendshipEdge> friends,
    String currentUserId,
  ) {
    final filtered = _filter.isEmpty
        ? friends
        : friends.where((edge) {
            final other = edge.otherParty(currentUserId);
            return other?.name.toLowerCase().contains(_filter.toLowerCase()) ??
                false;
          }).toList();

    return Column(
      children: [
        // ── Filter bar (shows when > 5 friends) ──
        if (friends.length > 5)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _filter = v),
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Filter friends...',
                hintStyle: TextThemes.getBodySmallStyle(context).copyWith(
                  fontSize: 14,
                  color: ThemeColors.getSecondaryTextColor(
                    context,
                  ).withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.filter_list_rounded,
                  size: 20,
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
                isDense: true,
                filled: true,
                fillColor: ThemeColors.getSurfaceColor(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeColors.getBorderColor(
                      context,
                    ).withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeColors.getBorderColor(
                      context,
                    ).withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: ThemeColors.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),

        // ── Count label ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${filtered.length} friend${filtered.length == 1 ? '' : 's'}',
              style: TextThemes.getBodySmallStyle(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.5,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ),
        ),

        // ── List ──
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No matches',
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final edge = filtered[index];
                    final other = edge.otherParty(currentUserId);
                    final userId = other?.id ?? '';

                    return UserCard(
                      name: other?.name ?? 'Friend',
                      avatarUrl: other?.profilePicUrl,
                      onTap: userId.isNotEmpty
                          ? () => widget.onOpenProfile(userId, other?.name)
                          : null,
                      trailing: _friendOptions(context, edge, userId),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _friendOptions(
    BuildContext context,
    FriendshipEdge edge,
    String userId,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showRemoveSheet(context, edge, userId),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 22,
            color: ThemeColors.getSecondaryTextColor(context),
          ),
        ),
      ),
    );
  }

  void _showRemoveSheet(
    BuildContext context,
    FriendshipEdge edge,
    String userId,
  ) {
    final other = edge.otherParty(
      ref.read(currentUserProfileProvider)?.id ?? '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeColors.getBorderColor(
                  context,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 28,
              backgroundColor: ThemeColors.primaryColor.withValues(alpha: 0.12),
              backgroundImage: other?.profilePicUrl != null
                  ? NetworkImage(
                      ApiConstants.resolveUrl(other!.profilePicUrl!) ?? '',
                    )
                  : null,
              child: other?.profilePicUrl == null
                  ? Text(
                      (other?.name ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: ThemeColors.primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              other?.name ?? 'Friend',
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.person_remove_alt_1_rounded,
                color: ThemeColors.errorColor,
              ),
              title: Text(
                'Remove Friend',
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  color: ThemeColors.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'They won\'t be notified.',
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  fontSize: 12,
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemove(
                  context,
                  edge,
                  userId,
                  other?.name ?? 'this friend',
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    FriendshipEdge edge,
    String userId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeColors.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove $name?',
          style: TextThemes.getBodyMediumStyle(
            context,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'They will be removed from your friends list.',
          style: TextThemes.getBodySmallStyle(
            context,
          ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w600,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(friendshipStatusProvider(userId).notifier)
                  .removeFriend();
            },
            child: Text(
              'Remove',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                color: ThemeColors.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyFriends(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: ThemeColors.getSecondaryTextColor(
                      context,
                    ).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: TextThemes.getBodyLargeStyle(
                      context,
                    ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Head over to the Discover tab to search and add new friends!',
                    textAlign: TextAlign.center,
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      fontSize: 14,
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: ThemeColors.errorColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load friends',
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.read(friendsListProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: ThemeColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
