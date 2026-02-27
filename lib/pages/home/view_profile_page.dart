import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/models/user_model.dart';

/// View profile page for viewing other users' profiles (WhatsApp-style)
class ViewProfilePage extends ConsumerWidget {
  final User user;

  const ViewProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // App bar with profile picture
          SliverAppBar(
            expandedHeight: 350,
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
                icon: Icon(
                  Icons.more_vert,
                  color: ThemeColors.getTextColor(context),
                ),
                onPressed: () => _showMoreOptions(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: ThemeColors.getSurfaceColor(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    // Profile Picture
                    GestureDetector(
                      onTap: () => _viewFullImage(context),
                      child: Hero(
                        tag: 'profile_${user.id}',
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                ThemeColors.primaryColor,
                                ThemeColors.primaryColor.withBlue(200),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ThemeColors.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ThemeColors.getSurfaceColor(context),
                              border: Border.all(
                                color: ThemeColors.getSurfaceColor(context),
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
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Text(
                      user.name,
                      style: TextThemes.getTitleStyle(
                        context,
                      ).copyWith(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Online Status
                    _buildOnlineStatus(context),
                  ],
                ),
              ),
            ),
          ),

          // Profile Information
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Bio Section
                if (user.bio != null && user.bio!.isNotEmpty)
                  _buildInfoSection(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    content: user.bio!,
                  ),

                // Email Section
                if (user.email != null && user.email!.isNotEmpty)
                  _buildInfoSection(
                    context,
                    icon: Icons.email_outlined,
                    title: 'Email',
                    content: user.email!,
                  ),

                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(context),

                const SizedBox(height: 16),

                // Media, Links, Documents Section
                _buildMediaSection(context),

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

  Widget _buildOnlineStatus(BuildContext context) {
    if (user.isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Online',
              style: TextThemes.getBodySmallStyle(
                context,
              ).copyWith(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    } else {
      final lastSeen = user.lastSeen;
      final lastSeenText = lastSeen != null
          ? _formatLastSeen(lastSeen)
          : 'Offline';

      return Text(
        lastSeenText,
        style: TextThemes.getBodyMediumStyle(
          context,
        ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
      );
    }
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryColor.withValues(alpha: 0.15),
                  ThemeColors.primaryColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
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
                  style: TextThemes.getBodySmallStyle(context).copyWith(
                    color: ThemeColors.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Message Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate back to chat or create new chat
                Navigator.pop(context);
              },
              icon: const Icon(Icons.message_rounded, size: 20),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Call Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryColor.withValues(alpha: 0.15),
                  ThemeColors.primaryColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Implement voice call
              },
              icon: const Icon(Icons.call),
              color: ThemeColors.primaryColor,
              iconSize: 24,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 12),
          // Video Call Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.primaryColor.withValues(alpha: 0.15),
                  ThemeColors.primaryColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Implement video call
              },
              icon: const Icon(Icons.videocam),
              color: ThemeColors.primaryColor,
              iconSize: 24,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThemeColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildMediaTile(
            context,
            icon: Icons.photo_library_outlined,
            title: 'Media, Links, and Docs',
            subtitle: '0 items',
            onTap: () {
              // TODO: Show media gallery
            },
          ),
          Divider(
            height: 1,
            indent: 68,
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.2),
          ),
          _buildMediaTile(
            context,
            icon: Icons.star_outline,
            title: 'Starred Messages',
            subtitle: '0 messages',
            onTap: () {
              // TODO: Show starred messages
            },
          ),
          Divider(
            height: 1,
            indent: 68,
            color: ThemeColors.getBorderColor(context).withValues(alpha: 0.2),
          ),
          _buildMediaTile(
            context,
            icon: Icons.search,
            title: 'Search in Chat',
            onTap: () {
              // TODO: Search in chat
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeColors.primaryColor.withValues(alpha: 0.15),
                    ThemeColors.primaryColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
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
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextThemes.getBodySmallStyle(context).copyWith(
                        color: ThemeColors.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
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
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Contact'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share contact
              },
            ),
            ListTile(
              leading: Icon(
                Icons.block_outlined,
                color: ThemeColors.errorColor,
              ),
              title: Text(
                'Block',
                style: TextStyle(color: ThemeColors.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Block user
              },
            ),
            ListTile(
              leading: Icon(
                Icons.report_outlined,
                color: ThemeColors.errorColor,
              ),
              title: Text(
                'Report',
                style: TextStyle(color: ThemeColors.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Report user
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inHours < 1) {
      return 'Last seen ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 1) {
      return 'Last seen ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Last seen a while ago';
    }
  }
}
