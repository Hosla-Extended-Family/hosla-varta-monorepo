import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/providers/friend_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/widgets/friend_button.dart';

/// Immutable snapshot of the friendship between the current user and a target.
class FriendshipStatusState {
  final FriendshipState state;
  final String? friendshipId;

  const FriendshipStatusState({required this.state, this.friendshipId});

  FriendshipStatusState copyWith({
    FriendshipState? state,
    String? friendshipId,
  }) {
    return FriendshipStatusState(
      state: state ?? this.state,
      friendshipId: friendshipId ?? this.friendshipId,
    );
  }
}

/// Per-user friendship status provider that derives from the friends &
/// requests lists and exposes action methods with optimistic updates.
///
/// Uses ref.listen (not ref.watch) for friends/requests so the notifier is
/// NOT recreated every time those lists reload.  This preserves optimistic
/// state (e.g. "Request Sent") across navigation and list refreshes.
final friendshipStatusProvider = StateNotifierProvider.family<
    FriendshipStatusNotifier,
    AsyncValue<FriendshipStatusState>,
    String>((ref, targetUserId) {
  final currentUser = ref.watch(currentUserProfileProvider);

  final notifier = FriendshipStatusNotifier(
    ref: ref,
    targetUserId: targetUserId,
    currentUserId: currentUser?.id ?? '',
  );

  // Listen (not watch) so the notifier object is stable.
  ref.listen<AsyncValue<List<FriendshipEdge>>>(friendsListProvider, (_, __) {
    notifier._syncFromProviders();
  });
  ref.listen<AsyncValue<List<FriendshipEdge>>>(friendRequestsProvider,
      (_, __) {
    notifier._syncFromProviders();
  });

  // Initial resolve from whatever data is already available.
  notifier._syncFromProviders();

  return notifier;
});

class FriendshipStatusNotifier
    extends StateNotifier<AsyncValue<FriendshipStatusState>> {
  final Ref ref;
  final String targetUserId;
  final String currentUserId;

  FriendshipStatusNotifier({
    required this.ref,
    required this.targetUserId,
    required this.currentUserId,
  }) : super(const AsyncValue.loading());

  /// Re-derive state from the current friends & requests providers.
  /// Only resolves when BOTH providers have loaded data; otherwise keeps
  /// whatever state we already have (preserving optimistic updates).
  void _syncFromProviders() {
    final friendsAsync = ref.read(friendsListProvider);
    final requestsAsync = ref.read(friendRequestsProvider);

    final friends = friendsAsync.whenOrNull(data: (d) => d);
    final requests = requestsAsync.whenOrNull(data: (d) => d);

    if (friends != null && requests != null) {
      resolveFromLists(friends, requests);
    }
    // If either list is still loading, keep the current state untouched.
  }

  /// Derive friendship state from the already-loaded friends + requests lists.
  void resolveFromLists(
    List<FriendshipEdge> friends,
    List<FriendshipEdge> requests,
  ) {
    if (currentUserId.isNotEmpty && currentUserId == targetUserId) {
      state = const AsyncValue.data(
        FriendshipStatusState(state: FriendshipState.self),
      );
      return;
    }

    // Check accepted friends
    final friendEdge = friends.cast<FriendshipEdge?>().firstWhere(
      (e) => e!.requesterId == targetUserId || e.receiverId == targetUserId,
      orElse: () => null,
    );
    if (friendEdge != null) {
      state = AsyncValue.data(
        FriendshipStatusState(
          state: FriendshipState.friend,
          friendshipId: friendEdge.id,
        ),
      );
      return;
    }

    // Check pending requests
    final requestEdge = requests.cast<FriendshipEdge?>().firstWhere(
      (e) => e!.requesterId == targetUserId || e.receiverId == targetUserId,
      orElse: () => null,
    );
    if (requestEdge != null) {
      final isOutgoing = requestEdge.requesterId == currentUserId;
      state = AsyncValue.data(
        FriendshipStatusState(
          state: isOutgoing
              ? FriendshipState.outgoing
              : FriendshipState.incoming,
          friendshipId: requestEdge.id,
        ),
      );
      return;
    }

    state = const AsyncValue.data(
      FriendshipStatusState(state: FriendshipState.none),
    );
  }

  // ── Actions with optimistic UI ─────────────────────────────────

  Future<void> sendRequest() async {
    // Optimistic
    state = const AsyncValue.data(
      FriendshipStatusState(state: FriendshipState.outgoing),
    );
    try {
      await ref.read(friendActionsProvider).sendRequest(targetUserId);
      // Re-derive after server sync
      _refreshLists();
    } catch (e) {
      // Rollback
      state = const AsyncValue.data(
        FriendshipStatusState(state: FriendshipState.none),
      );
    }
  }

  Future<void> cancelRequest() async {
    final prevState = state;
    final fId = prevState.value?.friendshipId;
    state = const AsyncValue.data(
      FriendshipStatusState(state: FriendshipState.none),
    );
    try {
      if (fId != null && fId.isNotEmpty) {
        await ref.read(friendActionsProvider).reject(fId);
      }
      _refreshLists();
    } catch (e) {
      state = prevState;
    }
  }

  Future<void> acceptRequest() async {
    final fId = state.value?.friendshipId;
    state = const AsyncValue.data(
      FriendshipStatusState(state: FriendshipState.friend),
    );
    try {
      if (fId != null && fId.isNotEmpty) {
        await ref.read(friendActionsProvider).accept(fId);
      }
      _refreshLists();
    } catch (e) {
      state = AsyncValue.data(
        FriendshipStatusState(
          state: FriendshipState.incoming,
          friendshipId: fId,
        ),
      );
    }
  }

  Future<void> rejectRequest() async {
    final fId = state.value?.friendshipId;
    state = const AsyncValue.data(
      FriendshipStatusState(state: FriendshipState.none),
    );
    try {
      if (fId != null && fId.isNotEmpty) {
        await ref.read(friendActionsProvider).reject(fId);
      }
      _refreshLists();
    } catch (e) {
      state = AsyncValue.data(
        FriendshipStatusState(
          state: FriendshipState.incoming,
          friendshipId: fId,
        ),
      );
    }
  }

  Future<void> removeFriend() async {
    final fId = state.value?.friendshipId;
    state = const AsyncValue.data(
      FriendshipStatusState(state: FriendshipState.none),
    );
    try {
      if (fId != null && fId.isNotEmpty) {
        await ref.read(friendActionsProvider).removeFriend(fId);
      }
      _refreshLists();
    } catch (e) {
      state = AsyncValue.data(
        FriendshipStatusState(state: FriendshipState.friend, friendshipId: fId),
      );
    }
  }

  void _refreshLists() {
    ref.read(friendsListProvider.notifier).refresh();
    ref.read(friendRequestsProvider.notifier).refresh();
  }
}
