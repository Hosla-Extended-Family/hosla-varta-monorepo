import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/services/post_service.dart';
import 'package:hosla/widgets/profile_pic.dart';

/// Bottom sheet for viewing and adding comments with threaded reply support.
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

  /// All comments (flat list – server tree is flattened for local storage).
  List<Comment> _comments = [];

  bool _isLoading = true;
  bool _isSending = false;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _totalComments = 0;

  // Reply state
  Comment? _replyingTo;
  String? _replyingToUserName;

  // Track expanded replies per top-level comment id
  final Map<String, bool> _expandedReplies = {};

  // ------- Helpers -------

  List<Comment> get _topLevelComments => _comments
      .where((c) => c.parentId == null || c.parentId!.isEmpty)
      .toList();

  List<Comment> _repliesFor(String parentId) =>
      _comments.where((c) => c.parentId == parentId).toList();

  // ------- Lifecycle -------

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMoreComments();
    }
  }

  // ------- Data loading -------

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    _currentPage = 1;
    final localRepo = ref.read(localPostRepositoryProvider);

    try {
      final postService = ref.read(postServiceProvider);
      final resp = await postService.getComments(
        postId: widget.post.id,
        page: 1,
        limit: 20,
      );

      // Flatten tree (server may include nested replies) and persist
      final flat = PostService.flattenComments(resp.comments);
      for (final c in flat) {
        await localRepo.saveComment(c);
      }

      _hasMore = resp.hasMore;
      _totalComments = resp.totalComments;
      _currentPage = 1;
    } catch (_) {
      // Offline – use local cache
    }

    final comments = await localRepo.getCommentsByPostId(widget.post.id);

    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final postService = ref.read(postServiceProvider);
      final resp = await postService.getComments(
        postId: widget.post.id,
        page: _currentPage + 1,
        limit: 20,
      );

      final localRepo = ref.read(localPostRepositoryProvider);
      final flat = PostService.flattenComments(resp.comments);
      for (final c in flat) {
        await localRepo.saveComment(c);
      }

      _currentPage += 1;
      _hasMore = resp.hasMore;
      _totalComments = resp.totalComments;

      // Merge new comments avoiding duplicates
      final existingIds = _comments.map((c) => c.id).toSet();
      final newComments = flat
          .where((c) => !existingIds.contains(c.id))
          .toList();

      setState(() {
        _comments.addAll(newComments);
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // ------- Actions -------

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

    // If replying, prepend @mention and pass parentId
    String finalContent = content;
    if (_replyingTo != null && _replyingToUserName != null) {
      finalContent = '@[${_replyingToUserName}] $content';
    }

    final success = await postActions.addComment(
      post: widget.post,
      content: finalContent,
      userId: currentUser.id,
      userName: currentUser.name,
      userAvatarUrl: currentUser.avatarUrl,
      parentId: _replyingTo?.id,
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      _commentController.clear();
      _cancelReply();
      await _loadComments();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _likeComment(Comment comment) async {
    final currentUser = ref.read(currentUserProfileProvider);
    if (currentUser == null) return; // anonymous – no action

    final updatedComment = comment.copyWith(
      isLiked: !comment.isLiked,
      likeCount: comment.isLiked
          ? (comment.likeCount > 0 ? comment.likeCount - 1 : 0)
          : comment.likeCount + 1,
    );

    setState(() {
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) _comments[index] = updatedComment;
    });

    try {
      final postService = ref.read(postServiceProvider);
      final result = updatedComment.isLiked
          ? await postService.likeComment(commentId: comment.id)
          : await postService.unlikeComment(commentId: comment.id);

      if (result['success'] != true) {
        _revertLike(comment);
      }
    } catch (_) {
      _revertLike(comment);
    }
  }

  void _revertLike(Comment original) {
    setState(() {
      final index = _comments.indexWhere((c) => c.id == original.id);
      if (index != -1) _comments[index] = original;
    });
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final postActions = ref.read(postActionsProvider);
    final success = await postActions.deleteComment(
      post: widget.post,
      comment: comment,
    );

    if (success && mounted) {
      await _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      }
    }
  }

  static const List<({String value, String label, IconData icon})>
  _reportReasons = [
    (value: 'ABUS', label: 'Abusive', icon: Icons.gavel),
    (value: 'SPAM', label: 'Spam', icon: Icons.report_gmailerrorred),
    (value: 'OTHER', label: 'Other', icon: Icons.more_horiz),
  ];

  Future<void> _reportPost() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Report Post',
                    style: TextThemes.getBodyLargeStyle(
                      ctx,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ..._reportReasons.map(
              (r) => ListTile(
                leading: Icon(r.icon, size: 20),
                title: Text(r.label),
                onTap: () => Navigator.pop(ctx, r.value),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (reason == null || !mounted) return;

    final postActions = ref.read(postActionsProvider);
    final success = await postActions.reportPost(
      postId: widget.post.id,
      reason: reason,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Post reported' : 'Failed to report')),
      );
    }
  }

  void _showCommentActions(Comment comment) {
    final currentUser = ref.read(currentUserProfileProvider);
    if (currentUser == null) return; // anonymous

    final isOwn = comment.userId == currentUser.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwn)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Comment',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteComment(comment);
                },
              ),
            if (!isOwn)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report Post'),
                onTap: () {
                  Navigator.pop(ctx);
                  _reportPost();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // ------- Build -------

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);
    final isAuthenticated = currentUser != null;

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
          _buildHeader(context),

          Divider(
            height: 1,
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.5),
          ),

          // Comments list
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
                : _buildCommentsList(),
          ),

          // Reply indicator
          if (_replyingTo != null) _buildReplyIndicator(context),

          // Input (only for authenticated users)
          if (isAuthenticated) _buildInputField(context, currentUser),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayCount = _totalComments > 0 ? _totalComments : _comments.length;
    return Padding(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ThemeColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$displayCount',
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
    );
  }

  Widget _buildCommentsList() {
    final currentUser = ref.read(currentUserProfileProvider);
    final topLevel = _topLevelComments;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: topLevel.length + (_isLoadingMore || _hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= topLevel.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const SizedBox.shrink();
        }

        final comment = topLevel[index];
        final replies = _repliesFor(comment.id);
        final isExpanded = _expandedReplies[comment.id] ?? false;

        return _CommentThread(
          comment: comment,
          replies: replies,
          isExpanded: isExpanded,
          currentUserId: currentUser?.id,
          onReply: () => _startReply(comment),
          onLike: () => _likeComment(comment),
          onLikeReply: _likeComment,
          onToggleReplies: () => _toggleReplies(comment.id),
          onReplyToReply: _startReply,
          onLongPress: () => _showCommentActions(comment),
          onReplyLongPress: _showCommentActions,
          onDelete: _deleteComment,
        );
      },
    );
  }

  Widget _buildReplyIndicator(BuildContext context) {
    return Container(
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
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.1),
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
    );
  }

  Widget _buildInputField(BuildContext context, dynamic currentUser) {
    return Container(
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
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ProfilePic(
                  radius: 16,
                  imageUrl: currentUser?.avatarUrl ?? '',
                  name: currentUser?.name,
                ),
              ),
              const SizedBox(width: 10),
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
                      color: ThemeColors.getBorderColor(
                        context,
                      ).withValues(alpha: 0.4),
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
                      hintStyle: TextThemes.getBodyMediumStyle(context)
                          .copyWith(
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
              color: ThemeColors.primaryColor.withValues(alpha: 0.1),
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
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextThemes.getBodySmallStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
//  Thread: top-level comment + its replies
// ──────────────────────────────────────────────────────

class _CommentThread extends StatelessWidget {
  final Comment comment;
  final List<Comment> replies;
  final bool isExpanded;
  final String? currentUserId;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final void Function(Comment) onLikeReply;
  final VoidCallback onToggleReplies;
  final void Function(Comment) onReplyToReply;
  final VoidCallback onLongPress;
  final void Function(Comment) onReplyLongPress;
  final void Function(Comment) onDelete;

  const _CommentThread({
    required this.comment,
    required this.replies,
    required this.isExpanded,
    this.currentUserId,
    required this.onReply,
    required this.onLike,
    required this.onLikeReply,
    required this.onToggleReplies,
    required this.onReplyToReply,
    required this.onLongPress,
    required this.onReplyLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        _CommentRow(
          comment: comment,
          isReply: false,
          currentUserId: currentUserId,
          onReply: onReply,
          onLike: onLike,
          onLongPress: onLongPress,
          onDelete: () => onDelete(comment),
        ),

        // "View N replies" toggle
        if (replies.isNotEmpty && !isExpanded)
          _ViewRepliesToggle(
            count: replies.length,
            isExpanded: false,
            onTap: onToggleReplies,
          ),

        // Expanded replies
        if (replies.isNotEmpty && isExpanded) ...[
          _RepliesList(
            replies: replies,
            currentUserId: currentUserId,
            onReplyToReply: onReplyToReply,
            onLikeReply: onLikeReply,
            onLongPress: onReplyLongPress,
            onDelete: onDelete,
          ),
          _ViewRepliesToggle(
            count: replies.length,
            isExpanded: true,
            onTap: onToggleReplies,
          ),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────
//  Toggle button: "View N replies" / "Hide replies"
// ──────────────────────────────────────────────────────

class _ViewRepliesToggle extends StatelessWidget {
  final int count;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ViewRepliesToggle({
    required this.count,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 24,
              height: 1,
              color: ThemeColors.getSecondaryTextColor(
                context,
              ).withValues(alpha: 0.3),
            ),
            const SizedBox(width: 8),
            Text(
              isExpanded
                  ? 'Hide replies'
                  : 'View $count ${count == 1 ? 'reply' : 'replies'}',
              style: TextThemes.getBodySmallStyle(context).copyWith(
                color: ThemeColors.getSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
//  Replies list (with vertical connector line)
// ──────────────────────────────────────────────────────

class _RepliesList extends StatelessWidget {
  final List<Comment> replies;
  final String? currentUserId;
  final void Function(Comment) onReplyToReply;
  final void Function(Comment) onLikeReply;
  final void Function(Comment) onLongPress;
  final void Function(Comment) onDelete;

  const _RepliesList({
    required this.replies,
    this.currentUserId,
    required this.onReplyToReply,
    required this.onLikeReply,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 34),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vertical connector line
            Container(
              width: 2,
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                color: ThemeColors.getBorderColor(
                  context,
                ).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            // Reply items
            Expanded(
              child: Column(
                children: replies
                    .map(
                      (reply) => _CommentRow(
                        comment: reply,
                        isReply: true,
                        currentUserId: currentUserId,
                        onReply: () => onReplyToReply(reply),
                        onLike: () => onLikeReply(reply),
                        onLongPress: () => onLongPress(reply),
                        onDelete: () => onDelete(reply),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
//  Single comment row (used for both parent & reply)
// ──────────────────────────────────────────────────────

class _CommentRow extends StatelessWidget {
  final Comment comment;
  final bool isReply;
  final String? currentUserId;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _CommentRow({
    required this.comment,
    required this.isReply,
    this.currentUserId,
    required this.onReply,
    required this.onLike,
    required this.onLongPress,
    required this.onDelete,
  });

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 7) return '${difference.inDays ~/ 7}w';
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final avatarRadius = isReply ? 14.0 : 18.0;
    final padding = isReply
        ? const EdgeInsets.only(left: 12, right: 16, top: 4, bottom: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return GestureDetector(
      onLongPress: comment.isDeleted ? null : onLongPress,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfilePic(
              radius: avatarRadius,
              imageUrl: comment.isDeleted ? '' : (comment.userAvatarUrl ?? ''),
              name: comment.isDeleted ? null : comment.userName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: comment.isDeleted
                  ? _buildDeletedContent(context)
                  : _buildActiveContent(context),
            ),
            if (!comment.isDeleted) ...[
              GestureDetector(
                onTap: onLike,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Icon(
                      comment.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: comment.isLiked
                          ? Colors.red
                          : ThemeColors.getSecondaryTextColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedContent(BuildContext context) {
    final style = TextThemes.getBodyMediumStyle(context).copyWith(
      fontStyle: FontStyle.italic,
      color: ThemeColors.getSecondaryTextColor(context),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('This comment was deleted', style: style),
    );
  }

  Widget _buildActiveContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comment.userName,
          style: TextThemes.getBodyMediumStyle(
            context,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        _MentionText(text: comment.content),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _getRelativeTime(comment.createdAt),
              style: TextThemes.getBodySmallStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
            ),
            const SizedBox(width: 16),
            if (comment.likeCount > 0) ...[
              Text(
                '${comment.likeCount} ${comment.likeCount == 1 ? 'like' : 'likes'}',
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  color: ThemeColors.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
            ],
            GestureDetector(
              onTap: onReply,
              child: Text(
                'Reply',
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  color: ThemeColors.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Delete button for comment owner
            if (currentUserId != null && comment.userId == currentUserId) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onDelete,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delete',
                      style: TextThemes.getBodySmallStyle(context).copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Sync status
            if (comment.syncStatus == SyncStatus.pending) ...[
              const SizedBox(width: 8),
              const Icon(Icons.schedule, size: 14, color: Colors.orange),
            ] else if (comment.syncStatus == SyncStatus.failed) ...[
              const SizedBox(width: 8),
              const Icon(Icons.error_outline, size: 14, color: Colors.red),
            ],
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────
//  Mention-aware text widget: highlights @username
// ──────────────────────────────────────────────────────

class _MentionText extends StatelessWidget {
  final String text;

  const _MentionText({required this.text});

  @override
  Widget build(BuildContext context) {
    final mentionRegex = RegExp(r'@\[([^\]]+)\]|@(\w+)');
    final matches = mentionRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: TextThemes.getBodyMediumStyle(context));
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextThemes.getBodyMediumStyle(context),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: '@${match.group(1) ?? match.group(2)}',
          style: TextThemes.getBodyMediumStyle(context).copyWith(
            color: ThemeColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextThemes.getBodyMediumStyle(context),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}
