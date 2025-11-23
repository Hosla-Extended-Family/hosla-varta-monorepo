import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/pages/home/edit_profile_page.dart';
import 'package:hosla/providers/theme_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentUser = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // WhatsApp-style header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: ThemeColors.getSurfaceColor(context),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: ThemeColors.getTextColor(context),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit, color: ThemeColors.primaryColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: ThemeColors.getSurfaceColor(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Profile Picture
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // TODO: View full image
                          },
                          child: Hero(
                            tag: 'profile_pic',
                            child: ProfilePic(
                              radius: 70,
                              imageUrl: currentUser?.avatarUrl ?? '',
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: ThemeColors.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ThemeColors.getSurfaceColor(context),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      currentUser?.name ?? 'User',
                      style: TextThemes.getTitleStyle(
                        context,
                      ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // Bio
                    Text(
                      currentUser?.bio ?? 'Hey there! I am using Hosla Varta',
                      style: TextThemes.getBodyMediumStyle(context).copyWith(
                        fontSize: 14,
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Profile Options
          SliverToBoxAdapter(
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
                if (currentUser?.email != null &&
                    currentUser!.email!.isNotEmpty)
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
                  trailing: Icon(
                    Icons.chevron_right,
                    color: ThemeColors.errorColor,
                  ),
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
          ),
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
