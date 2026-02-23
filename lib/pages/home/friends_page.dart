import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/pages/home/user_profile_view_page.dart';
import 'package:hosla/providers/friend_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/loading_widget.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  final TextEditingController _userIdController = TextEditingController();
  bool _isSending = false;

  void _logError(String contextLabel, Object error, StackTrace stackTrace) {
    debugPrint('FriendsPage:$contextLabel error: $error');
    debugPrint(stackTrace.toString());
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);
    final currentUser = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Friends & Requests'),
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(friendsListProvider.notifier).refresh();
          await ref.read(friendRequestsProvider.notifier).refresh();
        },
        color: ThemeColors.primaryColor,
        backgroundColor: ThemeColors.getSurfaceColor(context),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAddFriendCard(context),
            const SizedBox(height: 16),
            _buildRequestsCard(context, requestsAsync, currentUser?.id ?? ''),
            const SizedBox(height: 16),
            _buildFriendsCard(context, friendsAsync, currentUser?.id ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFriendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a friend',
            style: TextThemes.getTitleStyle(
              context,
            ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the user ID of the person you want to connect with.',
            style: TextThemes.getBodyMediumStyle(
              context,
            ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userIdController,
            decoration: InputDecoration(
              hintText: 'e.g. user-uuid',
              filled: true,
              fillColor: ThemeColors.getBackgroundColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeColors.getBorderColor(
                    context,
                  ).withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendRequest,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: _isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _viewUserById,
                icon: const Icon(Icons.person_search_rounded, size: 18),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsCard(
    BuildContext context,
    AsyncValue<List<FriendshipEdge>> requestsAsync,
    String currentUserId,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Requests',
                style: TextThemes.getTitleStyle(
                  context,
                ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    ref.read(friendRequestsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return Text(
                  'No pending requests',
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                );
              }
              return Column(
                children: requests.map((req) {
                  final isIncoming = req.receiverId.isEmpty
                      ? true
                      : req.receiverId == currentUserId;
                  final other = isIncoming
                      ? (req.requester ?? req.receiver)
                      : (req.receiver ?? req.requester);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: (other?.id.isNotEmpty == true)
                        ? () => _openUserProfile(other!.id, other.name)
                        : null,
                    leading: CircleAvatar(
                      backgroundColor: ThemeColors.primaryColor.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage: other?.profilePicUrl != null
                          ? NetworkImage(other!.profilePicUrl!)
                          : null,
                      child: other?.profilePicUrl == null
                          ? Icon(Icons.person, color: ThemeColors.primaryColor)
                          : null,
                    ),
                    title: Text(other?.name ?? 'Unknown'),
                    subtitle: Text(isIncoming ? 'Wants to connect' : 'Sent'),
                    trailing: isIncoming
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _reject(req.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle),
                                color: ThemeColors.primaryColor,
                                onPressed: () => _accept(req.id),
                              ),
                            ],
                          )
                        : const Text('Pending'),
                  );
                }).toList(),
              );
            },
            loading: () => const LoadingWidget(message: 'Loading requests...'),
            error: (e, st) {
              _logError('load_requests', e, st);
              return Text(
                'Unable to load requests. Please try again.',
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(color: ThemeColors.errorColor),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsCard(
    BuildContext context,
    AsyncValue<List<FriendshipEdge>> friendsAsync,
    String currentUserId,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.getBorderColor(context).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your friends',
                style: TextThemes.getTitleStyle(
                  context,
                ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    ref.read(friendsListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          friendsAsync.when(
            data: (friends) {
              if (friends.isEmpty) {
                return Text(
                  'No friends yet. Send a request to get started!',
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                );
              }
              return Column(
                children: friends.map((edge) {
                  final other = edge.otherParty(currentUserId);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: (other?.id.isNotEmpty == true)
                        ? () => _openUserProfile(other!.id, other.name)
                        : null,
                    leading: CircleAvatar(
                      backgroundColor: ThemeColors.primaryColor.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage: other?.profilePicUrl != null
                          ? NetworkImage(other!.profilePicUrl!)
                          : null,
                      child: other?.profilePicUrl == null
                          ? Icon(Icons.person, color: ThemeColors.primaryColor)
                          : null,
                    ),
                    title: Text(other?.name ?? 'Friend'),
                    subtitle: const Text('Accepted'),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => _showFriendOptions(edge.id),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const LoadingWidget(message: 'Loading friends...'),
            error: (e, st) {
              _logError('load_friends', e, st);
              return Text(
                'Unable to load friends. Please try again.',
                style: TextThemes.getBodyMediumStyle(
                  context,
                ).copyWith(color: ThemeColors.errorColor),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) return;

    setState(() => _isSending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(friendActionsProvider).sendRequest(userId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
      _userIdController.clear();
      await ref.read(friendRequestsProvider.notifier).refresh();
    } catch (e, st) {
      _logError('send_request', e, st);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to send request. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _viewUserById() {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showErrorSnackBar('Enter a user ID first');
      return;
    }
    _openUserProfile(userId, null);
  }

  void _openUserProfile(String userId, String? initialName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserProfileViewPage(userId: userId, initialName: initialName),
      ),
    );
  }

  Future<void> _accept(String friendshipId) async {
    try {
      await ref.read(friendActionsProvider).accept(friendshipId);
    } catch (e, st) {
      _logError('accept_request', e, st);
      _showErrorSnackBar('Failed to accept request. Please try again.');
    }
  }

  Future<void> _reject(String friendshipId) async {
    try {
      await ref.read(friendActionsProvider).reject(friendshipId);
    } catch (e, st) {
      _logError('reject_request', e, st);
      _showErrorSnackBar('Failed to reject request. Please try again.');
    }
  }

  void _showFriendOptions(String friendshipId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeColors.getSurfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove_alt_1),
              title: const Text('Remove friend'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ref
                      .read(friendActionsProvider)
                      .removeFriend(friendshipId);
                } catch (e, st) {
                  _logError('remove_friend', e, st);
                  if (mounted) {
                    _showErrorSnackBar(
                      'Failed to remove friend. Please try again.',
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Close'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
