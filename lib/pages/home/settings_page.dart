import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/pages/authentication/update_password_page.dart';
import 'package:hosla/pages/home/edit_profile_page.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/providers/theme_provider.dart';
import 'package:hosla/widgets/snack_bar_widget.dart';

/// Enhanced Settings page with profile, notifications, privacy options, and logout
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider);
    final appSettings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              ThemeColors.primaryColor,
              ThemeColors.primaryColor.withBlue(200),
            ],
          ).createShader(bounds),
          child: Text(
            'Settings',
            style: TextThemes.getTitleStyle(context).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(currentUser),

            const SizedBox(height: 24),

            // Account Settings
            _buildSection('Account', [
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your profile information',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpdatePasswordPage()),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.email_outlined,
                title: 'Email Settings',
                subtitle: 'Manage email preferences',
                onTap: () => _showEmailSettings(),
              ),
            ]),

            const SizedBox(height: 24),

            // Notifications Settings
            _buildSection('Notifications', [
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications',
                value: appSettings.notificationsEnabled,
                onChanged: (value) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateNotifications(value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.volume_up_outlined,
                title: 'Sound',
                subtitle: 'Play notification sounds',
                value: appSettings.soundEnabled,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).updateSound(value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.vibration,
                title: 'Vibration',
                subtitle: 'Vibrate for notifications',
                value: appSettings.vibrationEnabled,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).updateVibration(value);
                },
              ),
              _buildSettingsTile(
                icon: Icons.tune,
                title: 'Notification Preferences',
                subtitle: 'Customize which notifications you receive',
                onTap: () => _showNotificationPreferences(),
              ),
            ]),

            const SizedBox(height: 24),

            // Appearance Settings
            _buildSection('Appearance', [
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                value: ref.watch(themeProvider) == ThemeMode.dark,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Privacy Settings
            _buildSection('Privacy & Security', [
              _buildSwitchTile(
                icon: Icons.location_on_outlined,
                title: 'Location Services',
                subtitle: 'Allow location access for events',
                value: appSettings.locationEnabled,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).updateLocation(value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.lock_person,
                title: 'Private Profile',
                subtitle: 'Make your profile private',
                value: appSettings.privateProfile,
                onChanged: (value) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updatePrivateProfile(value);
                },
              ),
              _buildSettingsTile(
                icon: Icons.security,
                title: 'Privacy Settings',
                subtitle: 'Manage your privacy preferences',
                onTap: () => _showPrivacySettings(),
              ),
              _buildSettingsTile(
                icon: Icons.block,
                title: 'Blocked Users',
                subtitle: 'Manage blocked users',
                onTap: () => _showBlockedUsers(),
              ),
            ]),

            const SizedBox(height: 24),

            // App Settings
            _buildSection('App Settings', [
              _buildSettingsTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: appSettings.language,
                onTap: () => _showLanguageOptions(),
              ),
              _buildSettingsTile(
                icon: Icons.storage,
                title: 'Storage & Data',
                subtitle: 'Manage app data usage',
                onTap: () => _showStorageSettings(),
              ),
            ]),

            const SizedBox(height: 24),

            // Support Settings
            _buildSection('Support', [
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () => _showHelpSupport(),
              ),
              _buildSettingsTile(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                subtitle: 'Report issues with the app',
                onTap: () => _showBugReport(),
              ),
              _buildSettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts with us',
                onTap: () => _showFeedback(),
              ),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and legal information',
                onTap: () => _showAbout(),
              ),
            ]),

            const SizedBox(height: 24),

            // Data Management
            _buildSection('Data', [
              _buildSettingsTile(
                icon: Icons.download,
                title: 'Export Data',
                subtitle: 'Download your account data',
                onTap: () => _exportUserData(),
              ),
              _buildSettingsTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: () => _showDeleteAccountDialog(),
                textColor: ThemeColors.getErrorColor(context),
              ),
            ]),

            const SizedBox(height: 32),

            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    ThemeColors.getErrorColor(context),
                    ThemeColors.getErrorColor(context).withRed(255),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.getErrorColor(context).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Build profile section
  Widget _buildProfileSection(currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : ThemeColors.getOverlayColor(context, opacity: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile picture with gradient border
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryColor,
                  ThemeColors.primaryColor.withBlue(200),
                ],
              ),
            ),
            padding: const EdgeInsets.all(3),
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
                child:
                    currentUser?.avatarUrl != null &&
                        currentUser!.avatarUrl!.isNotEmpty
                    ? Image.network(
                        currentUser.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: ThemeColors.getSurfaceColor(context),
                            child: Icon(
                              Icons.person,
                              size: 35,
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: ThemeColors.getSurfaceColor(context),
                        child: Icon(
                          Icons.person,
                          size: 35,
                          color: ThemeColors.getSecondaryTextColor(context),
                        ),
                      ),
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
                Text(
                  currentUser?.email ?? '',
                  style: TextThemes.getBodySmallStyle(context).copyWith(
                    color: ThemeColors.getSecondaryTextColor(context),
                    fontSize: 13,
                  ),
                ),
                if (currentUser?.bio != null &&
                    currentUser!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    currentUser!.bio!,
                    style: TextThemes.getBodySmallStyle(context).copyWith(
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Edit button with gradient
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryColor.withOpacity(0.2),
                  ThemeColors.primaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: IconButton(
              onPressed: () => _showEditProfileDialog(currentUser),
              icon: const Icon(Icons.edit_rounded),
              color: ThemeColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build settings section
  Widget _buildSection(String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextThemes.getBodyMediumStyle(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: ThemeColors.primaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: ThemeColors.getCardColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: ThemeColors.getBorderColor(context).withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : ThemeColors.getOverlayColor(context, opacity: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Build settings tile
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (textColor ?? ThemeColors.primaryColor).withOpacity(0.15),
                    (textColor ?? ThemeColors.primaryColor).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: textColor ?? ThemeColors.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextThemes.getBodyMediumStyle(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 15,
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
            Icon(
              Icons.chevron_right_rounded,
              color: ThemeColors.getSecondaryTextColor(context),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Build switch tile
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryColor.withOpacity(0.15),
                  ThemeColors.primaryColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ThemeColors.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeColors.primaryColor,
          ),
        ],
      ),
    );
  }

  /// Show edit profile dialog
  void _showEditProfileDialog(currentUser) {
    final nameController = TextEditingController(text: currentUser?.name ?? '');
    final bioController = TextEditingController(text: currentUser?.bio ?? '');
    final emailController = TextEditingController(
      text: currentUser?.email ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(currentUserProfileProvider.notifier)
                  .updateProfile(
                    name: nameController.text,
                    email: emailController.text,
                    bio: bioController.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(currentUserProfileProvider.notifier).logout();
              Navigator.pop(context);
              // TODO: Navigate to login screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.getErrorColor(context),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Show delete account dialog
  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: ThemeColors.errorColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement account deletion
              Navigator.pop(context);
              SnackBarWidget.show(context, 'Account deletion requested');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.getErrorColor(context),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // Placeholder methods for additional functionality
  void _showEmailSettings() => _showComingSoon();
  void _showNotificationPreferences() => _showComingSoon();
  void _showPrivacySettings() => _showComingSoon();
  void _showBlockedUsers() => _showComingSoon();
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
