import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';

/// Bottom sheet for viewing and adding comments with reply support (Instagram-style)
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
  final FocusNode _focusNode = FocusNode();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  // Reply state
  Comment? _replyingTo;
  String? _replyingToUserName;

  // Track expanded replies for each comment
  final Map<String, bool> _expandedReplies = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    final localRepo = ref.read(localPostRepositoryProvider);
    // Try server first (auth optional), then fall back to local cache.
    try {
      final postService = ref.read(postServiceProvider);
      final serverComments = await postService.getComments(
        postId: widget.post.id,
      );
      for (final c in serverComments) {
        await localRepo.saveComment(c);
      }
    } catch (_) {
      // Ignore network errors; cached comments will still show.
    }

    final comments = await localRepo.getCommentsByPostId(widget.post.id);

    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
      _replyingToUserName = comment.userName;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyingToUserName = null;
    });
  }

  void _toggleReplies(String commentId) {
    setState(() {
      _expandedReplies[commentId] = !(_expandedReplies[commentId] ?? false);
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

    // Format content with reply mention if replying
    String finalContent = content;
    if (_replyingTo != null && _replyingToUserName != null) {
      finalContent = '@$_replyingToUserName $content';
    }

    final success = await postActions.addComment(
      post: widget.post,
      content: finalContent,
      userId: currentUser.id,
      userName: currentUser.name,
      userAvatarUrl: currentUser.avatarUrl,
      parentId: _replyingTo?.id, // Pass parentId for nested replies
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      _commentController.clear();
      _cancelReply();
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

  void _likeComment(Comment comment) {
    // TODO: Implement comment like functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(comment.isLiked ? 'Unliked comment' : 'Liked comment'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeColors.getBorderColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: TextThemes.getTitleStyle(
                    context,
                  ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_comments.length}',
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: ThemeColors.getSecondaryTextColor(context),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: ThemeColors.getBorderColor(context).withOpacity(0.5),
          ),

          // Comments List
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          // Get replies (comments that mention this user)
                          final replies = _comments
                              .where(
                                (c) =>
                                    c.content.startsWith(
                                      '@${comment.userName}',
                                    ) &&
                                    c.id != comment.id &&
                                    c.createdAt.isAfter(comment.createdAt),
                              )
                              .toList();

                          return _CommentTile(
                            comment: comment,
                            replies: replies,
                            isExpanded: _expandedReplies[comment.id] ?? false,
                            onReply: () => _startReply(comment),
                            onLike: () => _likeComment(comment),
                            onToggleReplies: () => _toggleReplies(comment.id),
                            onReplyToReply: _startReply,
                          );
                        },
                      ),
          ),

          // Reply indicator
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withValues(alpha: 0.08),
                border: Border(
                  top: BorderSide(
                    color: ThemeColors.primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.reply_rounded,
                      size: 14,
                      color: ThemeColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextThemes.getBodySmallStyle(context),
                        children: [
                          TextSpan(
                            text: 'Replying to ',
                            style: TextStyle(
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                          ),
                          TextSpan(
                            text: '@$_replyingToUserName',
                            style: TextStyle(
                              color: ThemeColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ThemeColors.getSecondaryTextColor(context).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input Field Container
          Container(
            decoration: BoxDecoration(
              color: ThemeColors.getSurfaceColor(context),
              border: Border(
                top: BorderSide(
                  color: ThemeColors.getBorderColor(context).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Current user avatar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ProfilePic(
                        radius: 16,
                        imageUrl: currentUser?.avatarUrl ?? '',
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Input field
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          maxHeight: 120,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.getBackgroundColor(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          style: TextThemes.getBodyMediumStyle(context),
                          decoration: InputDecoration(
                            hintText: _replyingTo != null
                                ? 'Reply to @$_replyingToUserName...'
                                : 'Add a comment...',
                            hintStyle: TextThemes.getBodyMediumStyle(context).copyWith(
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendComment(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Send button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: GestureDetector(
                        onTap: _isSending ? null : _sendComment,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _isSending
                                ? ThemeColors.primaryColor.withValues(alpha: 0.7)
                                : ThemeColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
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
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: ThemeColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextThemes.getBodyMediumStyle(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextThemes.getBodySmallStyle(context).copyWith(
              color: ThemeColors.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a single comment with reply support
class _CommentTile extends StatelessWidget {
  final Comment comment;
  final List<Comment> replies;
  final bool isExpanded;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onToggleReplies;
  final Function(Comment) onReplyToReply;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.isExpanded,
    required this.onReply,
    required this.onLike,
    required this.onToggleReplies,
    required this.onReplyToReply,
  });

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // Parse content and highlight @mentions
  Widget _buildCommentContent(BuildContext context, String content) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(content);

    if (matches.isEmpty) {
      return Text(
        content,
        style: TextThemes.getBodyMediumStyle(context),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastEnd, match.start),
            style: TextThemes.getBodyMediumStyle(context),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextThemes.getBodyMediumStyle(context).copyWith(
            color: ThemeColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(lastEnd),
          style: TextThemes.getBodyMediumStyle(context),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              ProfilePic(radius: 18, imageUrl: comment.userAvatarUrl ?? ''),
              const SizedBox(width: 12),

              // Comment Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Name & Content
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${comment.userName} ',
                            style: TextThemes.getBodyMediumStyle(
                              context,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildCommentContent(context, comment.content),
                    const SizedBox(height: 8),

                    // Actions row
                    Row(
                      children: [
                        Text(
                          _getRelativeTime(comment.createdAt),
                          style: TextThemes.getBodySmallStyle(context).copyWith(
                            color: ThemeColors.getSecondaryTextColor(context),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Like count
                        if (comment.likeCount > 0) ...[
                          Text(
                            '${comment.likeCount} ${comment.likeCount == 1 ? 'like' : 'likes'}',
                            style: TextThemes.getBodySmallStyle(
                              context,
                            ).copyWith(
                              color:
                                  ThemeColors.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Reply button
                        GestureDetector(
                          onTap: onReply,
                          child: Text(
                            'Reply',
                            style: TextThemes.getBodySmallStyle(
                              context,
                            ).copyWith(
                              color:
                                  ThemeColors.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // Sync status indicator
                        if (comment.syncStatus == SyncStatus.pending) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.orange,
                          ),
                        ] else if (comment.syncStatus == SyncStatus.failed) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Like button
              GestureDetector(
                onTap: onLike,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    comment.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: comment.isLiked
                        ? Colors.red
                        : ThemeColors.getSecondaryTextColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        // View replies button
        if (replies.isNotEmpty && !isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 62, bottom: 8),
            child: GestureDetector(
              onTap: onToggleReplies,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 1,
                    color: ThemeColors.getSecondaryTextColor(
                      context,
                    ).withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View ${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Replies list
        if (replies.isNotEmpty && isExpanded) ...[
          ...replies.map(
            (reply) => _ReplyTile(
              reply: reply,
              onReply: () => onReplyToReply(reply),
              onLike: () {},
            ),
          ),
          // Hide replies button
          Padding(
            padding: const EdgeInsets.only(left: 62, bottom: 8),
            child: GestureDetector(
              onTap: onToggleReplies,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 1,
                    color: ThemeColors.getSecondaryTextColor(
                      context,
                    ).withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hide replies',
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget for displaying a reply (nested comment)
class _ReplyTile extends StatelessWidget {
  final Comment reply;
  final VoidCallback onReply;
  final VoidCallback onLike;

  const _ReplyTile({
    required this.reply,
    required this.onReply,
    required this.onLike,
  });

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildReplyContent(BuildContext context, String content) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(content);

    if (matches.isEmpty) {
      return Text(
        content,
        style: TextThemes.getBodyMediumStyle(context).copyWith(fontSize: 13),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastEnd, match.start),
            style: TextThemes.getBodyMediumStyle(context).copyWith(
              fontSize: 13,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextThemes.getBodyMediumStyle(context).copyWith(
            color: ThemeColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(
        TextSpan(
          text: content.substring(lastEnd),
          style: TextThemes.getBodyMediumStyle(context).copyWith(fontSize: 13),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62, right: 16, top: 4, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Picture (smaller)
          ProfilePic(radius: 14, imageUrl: reply.userAvatarUrl ?? ''),
          const SizedBox(width: 10),

          // Reply Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.userName,
                  style: TextThemes.getBodyMediumStyle(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                _buildReplyContent(context, reply.content),
                const SizedBox(height: 6),

                // Actions row
                Row(
                  children: [
                    Text(
                      _getRelativeTime(reply.createdAt),
                      style: TextThemes.getBodySmallStyle(context).copyWith(
                        color: ThemeColors.getSecondaryTextColor(context),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (reply.likeCount > 0) ...[
                      Text(
                        '${reply.likeCount} ${reply.likeCount == 1 ? 'like' : 'likes'}',
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.getSecondaryTextColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Reply',
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.getSecondaryTextColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Like button
          GestureDetector(
            onTap: onLike,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                reply.isLiked ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: reply.isLiked
                    ? Colors.red
                    : ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
