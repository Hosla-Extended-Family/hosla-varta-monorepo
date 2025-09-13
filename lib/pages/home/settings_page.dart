import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/profile_pic.dart';

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
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.navBarColor,
        elevation: 1,
        title: Text(
          'Settings',
          style: TextThemes.title.copyWith(fontSize: 20),
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
            _buildSection(
              'Account',
              [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Update your profile information',
                  onTap: () => _showEditProfileDialog(currentUser),
                ),
                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => _showChangePasswordDialog(),
                ),
                _buildSettingsTile(
                  icon: Icons.email_outlined,
                  title: 'Email Settings',
                  subtitle: 'Manage email preferences',
                  onTap: () => _showEmailSettings(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Notifications Settings
            _buildSection(
              'Notifications',
              [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications',
                  value: appSettings.notificationsEnabled,
                  onChanged: (value) {
                    ref.read(appSettingsProvider.notifier).updateNotifications(value);
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
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Privacy Settings
            _buildSection(
              'Privacy & Security',
              [
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
                    ref.read(appSettingsProvider.notifier).updatePrivateProfile(value);
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
              ],
            ),
            
            const SizedBox(height: 24),
            
            // App Settings
            _buildSection(
              'App Settings',
              [
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Enable dark theme',
                  value: appSettings.darkMode,
                  onChanged: (value) {
                    ref.read(appSettingsProvider.notifier).updateDarkMode(value);
                  },
                ),
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
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Support Settings
            _buildSection(
              'Support',
              [
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
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Data Management
            _buildSection(
              'Data',
              [
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
                  textColor: Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
    return Container(
      padding: Constants.defaultPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile picture
          ProfilePic(
            radius: 35,
            imageUrl: currentUser?.avatarUrl ?? '',
          ),
          
          const SizedBox(width: 16),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.name ?? 'Loading...',
                  style: TextThemes.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser?.email ?? '',
                  style: TextThemes.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (currentUser?.bio != null && currentUser!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    currentUser!.bio!,
                    style: TextThemes.bodySmall.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Edit button
          IconButton(
            onPressed: () => _showEditProfileDialog(currentUser),
            icon: const Icon(Icons.edit, color: ThemeColors.primaryColor),
          ),
        ],
      ),
    );
  }

  /// Build settings section
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextThemes.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeColors.secondaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? ThemeColors.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: textColor ?? ThemeColors.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextThemes.bodyMedium.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextThemes.bodySmall.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ThemeColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: ThemeColors.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextThemes.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextThemes.bodySmall.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: ThemeColors.primaryColor,
      ),
    );
  }

  /// Show edit profile dialog
  void _showEditProfileDialog(currentUser) {
    final nameController = TextEditingController(text: currentUser?.name ?? '');
    final bioController = TextEditingController(text: currentUser?.bio ?? '');
    final emailController = TextEditingController(text: currentUser?.email ?? '');

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
              ref.read(currentUserProfileProvider.notifier).updateProfile(
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

  /// Show change password dialog
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
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
              if (newPasswordController.text == confirmPasswordController.text) {
                // TODO: Implement password change
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match!')),
                );
              }
            },
            child: const Text('Update'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
              style: TextStyle(color: Colors.red),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requested'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
