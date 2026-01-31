import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';

class PostWidget extends StatefulWidget {
  final Post? post;

  const PostWidget({super.key, this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLiked = false;
  int _likeCount = 42;
  int _commentCount = 8;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      if (_isLiked) {
        _likeCount--;
        _isLiked = false;
      } else {
        _likeCount++;
        _isLiked = true;
        _controller.forward().then((_) => _controller.reverse());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : ThemeColors.getOverlayColor(context, opacity: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        ThemeColors.primaryColor.withValues(alpha: 0.6),
                        ThemeColors.secondaryColor.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ThemeColors.getCardColor(context),
                      border: Border.all(
                        color: ThemeColors.getCardColor(context),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: ThemeColors.getSurfaceColor(context),
                            child: Icon(
                              Icons.person,
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hosla',
                        style: TextThemes.getBodyMediumStyle(
                          context,
                        ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2 hours ago',
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.getSecondaryTextColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showPostOptions(context),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: ThemeColors.getSecondaryTextColor(context),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const text =
                    'This is a sample post content. It can be multiple lines long and should display properly within the post widget.';
                final span = TextSpan(
                  text: text,
                  style: TextThemes.getBodyMediumStyle(context),
                );
                final tp = TextPainter(
                  text: span,
                  textDirection: TextDirection.ltr,
                );
                tp.layout(maxWidth: constraints.maxWidth);
                final exceedsMaxLines = tp.computeLineMetrics().length > 2;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextThemes.getBodyMediumStyle(
                        context,
                      ).copyWith(height: 1.5, fontSize: 15),
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                      maxLines: _isExpanded ? null : 3,
                    ),
                    if (exceedsMaxLines)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _isExpanded ? 'show less' : 'read more',
                            style: TextThemes.getBodySmallStyle(context)
                                .copyWith(
                                  color: ThemeColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Tags Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: ['#Event', '#Community', '#Support']
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThemeColors.primaryColor.withOpacity(0.15),
                            ThemeColors.primaryColor.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ThemeColors.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Image Section
          Container(
            constraints: const BoxConstraints(
              minHeight: 200,
              maxHeight: 400,
              minWidth: double.infinity,
              maxWidth: double.infinity,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.asset(
                'assets/images/Sample_image.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeColors.getSurfaceColor(context),
                          ThemeColors.getCardColor(context),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_rounded,
                          size: 64,
                          color: ThemeColors.getSecondaryTextColor(
                            context,
                          ).withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Image not available',
                          style: TextThemes.getBodySmallStyle(context).copyWith(
                            color: ThemeColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Stats Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '$_likeCount likes',
                  style: TextThemes.getBodySmallStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_commentCount comments',
                  style: TextThemes.getBodySmallStyle(context).copyWith(
                    color: ThemeColors.getSecondaryTextColor(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              height: 1,
              color: ThemeColors.getBorderColor(context).withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 8),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: 'Like',
                  color: _isLiked ? Colors.red : null,
                  onTap: _toggleLike,
                ),
                _buildActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: 'Comment',
                  onTap: () {
                    _showCommentsBottomSheet(context);
                  },
                ),
                _buildActionButton(
                  icon: Icons.send_rounded,
                  label: 'Share',
                  onTap: () {
                    // TODO: Handle share action
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? ThemeColors.getSecondaryTextColor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: icon == Icons.favorite_rounded
                  ? _scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Icon(icon, size: 22, color: buttonColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextThemes.getBodyMediumStyle(context).copyWith(
                color: buttonColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOptionTile(
              context,
              icon: Icons.bookmark_border_rounded,
              title: 'Save Post',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Post saved successfully',
                      style: TextStyle(fontFamily: 'Quicksand'),
                    ),
                    backgroundColor: ThemeColors.successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.link_rounded,
              title: 'Copy Link',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Link copied to clipboard',
                      style: TextStyle(fontFamily: 'Quicksand'),
                    ),
                    backgroundColor: ThemeColors.successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.person_off_outlined,
              title: 'Not Interested',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.report_outlined,
              title: 'Report',
              onTap: () {
                Navigator.pop(context);
              },
              isDestructive: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? ThemeColors.errorColor
            : ThemeColors.getTextColor(context),
      ),
      title: Text(
        title,
        style: TextThemes.getBodyMediumStyle(context).copyWith(
          color: isDestructive
              ? ThemeColors.errorColor
              : ThemeColors.getTextColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showCommentsBottomSheet(BuildContext context) {
    // Create a mock post if none is provided
    final postData =
        widget.post ??
        Post(
          id: 'mock_post_1',
          userId: 'user_1',
          userName: 'Hosla',
          content: 'This is a sample post content.',
          createdAt: DateTime.now(),
          tags: ['#Event', '#Community', '#Support'],
          likeCount: _likeCount,
          commentCount: _commentCount,
        );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: ThemeColors.getSurfaceColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Comments ($_commentCount)',
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
              Expanded(
                child: _commentCount == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 64,
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextThemes.getBodyMediumStyle(context)
                                  .copyWith(
                                    color: ThemeColors.getSecondaryTextColor(
                                      context,
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: TextThemes.getBodySmallStyle(context)
                                  .copyWith(
                                    color: ThemeColors.getSecondaryTextColor(
                                      context,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _commentCount,
                        itemBuilder: (context, index) {
                          // Mock comments for now
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: ThemeColors.primaryColor
                                  .withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: ThemeColors.primaryColor,
                              ),
                            ),
                            title: Text(
                              'User ${index + 1}',
                              style: TextThemes.getBodyMediumStyle(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'This is a sample comment.',
                              style: TextThemes.getBodySmallStyle(context),
                            ),
                          );
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
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setState(() {
                              _commentCount++;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Comment added',
                                  style: TextStyle(fontFamily: 'Quicksand'),
                                ),
                                backgroundColor: ThemeColors.successColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: ThemeColors.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _commentCount++;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
