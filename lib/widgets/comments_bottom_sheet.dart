import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';

/// Bottom sheet for viewing and adding comments
class CommentsBottomSheet extends ConsumerStatefulWidget {
  final Post post;

  const CommentsBottomSheet({super.key, required this.post});

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    final localRepo = ref.read(localPostRepositoryProvider);
    final comments = await localRepo.getCommentsByPostId(widget.post.id);

    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final currentUser = ref.read(currentUserProfileProvider);
    if (currentUser == null) return;

    setState(() {
      _isSending = true;
    });

    final postActions = ref.read(postActionsProvider);
    final success = await postActions.addComment(
      post: widget.post,
      content: content,
      userId: currentUser.id,
      userName: currentUser.name,
      userAvatarUrl: currentUser.avatarUrl,
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      _commentController.clear();
      await _loadComments();
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Comments (${_comments.length})',
                  style: TextThemes.getTitleStyle(
                    context,
                  ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 64,
                    color: ThemeColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No comments yet',
                    style: TextThemes.getBodyMediumStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to comment!',
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return _CommentTile(comment: comment);
                },
              ),
            ),

          const Divider(height: 1),

          // Input Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send, color: ThemeColors.primaryColor),
                  onPressed: _isSending ? null : _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a single comment
class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

  String _getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(comment.createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture
          ProfilePic(radius: 20, imageUrl: comment.userAvatarUrl ?? ''),
          const SizedBox(width: 12),
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Name & Time
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: TextThemes.getBodyMediumStyle(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getRelativeTime(),
                      style: TextThemes.getBodySmallStyle(context).copyWith(
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                    ),
                    const Spacer(),
                    // Sync status indicator
                    if (comment.syncStatus == SyncStatus.pending)
                      Icon(Icons.schedule, size: 16, color: Colors.orange)
                    else if (comment.syncStatus == SyncStatus.failed)
                      Icon(Icons.error_outline, size: 16, color: Colors.red),
                  ],
                ),
                const SizedBox(height: 4),
                // Comment Text
                Text(
                  comment.content,
                  style: TextThemes.getBodyMediumStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
