import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/pages/home/edit_profile_page.dart';
import 'package:hosla/pages/home/user_posts_page.dart';
import 'package:hosla/pages/home/saved_posts_page.dart';
import 'package:hosla/pages/home/settings_page.dart';
import 'package:hosla/providers/theme_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = 180.0 + topPadding;

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient and profile picture overlapping
            SizedBox(
              height: headerHeight + 55, // Extra space for profile picture overlap
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient header
                  Container(
                    height: headerHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeColors.primaryColor,
                          ThemeColors.primaryColor.withBlue(200),
                          ThemeColors.secondaryColor,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Pattern overlay
                        CustomPaint(
                          size: Size(double.infinity, headerHeight),
                          painter: _PatternPainter(),
                        ),
                        // Back button
                        Positioned(
                          top: topPadding + 8,
                          left: 8,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        // Settings button
                        Positioned(
                          top: topPadding + 8,
                          right: 16,
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsPage()),
                              );
                            },
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        // Title
                        Positioned(
                          top: topPadding + 16,
                          left: 0,
                          right: 0,
                          child: const Center(
                            child: Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile picture positioned to overlap
                  Positioned(
                    top: headerHeight - 55,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildProfilePicture(currentUser)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // User Name
            Text(
              currentUser?.name ?? 'User',
              style: TextThemes.getTitleStyle(context).copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Phone number
            if (currentUser?.phone != null)
              Text(
                currentUser!.phone!,
                style: TextThemes.getBodyMediumStyle(context).copyWith(
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
              ),
            const SizedBox(height: 8),

            // Bio
            if (currentUser?.bio != null && currentUser!.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  currentUser.bio!,
                  textAlign: TextAlign.center,
                  style: TextThemes.getBodyMediumStyle(context).copyWith(
                    color: ThemeColors.getSecondaryTextColor(context),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      isPrimary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildIconButton(
                    context,
                    icon: Icons.share_outlined,
                    onTap: () {
                      // TODO: Share profile
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Menu Items
            _buildMenuSection(context, isDark),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(currentUser) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                ThemeColors.primaryColor,
                ThemeColors.primaryColor.withOpacity(0.5),
              ],
            ),
          ),
        ),
        // White border
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ThemeColors.getSurfaceColor(context),
          ),
        ),
        // Profile image
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ThemeColors.getBackgroundColor(context),
          ),
          child: ClipOval(
            child: currentUser?.avatarUrl != null &&
                    currentUser!.avatarUrl!.isNotEmpty
                ? Image.network(
                    currentUser.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        // Online indicator
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ThemeColors.successColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: ThemeColors.getSurfaceColor(context),
                width: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: ThemeColors.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 48,
        color: ThemeColors.primaryColor,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [
                    ThemeColors.primaryColor,
                    ThemeColors.primaryColor.withBlue(180),
                  ],
                )
              : null,
          color: isPrimary ? null : ThemeColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(
                  color: ThemeColors.getBorderColor(context).withOpacity(0.3),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary
                  ? Colors.white
                  : ThemeColors.getTextColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextThemes.getBodyMediumStyle(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : ThemeColors.getTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeColors.getBorderColor(context).withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: ThemeColors.getTextColor(context),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isDark) {
    final currentUser = ref.watch(currentUserProfileProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // My Activity Section
          _buildSectionHeader(context, 'My Activity'),
          _buildMenuItem(
            context,
            icon: Icons.grid_view_rounded,
            iconColor: ThemeColors.primaryColor,
            title: 'My Posts',
            subtitle: 'View all your posts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserPostsPage(
                    userId: currentUser?.id ?? '',
                    userName: currentUser?.name ?? 'User',
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.bookmark_rounded,
            iconColor: ThemeColors.warningColor,
            title: 'Saved Posts',
            subtitle: 'Posts you\'ve saved',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedPostsPage()),
              );
            },
          ),
          _buildDivider(context),

          // Preferences Section
          _buildSectionHeader(context, 'Preferences'),
          _buildMenuItem(
            context,
            icon: isDark ? Icons.light_mode : Icons.dark_mode,
            iconColor: isDark ? ThemeColors.warningColor : Colors.indigo,
            title: 'Theme',
            subtitle: isDark ? 'Dark Mode' : 'Light Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              activeColor: ThemeColors.primaryColor,
            ),
            onTap: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_rounded,
            iconColor: ThemeColors.errorColor,
            title: 'Notifications',
            subtitle: 'Manage notifications',
            onTap: () {
              // TODO: Notifications settings
            },
          ),
          _buildDivider(context),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildMenuItem(
            context,
            icon: Icons.settings_rounded,
            iconColor: ThemeColors.secondaryColor,
            title: 'Settings',
            subtitle: 'Privacy, security, and more',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline_rounded,
            iconColor: ThemeColors.infoColor,
            title: 'Help & Support',
            subtitle: 'FAQs and contact us',
            onTap: () {
              // TODO: Help page
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outline_rounded,
            iconColor: Colors.grey,
            title: 'About',
            subtitle: 'App version and info',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          _buildDivider(context),

          // Logout
          _buildMenuItem(
            context,
            icon: Icons.logout_rounded,
            iconColor: ThemeColors.errorColor,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            showChevron: false,
            onTap: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextThemes.getBodySmallStyle(context).copyWith(
          color: ThemeColors.primaryColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextThemes.getBodyMediumStyle(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextThemes.getBodySmallStyle(context).copyWith(
                        color: ThemeColors.getSecondaryTextColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing widget or chevron
              if (trailing != null)
                trailing
              else if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: ThemeColors.getSecondaryTextColor(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: ThemeColors.getBorderColor(context).withOpacity(0.3),
        height: 1,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeColors.primaryColor,
                    ThemeColors.primaryColor.withBlue(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hosla Varta',
              style: TextThemes.getTitleStyle(context).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextThemes.getBodyMediumStyle(context).copyWith(
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connect with your community\nShare moments, stories & more',
              textAlign: TextAlign.center,
              style: TextThemes.getBodySmallStyle(context).copyWith(
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: ThemeColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: ThemeColors.getSurfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: ThemeColors.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextThemes.getTitleStyle(context).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout? You\'ll need to sign in again to access your account.',
            style: TextThemes.getBodyMediumStyle(context).copyWith(
              color: ThemeColors.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: ThemeColors.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      await _userService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: ThemeColors.errorColor,
          ),
        );
      }
    }
  }
}

/// Custom painter for the pattern overlay
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const radius = 4.0;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = (y ~/ spacing).isEven ? 0 : spacing / 2;
          x < size.width;
          x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
