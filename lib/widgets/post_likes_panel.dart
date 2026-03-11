import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/providers/feed_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';

/// Scrollable bottom-sheet panel that displays users who liked a post.
class PostLikesPanel extends ConsumerWidget {
  final String postId;
  final int likeCount;

  const PostLikesPanel({
    super.key,
    required this.postId,
    required this.likeCount,
  });

  static Future<void> show(
    BuildContext context, {
    required String postId,
    required int likeCount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostLikesPanel(postId: postId, likeCount: likeCount),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesAsync = ref.watch(postLikesProvider(postId));
    final surfaceColor = ThemeColors.getSurfaceColor(context);
    final borderColor = ThemeColors.getBorderColor(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: borderColor.withValues(alpha: 0.3)),
              left: BorderSide(color: borderColor.withValues(alpha: 0.3)),
              right: BorderSide(color: borderColor.withValues(alpha: 0.3)),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Liked by',
                      style: TextThemes.getBodyLargeStyle(
                        context,
                      ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeColors.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$likeCount',
                        style: TextThemes.getBodySmallStyle(context).copyWith(
                          color: ThemeColors.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor.withValues(alpha: 0.3)),
              Expanded(
                child: likesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: ThemeColors.errorColor,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load likes',
                            style: TextThemes.getBodyMediumStyle(context),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(postLikesProvider(postId)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (users) => users.isEmpty
                      ? Center(
                          child: Text(
                            'No likes yet',
                            style: TextThemes.getBodyMediumStyle(context)
                                .copyWith(
                                  color: ThemeColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 72,
                            color: borderColor.withValues(alpha: 0.2),
                          ),
                          itemBuilder: (context, index) =>
                              _LikeUserTile(user: users[index]),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LikeUserTile extends StatelessWidget {
  final LikeUser user;

  const _LikeUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ProfilePic(
            imageUrl: user.profilePicUrl ?? '',
            radius: 22,
            name: user.name,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              user.name,
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
