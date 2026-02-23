import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/pages/home/edit_post_page.dart';
import 'package:hosla/pages/home/user_profile_view_page.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/comments_bottom_sheet.dart';
import 'package:hosla/widgets/profile_pic.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';
import 'package:share_plus/share_plus.dart';

/// Enhanced post card widget with actions (like, save, comment, edit, delete)
class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onComment;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onComment,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _likeController;
  late Animation<double> _scaleAnimation;
  late Post _post;

  bool _hasValidImage(String? url) {
    if (url == null) return false;
    final u = url.trim();
    if (u.isEmpty) return false;
    final parsed = Uri.tryParse(u);
    return parsed != null && parsed.hasScheme;
  }

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = widget.post;
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    final postActions = ref.read(postActionsProvider);

    final current = _post;
    final nextLiked = !current.isLiked;
    final nextCount = nextLiked
        ? current.likeCount + 1
        : (current.likeCount - 1 < 0 ? 0 : current.likeCount - 1);

    // Local optimistic UI
    setState(() {
      _post = current.copyWith(isLiked: nextLiked, likeCount: nextCount);
    });

    // Trigger animation
    if (!current.isLiked) {
      _likeController.forward().then((_) => _likeController.reverse());
    }

    await postActions.toggleLike(current);

    // Refresh from local DB (authoritative offline cache)
    try {
      final localRepo = ref.read(localPostRepositoryProvider);
      final latest = await localRepo.getPostById(current.id);
      if (!mounted) return;
      if (latest != null) {
        setState(() => _post = latest);
      }
    } catch (_) {}
  }

  void _toggleSave() async {
    final currentUser = ref.read(currentUserProfileProvider);

    // Prevent saving own post
    if (currentUser != null && currentUser.id == _post.userId) {
      if (!mounted) return;
      SnackBarWidget.warning(context, 'You cannot save your own post');
      return;
    }

    final postActions = ref.read(postActionsProvider);
    final wasSaved = _post.isSaved;

    await postActions.toggleSave(_post);

    // Refresh from local DB to get updated state
    try {
      final localRepo = ref.read(localPostRepositoryProvider);
      final latest = await localRepo.getPostById(_post.id);
      if (!mounted) return;
      if (latest != null) {
        setState(() => _post = latest);
      }
    } catch (_) {}

    // Show snackbar feedback using SnackBarWidget
    if (!mounted) return;
    if (wasSaved) {
      SnackBarWidget.success(context, 'Post unsaved');
    } else {
      SnackBarWidget.success(context, 'Post saved');
    }
  }

  Future<void> _openComments() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(post: _post),
    );

    // After closing, refresh post (commentCount might have changed)
    try {
      final localRepo = ref.read(localPostRepositoryProvider);
      final latest = await localRepo.getPostById(_post.id);
      if (!mounted) return;
      if (latest != null) {
        setState(() => _post = latest);
      }
    } catch (_) {}
  }

  void _sharePost() {
    final content = _post.content.trim();
    final imageUrl = _hasValidImage(_post.imageUrl) ? _post.imageUrl : null;
    final pieces = [
      if (content.isNotEmpty) content,
      if (imageUrl != null) imageUrl,
    ];
    if (pieces.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Nothing to share for this post')),
      );
      return;
    }
    final text = pieces.join('\n');
    Share.share(text, subject: 'Post by ${_post.userName}');
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileViewPage(
          userId: _post.userId,
          initialName: _post.userName,
          initialAvatarUrl: _post.userAvatarUrl,
        ),
      ),
    );
  }

  void _showPostMenu() {
    final currentUser = ref.read(currentUserProfileProvider);
    final isOwner = currentUser?.id == _post.userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Post'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (widget.onEdit != null) {
                      widget.onEdit!.call();
                      return;
                    }

                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPostPage(post: _post),
                      ),
                    );

                    if (changed == true) {
                      // Refresh from local DB to reflect latest cached post.
                      try {
                        final localRepo = ref.read(localPostRepositoryProvider);
                        final latest = await localRepo.getPostById(_post.id);
                        if (!mounted) return;
                        if (latest != null) {
                          setState(() => _post = latest);
                        }
                      } catch (_) {}
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    _post.visibility.toUpperCase() == 'ONLY_ME'
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  title: Text(
                    _post.visibility.toUpperCase() == 'ONLY_ME'
                        ? 'Reshow Post'
                        : 'Hide from Profile',
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final postActions = ref.read(postActionsProvider);
                    final target = _post.visibility.toUpperCase() == 'ONLY_ME'
                        ? 'PUBLIC'
                        : 'ONLY_ME';
                    final messenger = ScaffoldMessenger.of(context);

                    final ok = await postActions.setVisibility(_post, target);

                    if (!mounted) return;
                    if (ok) {
                      setState(() {
                        _post = _post.copyWith(visibility: target);
                      });
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            target == 'PUBLIC'
                                ? 'Post is visible again'
                                : 'Post hidden from feed/profile',
                          ),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Could not update visibility'),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation();
                  },
                ),
              ],
              if (!isOwner)
                ListTile(
                  leading: Icon(
                    _post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  title: Text(_post.isSaved ? 'Unsave Post' : 'Save Post'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleSave();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePost();
                },
              ),
              if (!isOwner)
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context);
                    final messenger = ScaffoldMessenger.of(context);
                    ref
                        .read(postServiceProvider)
                        .reportPost(postId: _post.id, reason: 'SPAM')
                        .then((_) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Reported. Thanks for letting us know.',
                              ),
                            ),
                          );
                        })
                        .catchError((_) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to report. Please try again.',
                              ),
                            ),
                          );
                        });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final postActions = ref.read(postActionsProvider);
              final messenger = ScaffoldMessenger.of(parentContext);
              final success = await postActions.deletePost(widget.post);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Post deleted successfully'
                        : 'Post deleted locally, will sync when online',
                  ),
                ),
              );
              widget.onDelete?.call();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxLines = _isExpanded ? null : 3;

    // Check if post has emergency tag (case insensitive)
    final hasEmergencyTag = _post.tags.any(
      (tag) => tag.toLowerCase() == 'emergency',
    );

    // Filter out 'default' tag (case insensitive)
    final displayTags = _post.tags
        .where((tag) => tag.toLowerCase() != 'default')
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasEmergencyTag
            ? ThemeColors.getCardColor(context)
            : ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasEmergencyTag
              ? Colors.red.shade400
              : ThemeColors.getBorderColor(context).withValues(alpha: 0.1),
          width: hasEmergencyTag ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasEmergencyTag
                ? Colors.red.withValues(alpha: 0.3)
                : (isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : ThemeColors.getOverlayColor(context, opacity: 0.08)),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _openProfile,
                    borderRadius: BorderRadius.circular(32),
                    child: Row(
                      children: [
                        // Profile Picture
                        ProfilePic(
                          radius: 24,
                          imageUrl: _post.userAvatarUrl ?? '',
                        ),
                        const SizedBox(width: 12),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _post.userName,
                                style: TextThemes.getTitleStyle(context)
                                    .copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _post.getRelativeTime(),
                                style: TextThemes.getBodySmallStyle(context)
                                    .copyWith(
                                      color: ThemeColors.getSecondaryTextColor(
                                        context,
                                      ),
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Three-dot menu
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showPostMenu,
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.content,
                  style: TextThemes.getBodyMediumStyle(context),
                  maxLines: maxLines,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
                if (_post.content.length > 150)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(
                      _isExpanded ? 'show less' : 'read more',
                      style: TextStyle(
                        color: ThemeColors.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tags Section
          if (displayTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayTags.map((tag) {
                  final normalized = tag.trim();
                  final plain = normalized.startsWith('#')
                      ? normalized.substring(1).trim()
                      : normalized;
                  final isEmergency = plain.toLowerCase() == 'emergency';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? Colors.red.withValues(alpha: 0.2)
                          : ThemeColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: isEmergency
                          ? Border.all(color: Colors.red, width: 1)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isEmergency)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            '#$plain',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextThemes.getBodySmallStyle(context)
                                .copyWith(
                                  color: isEmergency
                                      ? Colors.red
                                      : ThemeColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Image Section: only show if valid URL exists, hide if no image
          if (_hasValidImage(_post.imageUrl))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // If loading fails, hide the image section
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),

          // Stats row: likes and comments
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Text(
                  '${_post.likeCount} likes',
                  style: TextThemes.getBodySmallStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_post.commentCount} comments',
                  style: TextThemes.getBodySmallStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                ),
              ],
            ),
          ),
          // Divider before actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              height: 1,
              color: ThemeColors.getBorderColor(context).withValues(alpha: 0.2),
            ),
          ),
          // Actions row: Like, Comment, Share (evenly spaced, with labels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _toggleLike,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Icon(
                                _post.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _post.isLiked
                                    ? Colors.red
                                    : ThemeColors.getSecondaryTextColor(
                                        context,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Like',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextThemes.getBodyMediumStyle(context)
                                    .copyWith(
                                      color: ThemeColors.getSecondaryTextColor(
                                        context,
                                      ),
                                      fontSize: 14,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: widget.onComment ?? _openComments,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Comment',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextThemes.getBodyMediumStyle(context)
                                    .copyWith(
                                      color: ThemeColors.getSecondaryTextColor(
                                        context,
                                      ),
                                      fontSize: 14,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _sharePost,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.share,
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Share',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextThemes.getBodyMediumStyle(context)
                                    .copyWith(
                                      color: ThemeColors.getSecondaryTextColor(
                                        context,
                                      ),
                                      fontSize: 14,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
