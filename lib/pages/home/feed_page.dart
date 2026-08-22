import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/pages/home/friends_page.dart';
import 'package:hosla/pages/home/notifications_page.dart';
import 'package:hosla/pages/home/profile_page.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/providers/feed_provider.dart';
import 'package:hosla/widgets/post_card.dart';
import 'package:hosla/widgets/loading_widget.dart';
import 'package:hosla/widgets/glass_app_bar.dart';
import 'package:hosla/widgets/create_post_fab.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _friendScrollController = ScrollController();
  bool _showTitle = false;
  late TabController _tabController;

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
    _friendScrollController.addListener(_onFriendScroll);
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedPostsProvider.notifier).loadPosts();
      ref.read(currentUserProfileProvider.notifier).loadCurrentUser();
    });
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

  void _onFriendScroll() {
    if (_friendScrollController.position.pixels >=
        _friendScrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(feedPostsProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMorePosts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _friendScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(feedPostsProvider.notifier).refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);

    final topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight + 48;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [ThemeColors.primaryColor, ThemeColors.primaryColor],
              ).createShader(bounds),
              child: Text(
                'Varta Wall',
                style: TextThemes.getTitleStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            icon: Icon(
              Icons.notifications_outlined,
              color: ThemeColors.getNavBarIconColor(context),
              size: 24,
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendsPage()),
              );
            },
            icon: Icon(
              Icons.person_add_alt_1_rounded,
              color: ThemeColors.getNavBarIconColor(context),
              size: 24,
            ),
            tooltip: 'Add Friends',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            icon: () {
              final avatarUrl = currentUser?.avatarUrl;
              if (avatarUrl != null && avatarUrl.isNotEmpty) {
                return Container(
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
                      avatarUrl,
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
                );
              }
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeColors.getSurfaceColor(context),
                  border: Border.all(color: ThemeColors.primaryColor, width: 2),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: ThemeColors.getTextColor(context),
                ),
              );
            }(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: ThemeColors.primaryColor,
            indicatorWeight: 3,
            labelColor: ThemeColors.primaryColor,
            unselectedLabelColor: ThemeColors.getSecondaryTextColor(context),
            labelStyle: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(fontSize: 15),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.public, size: 20),
                    SizedBox(width: 6),
                    Text('Global'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_outlined, size: 20),
                    SizedBox(width: 6),
                    Text('Friends'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const CreatePostFab(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Global Feed Tab
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: ThemeColors.primaryColor,
            backgroundColor: ThemeColors.getSurfaceColor(context),
            edgeOffset: topPadding,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding + 8)),
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
                        final globalPosts = posts.where((p) {
                          final vis = p.visibility.toUpperCase();
                          return vis == 'PUBLIC';
                        }).toList();

                        if (globalPosts.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                ),
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
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final post = globalPosts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: PostCard(post: post),
                              );
                            }, childCount: globalPosts.length),
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
                      error: (e, _) => _buildFeedErrorWidget(e),
                    );
                  },
                ),
                SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          // Friends Feed Tab
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: ThemeColors.primaryColor,
            backgroundColor: ThemeColors.getSurfaceColor(context),
            edgeOffset: topPadding,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              controller: _friendScrollController,
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding + 8)),
                Consumer(
                  builder: (context, ref, _) {
                    final feed = ref.watch(feedPostsProvider);
                    return feed.when(
                      data: (posts) {
                        final friendPosts = posts
                            .where(
                              (p) => p.visibility.toUpperCase() == 'FRIENDS',
                            )
                            .toList();

                        if (friendPosts.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 72,
                                    color: ThemeColors.getSecondaryTextColor(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No friends-only posts yet',
                                    style: TextThemes.getTitleStyle(
                                      context,
                                    ).copyWith(fontSize: 20),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                    ),
                                    child: Text(
                                      'Add friends to start seeing their posts here.',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextThemes.getBodyMediumStyle(
                                            context,
                                          ).copyWith(
                                            color:
                                                ThemeColors.getSecondaryTextColor(
                                                  context,
                                                ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.only(top: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final post = friendPosts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: PostCard(post: post),
                              );
                            }, childCount: friendPosts.length),
                          ),
                        );
                      },
                      loading: () => const SliverFillRemaining(
                        child: Center(
                          child: LoadingWidget(message: 'Loading posts...'),
                        ),
                      ),
                      error: (e, _) => _buildFeedErrorWidget(e),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedErrorWidget(dynamic e) {
    final errorText = e.toString().replaceFirst('Exception: ', '');
    final lower = errorText.toLowerCase();
    final isAuthError = lower.contains('authenticate') ||
        lower.contains('unauthorized') ||
        lower.contains('login') ||
        lower.contains('token');
    final isRegistrationError = lower.contains('registration');

    IconData iconData = Icons.error_outline;
    String actionLabel = 'Retry';
    VoidCallback onAction = () {
      ref.read(feedPostsProvider.notifier).loadPosts();
    };

    if (isAuthError) {
      iconData = Icons.lock_outline;
      actionLabel = 'Log In Again';
      onAction = () {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      };
    } else if (isRegistrationError) {
      iconData = Icons.person_outline;
      actionLabel = 'Complete Profile';
      onAction = () {
        Navigator.pushNamed(context, '/create-profile');
      };
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ThemeColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 38,
                  color: ThemeColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorText,
                textAlign: TextAlign.center,
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
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
