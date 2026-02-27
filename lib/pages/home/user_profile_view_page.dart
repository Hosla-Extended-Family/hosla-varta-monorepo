import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/friend_provider.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/friend_button.dart';
import 'package:hosla/widgets/loading_widget.dart';
import 'package:hosla/widgets/post_card.dart';

/// Modern, redesigned View User Page inspired by Instagram + LinkedIn.
///
/// Layout:
///  1. Gradient header with back button
///  2. Profile card (avatar, name, bio, friend button)
///  3. Stats row (posts · friends · mutual)
///  4. Posts section (grid ↔ list toggle)
class UserProfileViewPage extends ConsumerStatefulWidget {
  final String userId;
  final String? initialName;
  final String? initialAvatarUrl;

  const UserProfileViewPage({
    super.key,
    required this.userId,
    this.initialName,
    this.initialAvatarUrl,
  });

  @override
  ConsumerState<UserProfileViewPage> createState() =>
      _UserProfileViewPageState();
}

class _UserProfileViewPageState extends ConsumerState<UserProfileViewPage> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(
      userProfileVisibilityProvider(widget.userId),
    );
    final currentUser = ref.watch(currentUserProfileProvider);
    final postsAsync = ref.watch(userPostsProvider(widget.userId));
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: profileAsync.when(
        data: (profile) => _buildBody(
          context,
          profile: profile,
          currentUser: currentUser,
          postsAsync: postsAsync,
          friendsAsync: friendsAsync,
        ),
        loading: () =>
            const Center(child: LoadingWidget(message: 'Loading profile...')),
        error: (e, _) => _buildError(context, e),
      ),
    );
  }

  // ── Main body ─────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context, {
    required UserProfileVisibilityResult profile,
    required dynamic currentUser,
    required AsyncValue<List<Post>> postsAsync,
    required AsyncValue<List<FriendshipEdge>> friendsAsync,
  }) {
    final isOwnProfile = currentUser?.id == widget.userId;
    final friendCount = friendsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // ── Gradient header ──
        _buildSliverHeader(context, profile),

        // ── Profile card ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildProfileCard(context, profile, isOwnProfile),
          ),
        ),

        // ── Stats row ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildStatsRow(
              context,
              postsAsync: postsAsync,
              friendCount: friendCount,
            ),
          ),
        ),

        // ── Posts header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Posts',
                  style: TextThemes.getTitleStyle(
                    context,
                  ).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                  icon: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    color: ThemeColors.getSecondaryTextColor(context),
                  ),
                  tooltip: _isGridView ? 'List view' : 'Grid view',
                ),
              ],
            ),
          ),
        ),

        // ── Posts content ──
        _buildPostsSection(context, postsAsync, isOwnProfile),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  // ── Sliver header ─────────────────────────────────────────────

  Widget _buildSliverHeader(
    BuildContext context,
    UserProfileVisibilityResult profile,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: ThemeColors.getNavBarColor(context),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ThemeColors.primaryColor,
                    ThemeColors.primaryColor.withBlue(180),
                    ThemeColors.secondaryColor,
                  ],
                ),
              ),
            ),
            // Pattern overlay
            Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
            // Bottom gradient fade
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Title text
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Text(
                profile.user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Quicksand',
                  letterSpacing: -0.3,
                ),
              ),
            ),
            // Chips row
            Positioned(
              bottom: 32,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  _visibilityChip(profile.visibility),
                  if (profile.role != null) ...[
                    const SizedBox(width: 8),
                    _roleChip(profile.role!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile card ──────────────────────────────────────────────

  Widget _buildProfileCard(
    BuildContext context,
    UserProfileVisibilityResult profile,
    bool isOwnProfile,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColors.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.getOverlayColor(context, opacity: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                _buildAvatar(profile.user.profilePicUrl, 48),
                const SizedBox(width: 16),
                // Name + Bio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.user.name,
                        style: TextThemes.getTitleStyle(
                          context,
                        ).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          profile.bio!,
                          style: TextThemes.getBodyMediumStyle(context)
                              .copyWith(
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ),
                                height: 1.4,
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Friend button
            if (!isOwnProfile) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FriendButton(targetUserId: widget.userId),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────

  Widget _buildStatsRow(
    BuildContext context, {
    required AsyncValue<List<Post>> postsAsync,
    required int friendCount,
  }) {
    final postCount = postsAsync.maybeWhen(
      data: (posts) => posts.length,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColors.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.getOverlayColor(context, opacity: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _statItem(context, count: postCount, label: 'Posts'),
            _statDivider(context),
            _statItem(context, count: friendCount, label: 'Friends'),
            _statDivider(context),
            _statItem(context, count: 0, label: 'Mutual'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    BuildContext context, {
    required int count,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _formatCount(count),
            style: TextThemes.getTitleStyle(
              context,
            ).copyWith(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextThemes.getBodySmallStyle(context).copyWith(
              color: ThemeColors.getSecondaryTextColor(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: ThemeColors.getBorderColor(context).withValues(alpha: 0.2),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  // ── Posts section ─────────────────────────────────────────────

  Widget _buildPostsSection(
    BuildContext context,
    AsyncValue<List<Post>> postsAsync,
    bool isOwnProfile,
  ) {
    return postsAsync.when(
      data: (posts) {
        final visiblePosts = isOwnProfile
            ? posts
            : posts
                  .where((p) => p.visibility.toUpperCase() != 'ONLY_ME')
                  .toList();

        if (visiblePosts.isEmpty) {
          return SliverToBoxAdapter(child: _emptyPostsView(context));
        }

        if (_isGridView) {
          return _buildGridView(context, visiblePosts);
        }
        return _buildListView(context, visiblePosts);
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: LoadingWidget(message: 'Loading posts...')),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Could not load posts',
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<Post> posts) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _gridPostTile(context, posts[index]),
          childCount: posts.length,
        ),
      ),
    );
  }

  Widget _gridPostTile(BuildContext context, Post post) {
    final hasImage =
        post.imageUrl != null &&
        post.imageUrl!.trim().isNotEmpty &&
        Uri.tryParse(post.imageUrl!)?.hasScheme == true;

    return GestureDetector(
      onTap: () => _openPostDetail(context, post),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _gridTextFallback(context, post),
              )
            : _gridTextFallback(context, post),
      ),
    );
  }

  Widget _gridTextFallback(BuildContext context, Post post) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeColors.primaryColor.withValues(alpha: 0.08),
            ThemeColors.secondaryColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        post.content.length > 60
            ? '${post.content.substring(0, 60)}…'
            : post.content,
        style: TextThemes.getBodySmallStyle(context).copyWith(fontSize: 11),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<Post> posts) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: PostCard(post: posts[index]),
        ),
        childCount: posts.length,
      ),
    );
  }

  Widget _emptyPostsView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 56,
            color: ThemeColors.getSecondaryTextColor(
              context,
            ).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No posts yet',
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }

  void _openPostDetail(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeColors.getBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
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
              const SizedBox(height: 8),
              PostCard(post: post),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────

  Widget _buildError(BuildContext context, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: ThemeColors.errorColor,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Profile unavailable',
              style: TextThemes.getTitleStyle(context).copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Widget _buildAvatar(String? url, double radius) {
    final hasUrl = url != null && url.isNotEmpty;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ThemeColors.primaryColor.withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.primaryColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarPlaceholder(radius),
              )
            : _avatarPlaceholder(radius),
      ),
    );
  }

  Widget _avatarPlaceholder(double radius) {
    return Container(
      color: ThemeColors.primaryColor.withValues(alpha: 0.08),
      child: Icon(
        Icons.person_rounded,
        color: ThemeColors.primaryColor,
        size: radius * 1.2,
      ),
    );
  }

  Widget _visibilityChip(String visibility) {
    final isFriendsOnly = visibility.toUpperCase() == 'FRIENDS';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFriendsOnly ? Icons.group_rounded : Icons.public_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isFriendsOnly ? 'Friends only' : 'Public',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'Quicksand',
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            role,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'Quicksand',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle dot pattern painter ────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
