import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';

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

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    final postActions = ref.read(postActionsProvider);

    // Trigger animation
    if (!widget.post.isLiked) {
      _likeController.forward().then((_) => _likeController.reverse());
    }

    await postActions.toggleLike(widget.post);
  }

  void _toggleSave() async {
    final postActions = ref.read(postActionsProvider);
    await postActions.toggleSave(widget.post);
  }

  void _showPostMenu() {
    final currentUser = ref.read(currentUserProfileProvider);
    final isOwner = currentUser?.id == widget.post.userId;

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
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit?.call();
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
              ListTile(
                leading: Icon(
                  widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                ),
                title: Text(widget.post.isSaved ? 'Unsave Post' : 'Save Post'),
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
                  // TODO: Implement share
                },
              ),
              if (!isOwner)
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement report
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final postActions = ref.read(postActionsProvider);
              final success = await postActions.deletePost(widget.post);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Post deleted successfully'
                          : 'Post deleted locally, will sync when online',
                    ),
                  ),
                );
              }
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : ThemeColors.getOverlayColor(context, opacity: 0.08),
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
                // Profile Picture
                ProfilePic(
                  radius: 24,
                  imageUrl: widget.post.userAvatarUrl ?? '',
                ),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userName,
                        style: TextThemes.getTitleStyle(
                          context,
                        ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.post.getRelativeTime(),
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.getSecondaryTextColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                  widget.post.content,
                  style: TextThemes.getBodyMediumStyle(context),
                  maxLines: maxLines,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
                if (widget.post.content.length > 150)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(
                      _isExpanded ? 'Show less' : 'Show more',
                      style: TextStyle(color: ThemeColors.primaryColor),
                    ),
                  ),
              ],
            ),
          ),

          // Image Section
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Tags Section
          if (widget.post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.post.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextThemes.getBodySmallStyle(context).copyWith(
                        color: ThemeColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Like Button
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: IconButton(
                    icon: Icon(
                      widget.post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.post.isLiked ? Colors.red : null,
                    ),
                    onPressed: _toggleLike,
                  ),
                ),
                Text(
                  '${widget.post.likeCount}',
                  style: TextThemes.getBodyMediumStyle(context),
                ),
                const SizedBox(width: 16),
                // Comment Button
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: widget.onComment,
                ),
                Text(
                  '${widget.post.commentCount}',
                  style: TextThemes.getBodyMediumStyle(context),
                ),
                const Spacer(),
                // Save Button
                IconButton(
                  icon: Icon(
                    widget.post.isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: widget.post.isSaved
                        ? ThemeColors.primaryColor
                        : null,
                  ),
                  onPressed: _toggleSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
