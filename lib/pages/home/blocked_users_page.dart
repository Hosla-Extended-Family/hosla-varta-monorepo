import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/widgets/profile_pic.dart';

class BlockedUsersPage extends ConsumerStatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  ConsumerState<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends ConsumerState<BlockedUsersPage> {
  // TODO: Replace with actual blocked users provider
  final List<Map<String, String>> _blockedUsers = [
    {'id': '1', 'name': 'John Doe', 'username': '@johndoe', 'avatarUrl': ''},
    {
      'id': '2',
      'name': 'Jane Smith',
      'username': '@janesmith',
      'avatarUrl': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          'Blocked Users',
          style: TextThemes.getTitleStyle(
            context,
          ).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: _blockedUsers.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _blockedUsers.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 80,
                color: ThemeColors.getBorderColor(
                  context,
                ).withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                return _buildBlockedUserTile(user);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_outlined,
            size: 80,
            color: ThemeColors.getSecondaryTextColor(
              context,
            ).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Blocked Users',
            style: TextThemes.getTitleStyle(
              context,
            ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Users you block will appear here',
              style: TextThemes.getBodyMediumStyle(
                context,
              ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserTile(Map<String, String> user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ProfilePic(imageUrl: user['avatarUrl'] ?? '', radius: 28),
      title: Text(
        user['name'] ?? '',
        style: TextThemes.getBodyLargeStyle(
          context,
        ).copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        user['username'] ?? '',
        style: TextThemes.getBodySmallStyle(
          context,
        ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
      ),
      trailing: OutlinedButton(
        onPressed: () => _unblockUser(user['id'] ?? ''),
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeColors.primaryColor,
          side: BorderSide(color: ThemeColors.primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
        child: const Text(
          'Unblock',
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _unblockUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unblock User?',
          style: TextThemes.getTitleStyle(
            context,
          ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This user will be able to see your posts and message you.',
          style: TextThemes.getBodyMediumStyle(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Quicksand',
                color: ThemeColors.getSecondaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement unblock user logic
              setState(() {
                _blockedUsers.removeWhere((user) => user['id'] == userId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'User unblocked successfully',
                    style: TextStyle(fontFamily: 'Quicksand'),
                  ),
                  backgroundColor: ThemeColors.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: Text(
              'Unblock',
              style: TextStyle(
                fontFamily: 'Quicksand',
                color: ThemeColors.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
