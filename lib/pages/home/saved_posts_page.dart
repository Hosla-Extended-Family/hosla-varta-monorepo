import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/pages/home/edit_post_page.dart';
import 'package:hosla/widgets/post_card.dart';
import 'package:hosla/widgets/comments_bottom_sheet.dart';
import 'package:hosla/widgets/loading_widget.dart';

/// Page for viewing saved posts with enhanced UI
class SavedPostsPage extends ConsumerStatefulWidget {
  const SavedPostsPage({super.key});

  @override
  ConsumerState<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends ConsumerState<SavedPostsPage> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final savedPostsAsyncValue = ref.watch(savedPostsProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 180,
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
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Toggle view button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background - using warm colors for saved/bookmarks
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeColors.warningColor,
                          ThemeColors.warningColor.withRed(220),
                          ThemeColors.primaryColor,
                        ],
                      ),
                    ),
                  ),
                  // Pattern overlay
                  Positioned.fill(
                    child: CustomPaint(painter: _PatternPainter()),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.bookmark_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saved Posts',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Quicksand',
                                    ),
                                  ),
                                  savedPostsAsyncValue.when(
                                    data: (posts) => Text(
                                      '${posts.length} ${posts.length == 1 ? 'post' : 'posts'} saved',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 14,
                                        fontFamily: 'Quicksand',
                                      ),
                                    ),
                                    loading: () => Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 14,
                                        fontFamily: 'Quicksand',
                                      ),
                                    ),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                ],
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

          // Content
          savedPostsAsyncValue.when(
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(context));
              }

              if (_isGridView) {
                return SliverPadding(
                  padding: const EdgeInsets.all(2),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildGridItem(context, posts[index], posts, index),
                      childCount: posts.length,
                    ),
                  ),
                );
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = posts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: PostCard(
                        post: post,
                        onEdit: () => _showEditDialog(context, post),
                        onComment: () => _showComments(context, post),
                      ),
                    );
                  }, childCount: posts.length),
                );
              }
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: LoadingWidget(message: 'Loading saved posts...'),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: _buildErrorState(context, error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    Post post,
    List<Post> allPosts,
    int index,
  ) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showPostDetail(context, allPosts, index),
      child: Container(
        decoration: BoxDecoration(color: ThemeColors.getSurfaceColor(context)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildTextPreview(context, post);
                },
              )
            else
              _buildTextPreview(context, post),
            // Bookmark indicator
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ThemeColors.warningColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
            // Stats overlay
            if (post.likeCount > 0)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${post.likeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPreview(BuildContext context, Post post) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeColors.warningColor.withValues(alpha: 0.1),
            ThemeColors.primaryColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          post.content.length > 50
              ? '${post.content.substring(0, 50)}...'
              : post.content,
          style: TextThemes.getBodySmallStyle(context).copyWith(fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
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
              color: ThemeColors.warningColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_outline_rounded,
              size: 64,
              color: ThemeColors.warningColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Posts',
            style: TextThemes.getTitleStyle(
              context,
            ).copyWith(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Posts you save will appear here. Tap the bookmark icon on any post to save it for later.',
              textAlign: TextAlign.center,
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Explore Posts'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ThemeColors.primaryColor,
              side: BorderSide(color: ThemeColors.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeColors.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: ThemeColors.errorColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Oops! Something went wrong',
            style: TextThemes.getTitleStyle(
              context,
            ).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'We couldn\'t load your saved posts. Please try again.',
              textAlign: TextAlign.center,
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(savedPostsProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDetail(
    BuildContext context,
    List<Post> posts,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _PostDetailView(posts: posts, initialIndex: initialIndex),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Post post) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditPostPage(post: post)),
    );
  }

  void _showComments(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: post),
    );
  }
}

/// Full-screen post detail view with swipe navigation
class _PostDetailView extends ConsumerWidget {
  final List<Post> posts;
  final int initialIndex;

  const _PostDetailView({required this.posts, required this.initialIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Saved Posts', style: TextThemes.getTitleStyle(context)),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            child: PostCard(
              post: posts[index],
              onComment: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentsBottomSheet(post: posts[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Pattern painter for header background
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const spacing = 25.0;
    const radius = 3.0;

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
