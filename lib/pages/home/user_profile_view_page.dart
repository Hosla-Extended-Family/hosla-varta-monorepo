import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/providers/friend_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/loading_widget.dart';

enum _RelationshipStatus { self, friend, incoming, outgoing, none }

class UserProfileViewPage extends ConsumerStatefulWidget {
  final String userId;
  final String? initialName;
  final String? initialAvatarUrl;

  const UserProfileViewPage({
    super.key,
    required this.userId,
    this.initialName,
    this.initialAvatarUrl,
  });

  @override
  ConsumerState<UserProfileViewPage> createState() =>
      _UserProfileViewPageState();
}

class _UserProfileViewPageState extends ConsumerState<UserProfileViewPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(
      userProfileVisibilityProvider(widget.userId),
    );
    final currentUser = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: ThemeColors.getBackgroundColor(context),
      body: profileAsync.when(
        data: (profile) {
          final List<FriendshipEdge> friends = ref
              .watch(friendsListProvider)
              .maybeWhen(
                data: (data) => data,
                orElse: () => const <FriendshipEdge>[],
              );
          final List<FriendshipEdge> requests = ref
              .watch(friendRequestsProvider)
              .maybeWhen(
                data: (data) => data,
                orElse: () => const <FriendshipEdge>[],
              );

          final statusDetails = _resolveStatus(
            currentUserId: currentUser?.id ?? '',
            profileUserId: profile.user.id,
            friends: friends,
            requests: requests,
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                stretch: true,
                backgroundColor: ThemeColors.getNavBarColor(context),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
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
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildAvatar(profile.user.profilePicUrl),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profile.user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Quicksand',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _visibilityChip(profile.visibility),
                                      const SizedBox(width: 8),
                                      if (profile.role != null)
                                        _roleChip(profile.role!),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.bio != null && profile.bio!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ThemeColors.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ThemeColors.getBorderColor(
                                context,
                              ).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            profile.bio!,
                            style: TextThemes.getBodyMediumStyle(context),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildActions(context, statusDetails),
                      const SizedBox(height: 24),
                      _buildMetaTiles(context, profile),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: LoadingWidget(message: 'Loading profile...')),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: ThemeColors.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Profile unavailable',
                  style: TextThemes.getTitleStyle(context),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextThemes.getBodyMediumStyle(
                    context,
                  ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: ClipOval(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholderAvatar(),
          ),
        ),
      );
    }
    return _placeholderAvatar();
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ThemeColors.primaryColor.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(Icons.person, color: ThemeColors.primaryColor, size: 40),
    );
  }

  Widget _visibilityChip(String visibility) {
    final isFriendsOnly = visibility.toUpperCase() == 'FRIENDS';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isFriendsOnly ? Colors.orange : Colors.green).withValues(
          alpha: 0.15,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFriendsOnly ? Icons.group : Icons.public,
            size: 14,
            color: isFriendsOnly ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            isFriendsOnly ? 'Friends' : 'Public',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ThemeColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Colors.blue, size: 14),
          const SizedBox(width: 6),
          Text(role, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, _StatusDetails status) {
    switch (status.status) {
      case _RelationshipStatus.self:
        return const SizedBox.shrink();
      case _RelationshipStatus.friend:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Friends'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeColors.primaryColor,
                  side: BorderSide(color: ThemeColors.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: status.friendshipId == null
                  ? null
                  : () => _removeFriend(status.friendshipId!),
              icon: const Icon(Icons.person_remove_alt_1),
              tooltip: 'Remove friend',
            ),
          ],
        );
      case _RelationshipStatus.incoming:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing || status.friendshipId == null
                    ? null
                    : () => _accept(status.friendshipId!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Accept Request'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _isProcessing || status.friendshipId == null
                  ? null
                  : () => _reject(status.friendshipId!),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeColors.getTextColor(context),
                side: BorderSide(
                  color: ThemeColors.getBorderColor(
                    context,
                  ).withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      case _RelationshipStatus.outgoing:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_top),
          label: const Text('Requested'),
          style: OutlinedButton.styleFrom(
            disabledForegroundColor: ThemeColors.getSecondaryTextColor(context),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      case _RelationshipStatus.none:
        return ElevatedButton.icon(
          onPressed: _isProcessing ? null : _sendRequest,
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add Friend'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
    }
  }

  Widget _buildMetaTiles(
    BuildContext context,
    UserProfileVisibilityResult profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Details',
          style: TextThemes.getTitleStyle(
            context,
          ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: ThemeColors.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ThemeColors.getBorderColor(
                context,
              ).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              _tile(
                context,
                icon: Icons.person_outline,
                label: 'Name',
                value: profile.user.name,
              ),
              _divider(context),
              _tile(
                context,
                icon: Icons.public,
                label: 'Visibility',
                value: profile.visibility.toUpperCase() == 'FRIENDS'
                    ? 'Friends only'
                    : 'Public',
              ),
              if (profile.role != null) ...[
                _divider(context),
                _tile(
                  context,
                  icon: Icons.shield_moon_outlined,
                  label: 'Role',
                  value: profile.role!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: ThemeColors.primaryColor),
      title: Text(
        label,
        style: TextThemes.getBodySmallStyle(
          context,
        ).copyWith(color: ThemeColors.getSecondaryTextColor(context)),
      ),
      subtitle: Text(value, style: TextThemes.getBodyMediumStyle(context)),
    );
  }

  Widget _divider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: ThemeColors.getBorderColor(context).withValues(alpha: 0.2),
        height: 1,
      ),
    );
  }

  Future<void> _sendRequest() async {
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(friendActionsProvider).sendRequest(widget.userId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Friend request sent')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _accept(String friendshipId) async {
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(friendActionsProvider).accept(friendshipId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Friend request accepted')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject(String friendshipId) async {
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(friendActionsProvider).reject(friendshipId);
      messenger.showSnackBar(const SnackBar(content: Text('Request rejected')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _removeFriend(String friendshipId) async {
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(friendActionsProvider).removeFriend(friendshipId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Removed from friends')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  _StatusDetails _resolveStatus({
    required String currentUserId,
    required String profileUserId,
    required List<FriendshipEdge> friends,
    required List<FriendshipEdge> requests,
  }) {
    if (currentUserId.isNotEmpty && currentUserId == profileUserId) {
      return const _StatusDetails(_RelationshipStatus.self, null);
    }

    final friendEdge = friends.firstWhere(
      (edge) =>
          edge.requesterId == profileUserId || edge.receiverId == profileUserId,
      orElse: () => const FriendshipEdge(
        id: '',
        requesterId: '',
        receiverId: '',
        status: 'NONE',
      ),
    );

    if (friendEdge.id.isNotEmpty) {
      return _StatusDetails(_RelationshipStatus.friend, friendEdge.id);
    }

    final requestEdge = requests.firstWhere(
      (edge) =>
          edge.requesterId == profileUserId || edge.receiverId == profileUserId,
      orElse: () => const FriendshipEdge(
        id: '',
        requesterId: '',
        receiverId: '',
        status: 'NONE',
      ),
    );

    if (requestEdge.id.isNotEmpty) {
      if (requestEdge.requesterId == currentUserId) {
        return _StatusDetails(_RelationshipStatus.outgoing, requestEdge.id);
      }
      return _StatusDetails(_RelationshipStatus.incoming, requestEdge.id);
    }

    return const _StatusDetails(_RelationshipStatus.none, null);
  }
}

class _StatusDetails {
  final _RelationshipStatus status;
  final String? friendshipId;
  const _StatusDetails(this.status, this.friendshipId);
}
