import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/pages/home/create_post_page.dart';
import 'package:hosla/pages/home/profile_page.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/providers/feed_provider.dart';
import 'package:hosla/widgets/post_card.dart';
import 'package:hosla/widgets/loading_widget.dart';
import 'dart:ui';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  // Stories data - Commented out for now
  // final List<Map<String, String>> _stories = [
  // Stories data - Commented out for now
  // final List<Map<String, String>> _stories = [
  //   {
  //     'name': 'Your Story',
  //     'imageUrl': 'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
  //     'isAddStory': 'true'
  //   },
  //   {
  //     'name': 'Rohan',
  //     'imageUrl': 'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
  //   },
  //   {
  //     'name': 'Priya',
  //     'imageUrl': 'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
  //   },
  //   {
  //     'name': 'Amit',
  //     'imageUrl': 'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
  //   },
  //   {
  //     'name': 'Sneha',
  //     'imageUrl': 'https://static.vecteezy.com/system/resources/thumbnails/004/511/281/small/default-avatar-photo-placeholder-profile-picture-vector.jpg',
  //   },
  // ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 100 && _showTitle) {
      setState(() => _showTitle = false);
    }

    // Infinite scroll: load more when near bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(feedPostsProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMorePosts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(feedPostsProvider.notifier).refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              centerTitle: false,
              backgroundColor: ThemeColors.getNavBarColor(
                context,
              ).withValues(alpha: 0.8),
              elevation: 0,
              title: AnimatedOpacity(
                opacity: _showTitle ? 1.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          ThemeColors.primaryColor,
                          ThemeColors.primaryColor.withBlue(200),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Varta Wall',
                        style: TextThemes.getTitleStyle(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostPage(),
                      ),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ThemeColors.primaryColor,
                          ThemeColors.primaryColor.withBlue(200),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.add_to_photos,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                  icon: currentUser?.avatarUrl != null
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColors.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              currentUser!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: ThemeColors.getSurfaceColor(context),
                                  child: Icon(
                                    Icons.person,
                                    size: 25,
                                    color: ThemeColors.getTextColor(context),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                ThemeColors.primaryColor.withValues(alpha: 0.3),
                                ThemeColors.primaryColor.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: ThemeColors.getTextColor(context),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: ThemeColors.primaryColor,
        backgroundColor: ThemeColors.getSurfaceColor(context),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 125)),
            // Stories Section - Commented out for now
            // SliverToBoxAdapter(
            //   child: Container(
            //     height: 110,
            //     margin: const EdgeInsets.symmetric(vertical: 8),
            //     child: ListView.builder(
            //       scrollDirection: Axis.horizontal,
            //       physics: const BouncingScrollPhysics(),
            //       padding: const EdgeInsets.symmetric(horizontal: 12),
            //       itemCount: _stories.length,
            //       itemBuilder: (context, index) {
            //         final story = _stories[index];
            //         final isAddStory = story['isAddStory'] == 'true';
            //         return _buildStoryItem(
            //           name: story['name']!,
            //           imageUrl: story['imageUrl']!,
            //           isAddStory: isAddStory,
            //         );
            //       },
            //     ),
            //   ),
            // ),
            // Posts Section (from network feed)
            Consumer(
              builder: (context, ref, _) {
                final feed = ref.watch(feedPostsProvider);
                return feed.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'No posts yet',
                              style: TextThemes.getBodyMediumStyle(context),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.only(top: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = posts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PostCard(post: post),
                          );
                        }, childCount: posts.length),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: LoadingWidget(message: 'Loading posts...'),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Failed to load feed',
                          style: TextThemes.getBodyMediumStyle(context),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // Story item builder - Commented out for now
  // Widget _buildStoryItem({
  //   required String name,
  //   required String imageUrl,
  //   bool isAddStory = false,
  // }) {
  //   return Container(
  //     width: 75,
  //     margin: const EdgeInsets.only(right: 12),
  //     child: Column(
  //       children: [
  //         Container(
  //           width: 70,
  //           height: 70,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             gradient: isAddStory
  //                 ? null
  //                 : LinearGradient(
  //                     begin: Alignment.topRight,
  //                     end: Alignment.bottomLeft,
  //                     colors: [
  //                       ThemeColors.primaryColor,
  //                       ThemeColors.primaryColor.withBlue(200),
  //                       ThemeColors.secondaryColor,
  //                     ],
  //                   ),
  //           ),
  //           padding: const EdgeInsets.all(2.5),
  //           child: Container(
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: ThemeColors.getCardColor(context),
  //               border: Border.all(
  //                 color: ThemeColors.getCardColor(context),
  //                 width: 3,
  //               ),
  //             ),
  //             child: ClipOval(
  //               child: Stack(
  //                 fit: StackFit.expand,
  //                 children: [
  //                   Image.network(
  //                     imageUrl,
  //                     fit: BoxFit.cover,
  //                     errorBuilder: (context, error, stackTrace) {
  //                       return Container(
  //                         color: ThemeColors.getSurfaceColor(context),
  //                         child: Icon(
  //                           Icons.person,
  //                           color: ThemeColors.getSecondaryTextColor(context),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                   if (isAddStory)
  //                     Container(
  //                       color: Colors.black.withValues(alpha: 0.3),
  //                       child: const Icon(
  //                         Icons.add_circle,
  //                         color: Colors.white,
  //                         size: 24,
  //                       ),
  //                     ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 6),
  //         Text(
  //           name,
  //           style: TextThemes.getBodySmallStyle(context).copyWith(
  //             fontSize: 11,
  //             fontWeight: FontWeight.w500,
  //           ),
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //           textAlign: TextAlign.center,
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
