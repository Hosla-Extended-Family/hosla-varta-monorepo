import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/providers/post_provider.dart';
import 'package:hosla/widgets/post_card.dart';
import 'package:hosla/widgets/edit_post_dialog.dart';
import 'package:hosla/widgets/comments_bottom_sheet.dart';

/// Page for viewing saved posts
class SavedPostsPage extends ConsumerWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPostsAsyncValue = ref.watch(savedPostsProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Saved Posts', style: TextThemes.getTitleStyle(context)),
        backgroundColor: ThemeColors.getSurfaceColor(context),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(savedPostsProvider.notifier).refresh();
        },
        child: savedPostsAsyncValue.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 80,
                      color: ThemeColors.getSecondaryTextColor(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved posts',
                      style: TextThemes.getTitleStyle(context).copyWith(
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save posts to view them here',
                      style: TextThemes.getBodyMediumStyle(context).copyWith(
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(
                  post: post,
                  onEdit: () => _showEditDialog(context, post),
                  onComment: () => _showComments(context, post),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load saved posts',
                  style: TextThemes.getTitleStyle(context),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextThemes.getBodySmallStyle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(savedPostsProvider.notifier).refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, post) {
    showDialog(
      context: context,
      builder: (context) => EditPostDialog(post: post),
    );
  }

  void _showComments(BuildContext context, post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: post),
    );
  }
}
