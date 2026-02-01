import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/models/user_model.dart';

/// WhatsApp-style contact info page showing user profile and mutual groups
class ContactInfoPage extends ConsumerWidget {
  final User user;
  final List<String>? mutualGroups;

  const ContactInfoPage({super.key, required this.user, this.mutualGroups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
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
              'Contact Info',
              style: TextThemes.getBodyLargeStyle(
                context,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: ThemeColors.getNavBarIconColor(context),
                ),
                onPressed: () => _showMoreOptions(context),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Section
                Container(
                  width: double.infinity,
                  color: ThemeColors.getSurfaceColor(context),
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: () => _viewFullImage(context),
                        child: Hero(
                          tag: 'contact_${user.id}',
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ThemeColors.primaryColor,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child:
                                  user.avatarUrl != null &&
                                      user.avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      user.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return _buildDefaultAvatar(context);
                                          },
                                    )
                                  : _buildDefaultAvatar(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        user.name,
                        style: TextThemes.getTitleStyle(
                          context,
                        ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // Phone or Email
                      if (user.email != null && user.email!.isNotEmpty)
                        Text(
                          user.email!,
                          style: TextThemes.getBodyMediumStyle(context)
                              .copyWith(
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ),
                              ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Bio Section
                if (user.bio != null && user.bio!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: ThemeColors.getSurfaceColor(context),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: TextThemes.getBodySmallStyle(context).copyWith(
                            color: ThemeColors.getSecondaryTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.bio!,
                          style: TextThemes.getBodyMediumStyle(context),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Media, Links, Docs
                _buildSection(
                  context,
                  children: [
                    _buildTile(
                      context,
                      icon: Icons.image_outlined,
                      title: 'Media, Links, and Docs',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '0',
                            style: TextThemes.getBodyMediumStyle(context)
                                .copyWith(
                                  color: ThemeColors.getSecondaryTextColor(
                                    context,
                                  ),
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: ThemeColors.getSecondaryTextColor(context),
                          ),
                        ],
                      ),
                      onTap: () {
                        // TODO: Show media
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 72,
                      color: ThemeColors.getBorderColor(
                        context,
                      ).withValues(alpha: 0.3),
                    ),
                    _buildTile(
                      context,
                      icon: Icons.star_border,
                      title: 'Starred Messages',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                      onTap: () {
                        // TODO: Show starred messages
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 72,
                      color: ThemeColors.getBorderColor(
                        context,
                      ).withValues(alpha: 0.3),
                    ),
                    _buildTile(
                      context,
                      icon: Icons.search,
                      title: 'Search in Chat',
                      trailing: Icon(
                        Icons.chevron_right,
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                      onTap: () {
                        // TODO: Search
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Mutual Groups
                if (mutualGroups != null && mutualGroups!.isNotEmpty)
                  _buildSection(
                    context,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${mutualGroups!.length} group${mutualGroups!.length > 1 ? 's' : ''} in common',
                              style: TextThemes.getBodyMediumStyle(context)
                                  .copyWith(
                                    color: ThemeColors.getSecondaryTextColor(
                                      context,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ...mutualGroups!.map(
                        (group) => Column(
                          children: [
                            _buildTile(
                              context,
                              icon: Icons.group,
                              title: group,
                              trailing: Icon(
                                Icons.chevron_right,
                                color: ThemeColors.getSecondaryTextColor(
                                  context,
                                ),
                              ),
                              onTap: () {
                                // TODO: Open group
                              },
                            ),
                            if (group != mutualGroups!.last)
                              Divider(
                                height: 1,
                                indent: 72,
                                color: ThemeColors.getBorderColor(
                                  context,
                                ).withValues(alpha: 0.3),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                // Actions
                _buildSection(
                  context,
                  children: [
                    _buildTile(
                      context,
                      icon: Icons.block,
                      title: 'Block ${user.name.split(' ').first}',
                      iconColor: ThemeColors.errorColor,
                      titleColor: ThemeColors.errorColor,
                      onTap: () {
                        _showBlockDialog(context);
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 72,
                      color: ThemeColors.getBorderColor(
                        context,
                      ).withValues(alpha: 0.3),
                    ),
                    _buildTile(
                      context,
                      icon: Icons.thumb_down_outlined,
                      title: 'Report Contact',
                      iconColor: ThemeColors.errorColor,
                      titleColor: ThemeColors.errorColor,
                      onTap: () {
                        _showReportDialog(context);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      color: ThemeColors.getSurfaceColor(context),
      child: Icon(
        Icons.person,
        size: 60,
        color: ThemeColors.getSecondaryTextColor(context),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      color: ThemeColors.getSurfaceColor(context),
      child: Column(children: children),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? ThemeColors.getSecondaryTextColor(context),
              size: 24,
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Text(
                title,
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(color: titleColor, fontSize: 16),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _viewFullImage(BuildContext context) {
    if (user.avatarUrl == null || user.avatarUrl!.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(user.avatarUrl!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Contact'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share contact
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Contact'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Edit contact
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block ${user.name.split(' ').first}?',
          style: TextThemes.getBodyLargeStyle(
            context,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Blocked contacts will no longer be able to message you.',
          style: TextThemes.getBodyMediumStyle(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Block user
            },
            child: Text(
              'Block',
              style: TextStyle(color: ThemeColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report this contact?',
          style: TextThemes.getBodyLargeStyle(
            context,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'The last 5 messages will be forwarded to Hosla Varta. This contact will not be notified.',
          style: TextThemes.getBodyMediumStyle(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Report user
            },
            child: Text(
              'Report',
              style: TextStyle(color: ThemeColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
