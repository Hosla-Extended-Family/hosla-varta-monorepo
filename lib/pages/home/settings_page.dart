import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/pages/home/edit_profile_page.dart';
import 'package:hosla/pages/home/verify_email_page.dart';
import 'package:hosla/pages/home/blocked_users_page.dart';
import 'package:hosla/pages/home/friends_page.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/providers/theme_provider.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

/// Modern Settings page with enhanced UI matching app design language
class SettingsPage extends ConsumerStatefulWidget {
  final bool showBackButton;

  const SettingsPage({super.key, this.showBackButton = true});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            backgroundColor: ThemeColors.getNavBarColor(context),
            automaticallyImplyLeading: false,
            leading: widget.showBackButton
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ThemeColors.primaryColor,
                          ThemeColors.primaryColor.withBlue(180),
                          ThemeColors.secondaryColor,
                        ],
                      ),
                    ),
                  ),
                  // Pattern overlay
                  Positioned.fill(
                    child: CustomPaint(painter: _PatternPainter()),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                  // Title content
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  _buildProfileCard(currentUser, isDark),
                  const SizedBox(height: 24),

                  // Account Section
                  _buildSection(
                    context,
                    title: 'Account',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildSettingsTile(
                        icon: Icons.edit_outlined,
                        iconColor: ThemeColors.primaryColor,
                        title: 'Edit Profile',
                        subtitle: 'Update your profile information',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.email_outlined,
                        iconColor: const Color(0xFF5C6BC0),
                        title: 'Verify Email',
                        subtitle: 'Add or verify your email address',
                        onTap: _navigateToVerifyEmail,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.people_outline_rounded,
                        iconColor: const Color(0xFF42A5F5),
                        title: 'Friends',
                        subtitle: 'View friends, requests, and add users',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FriendsPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notifications Section
                  _buildSection(
                    context,
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    children: [
                      _buildSwitchTile(
                        icon: Icons.notifications_active_outlined,
                        iconColor: const Color(0xFFFF7043),
                        title: 'Push Notifications',
                        subtitle: 'Receive push notifications',
                        value: appSettings.notificationsEnabled,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateNotifications(value);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.volume_up_outlined,
                        iconColor: const Color(0xFF26A69A),
                        title: 'Sound',
                        subtitle: 'Play notification sounds',
                        value: appSettings.soundEnabled,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateSound(value);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.vibration_rounded,
                        iconColor: const Color(0xFF7E57C2),
                        title: 'Vibration',
                        subtitle: 'Vibrate for notifications',
                        value: appSettings.vibrationEnabled,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateVibration(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Appearance Section
                  _buildSection(
                    context,
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    children: [
                      _buildSwitchTile(
                        icon: isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: isDark
                            ? const Color(0xFF5C6BC0)
                            : const Color(0xFFFFB74D),
                        title: 'Dark Mode',
                        subtitle: isDark
                            ? 'Currently using dark theme'
                            : 'Currently using light theme',
                        value: ref.watch(themeProvider) == ThemeMode.dark,
                        onChanged: (value) {
                          HapticFeedback.mediumImpact();
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Privacy Section
                  _buildSection(
                    context,
                    title: 'Privacy & Security',
                    icon: Icons.shield_outlined,
                    children: [
                      _buildSwitchTile(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFF66BB6A),
                        title: 'Location Services',
                        subtitle: 'Allow location access for events',
                        value: appSettings.locationEnabled,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateLocation(value);
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFFEF5350),
                        title: 'Private Profile',
                        subtitle: 'Only approved followers can see your posts',
                        value: appSettings.privateProfile,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(appSettingsProvider.notifier)
                              .updatePrivateProfile(value);
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.block_rounded,
                        iconColor: const Color(0xFFFF7043),
                        title: 'Blocked Users',
                        subtitle: 'Manage blocked users',
                        onTap: _showBlockedUsers,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // App Settings Section
                  _buildSection(
                    context,
                    title: 'App Settings',
                    icon: Icons.tune_rounded,
                    children: [
                      _buildSettingsTile(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF42A5F5),
                        title: 'Language',
                        subtitle: appSettings.language,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'EN',
                            style: TextStyle(
                              color: ThemeColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: _showLanguageOptions,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.storage_rounded,
                        iconColor: const Color(0xFF8D6E63),
                        title: 'Storage & Data',
                        subtitle: 'Manage app data usage',
                        onTap: _showStorageSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Support Section
                  _buildSection(
                    context,
                    title: 'Support',
                    icon: Icons.help_outline_rounded,
                    children: [
                      _buildSettingsTile(
                        icon: Icons.help_center_outlined,
                        iconColor: const Color(0xFF29B6F6),
                        title: 'Help & Support',
                        subtitle: 'Get help and contact support',
                        onTap: _showHelpSupport,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.bug_report_outlined,
                        iconColor: const Color(0xFFAB47BC),
                        title: 'Report a Bug',
                        subtitle: 'Report issues with the app',
                        onTap: _showBugReport,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.feedback_outlined,
                        iconColor: const Color(0xFF26A69A),
                        title: 'Send Feedback',
                        subtitle: 'Share your thoughts with us',
                        onTap: _showFeedback,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF78909C),
                        title: 'About',
                        subtitle: 'App version 1.0.0',
                        onTap: _showAbout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Danger Zone Section
                  _buildSection(
                    context,
                    title: 'Danger Zone',
                    icon: Icons.warning_amber_rounded,
                    titleColor: ThemeColors.errorColor,
                    children: [
                      _buildSettingsTile(
                        icon: Icons.download_rounded,
                        iconColor: const Color(0xFF5C6BC0),
                        title: 'Export Data',
                        subtitle: 'Download your account data',
                        onTap: _exportUserData,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.delete_forever_rounded,
                        iconColor: ThemeColors.errorColor,
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
                        titleColor: ThemeColors.errorColor,
                        onTap: _showDeleteAccountDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  _buildLogoutButton(),
                  const SizedBox(height: 32),

                  // App version footer
                  Text(
                    'Hosla Varta v1.0.0',
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(currentUser, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile picture with gradient ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryColor,
                  ThemeColors.primaryColor.withBlue(180),
                ],
              ),
            ),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeColors.getSurfaceColor(context),
                border: Border.all(
                  color: ThemeColors.getSurfaceColor(context),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child:
                    currentUser?.avatarUrl != null &&
                        currentUser!.avatarUrl!.isNotEmpty
                    ? Image.network(
                        currentUser.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.name ?? 'Loading...',
                  style: TextThemes.getBodyLargeStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                if (currentUser?.email != null &&
                    currentUser!.email!.isNotEmpty)
                  Text(
                    currentUser.email!,
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontSize: 13,
                    ),
                  ),
                if (currentUser?.phone != null &&
                    currentUser!.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    currentUser.phone!,
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ThemeColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: ThemeColors.primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: ThemeColors.primaryColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_rounded,
        size: 30,
        color: ThemeColors.primaryColor,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? titleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: titleColor ?? ThemeColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextThemes.getBodySmallStyle(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: titleColor ?? ThemeColors.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        // Section content
        Container(
          decoration: BoxDecoration(
            color: ThemeColors.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ThemeColors.getBorderColor(context).withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextThemes.getBodyMediumStyle(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: titleColor,
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
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: ThemeColors.getSecondaryTextColor(context),
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 15),
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

          // Custom switch
          _buildCustomSwitch(value, onChanged),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: value
              ? LinearGradient(
                  colors: [
                    ThemeColors.primaryColor,
                    ThemeColors.primaryColor.withBlue(180),
                  ],
                )
              : null,
          color: value ? null : ThemeColors.getBorderColor(context),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Divider(
        height: 1,
        color: ThemeColors.getBorderColor(context).withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              ThemeColors.errorColor,
              ThemeColors.errorColor.withRed(220),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.errorColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Quicksand',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeColors.getBorderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeColors.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: ThemeColors.errorColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Logout',
                  style: TextThemes.getTitleStyle(
                    context,
                  ).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to logout?',
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: ThemeColors.getBorderColor(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextThemes.getBodyMediumStyle(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await ref
                                .read(currentUserProfileProvider.notifier)
                                .logout();
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              SnackBarWidget.show(
                                context,
                                'Logout failed. Please try again.',
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeColors.errorColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColors.getSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeColors.getBorderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeColors.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: ThemeColors.errorColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Delete Account',
                  style: TextThemes.getTitleStyle(context).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.errorColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: ThemeColors.getBorderColor(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextThemes.getBodyMediumStyle(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          SnackBarWidget.show(
                            context,
                            'Account deletion requested',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeColors.errorColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToVerifyEmail() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
    );
    if (result == true && mounted) {
      SnackBarWidget.show(context, 'Email verified successfully!');
      setState(() {});
    }
  }

  void _showBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
    );
  }

  void _showLanguageOptions() => _showComingSoon();
  void _showStorageSettings() => _showComingSoon();
  void _showHelpSupport() => _showComingSoon();
  void _showBugReport() => _showComingSoon();
  void _showFeedback() => _showComingSoon();
  void _showAbout() => _showComingSoon();
  void _exportUserData() => _showComingSoon();

  void _showComingSoon() {
    SnackBarWidget.show(context, 'Feature coming soon!');
  }
}

/// Pattern painter for header background
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const spacing = 25.0;
    const radius = 3.0;

    for (double y = 0; y < size.height; y += spacing) {
      for (
        double x = (y ~/ spacing).isEven ? 0 : spacing / 2;
        x < size.width;
        x += spacing
      ) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
