import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/pages/home/edit_profile_page.dart';
import 'package:hosla/pages/home/user_posts_page.dart';
import 'package:hosla/pages/home/saved_posts_page.dart';
import 'package:hosla/providers/theme_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextThemes.getBodyMediumStyle(
            context,
          ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextThemes.getBodySmallStyle(context).copyWith(fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentUser = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ThemeColors.getNavBarIconColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentUser?.name ?? 'User',
          style: TextThemes.getTitleStyle(
            context,
          ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // Instagram-style profile header
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Profile info row with picture and stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: () {
                          // TODO: View full image
                        },
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColors.getBorderColor(
                                context,
                              ).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child:
                                currentUser?.avatarUrl != null &&
                                    currentUser!.avatarUrl!.isNotEmpty
                                ? Image.network(
                                    currentUser.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: ThemeColors.getSurfaceColor(
                                          context,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color:
                                              ThemeColors.getSecondaryTextColor(
                                                context,
                                              ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: ThemeColors.getSurfaceColor(context),
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: ThemeColors.getSecondaryTextColor(
                                        context,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [_buildStatColumn('42', 'Posts')],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Name and Bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.name ?? 'User',
                        style: TextThemes.getBodyMediumStyle(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.bio ?? 'Hey there! I am using Hosla Varta',
                        style: TextThemes.getBodySmallStyle(
                          context,
                        ).copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Edit Profile Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: ThemeColors.getBorderColor(
                            context,
                          ).withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: TextThemes.getBodyMediumStyle(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Profile Options
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Instagram-style Icon Navigation
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: ThemeColors.getBorderColor(
                          context,
                        ).withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        color: ThemeColors.getTextColor(context),
                        width: 1,
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: ThemeColors.getTextColor(context),
                    unselectedLabelColor: ThemeColors.getSecondaryTextColor(
                      context,
                    ),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on, size: 26)),
                      Tab(icon: Icon(Icons.bookmark_border, size: 26)),
                      Tab(icon: Icon(Icons.settings_outlined, size: 26)),
                    ],
                  ),
                ),
                // Tab View Content
                SizedBox(
                  height: 600, // Fixed height for tab content
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Posts Tab
                      _buildPostsTab(context, currentUser),
                      // Saved Tab
                      _buildSavedTab(context),
                      // Settings Tab
                      _buildSettingsTab(
                        context,
                        isDark,
                        themeNotifier,
                        currentUser,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Posts Tab Content - Instagram Grid Style
  Widget _buildPostsTab(BuildContext context, currentUser) {
    // Placeholder posts grid (3 columns)
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: 12, // Show 12 placeholder squares
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Navigate to posts page on tap
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserPostsPage(
                  userId: currentUser?.id ?? '',
                  userName: currentUser?.name ?? 'User',
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: ThemeColors.getSurfaceColor(context).withOpacity(0.3),
              border: Border.all(
                color: ThemeColors.getBorderColor(context).withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: ThemeColors.getSecondaryTextColor(
                  context,
                ).withOpacity(0.3),
              ),
            ),
          ),
        );
      },
    );
  }

  // Saved Tab Content - Instagram Grid Style
  Widget _buildSavedTab(BuildContext context) {
    // Placeholder saved posts grid (3 columns)
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: 9, // Show 9 placeholder squares
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Navigate to saved posts page on tap
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SavedPostsPage()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: ThemeColors.getSurfaceColor(context).withOpacity(0.3),
              border: Border.all(
                color: ThemeColors.getBorderColor(context).withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: ThemeColors.getSecondaryTextColor(
                      context,
                    ).withOpacity(0.3),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.bookmark,
                    size: 16,
                    color: ThemeColors.getSecondaryTextColor(
                      context,
                    ).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Settings Tab Content
  Widget _buildSettingsTab(
    BuildContext context,
    bool isDark,
    themeNotifier,
    currentUser,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildProfileTile(
            context: context,
            icon: Icons.phone,
            title: 'Phone',
            subtitle: '+91 98765 43210',
            onTap: () {},
          ),
          _buildProfileTile(
            context: context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Available',
            onTap: () {},
          ),
          if (currentUser?.email != null && currentUser!.email!.isNotEmpty)
            _buildProfileTile(
              context: context,
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: currentUser.email!,
              onTap: () {},
            ),
          const SizedBox(height: 16),
          // Settings Section
          _buildSectionHeader(context, 'Settings'),
          _buildProfileTile(
            context: context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Handle notification toggle
              },
              activeColor: ThemeColors.primaryColor,
            ),
            onTap: null,
          ),
          _buildProfileTile(
            context: context,
            icon: isDark ? Icons.light_mode : Icons.dark_mode,
            title: 'Theme',
            subtitle: isDark ? 'Dark Mode' : 'Light Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                themeNotifier.toggleTheme();
              },
              activeColor: ThemeColors.primaryColor,
            ),
            onTap: null,
          ),
          _buildProfileTile(
            context: context,
            icon: Icons.lock_outline,
            title: 'Privacy',
            trailing: Icon(
              Icons.chevron_right,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
            onTap: () {},
          ),
          _buildProfileTile(
            context: context,
            icon: Icons.security_outlined,
            title: 'Security',
            trailing: Icon(
              Icons.chevron_right,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          // Additional Section
          _buildSectionHeader(context, 'More'),
          _buildProfileTile(
            context: context,
            icon: Icons.share_outlined,
            title: 'Share App',
            trailing: Icon(
              Icons.chevron_right,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
            onTap: () {},
          ),
          _buildProfileTile(
            context: context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            trailing: Icon(
              Icons.chevron_right,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
            onTap: () {},
          ),
          _buildProfileTile(
            context: context,
            icon: Icons.logout,
            title: 'Logout',
            titleColor: ThemeColors.errorColor,
            trailing: Icon(Icons.chevron_right, color: ThemeColors.errorColor),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
          const SizedBox(height: 32),
          // App Version
          Text(
            'Hosla Varta v1.0.0',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 12,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ThemeColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                titleColor?.withOpacity(0.1) ??
                ThemeColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: titleColor ?? ThemeColors.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: titleColor ?? ThemeColors.getTextColor(context),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 13,
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.getSurfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.bold,
              color: ThemeColors.getTextColor(context),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontFamily: 'Quicksand',
              color: ThemeColors.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement logout
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
