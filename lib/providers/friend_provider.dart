import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/services/friend_service.dart';

/// Provider for FriendService
final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

/// Accepted friends list
final friendsListProvider =
    StateNotifierProvider<FriendsNotifier, AsyncValue<List<FriendshipEdge>>>(
      (ref) => FriendsNotifier(ref.read(friendServiceProvider)),
    );

/// Pending requests list (incoming/outgoing)
final friendRequestsProvider =
    StateNotifierProvider<
      FriendRequestsNotifier,
      AsyncValue<List<FriendshipEdge>>
    >((ref) => FriendRequestsNotifier(ref.read(friendServiceProvider)));

/// User profile visibility-aware provider
final userProfileVisibilityProvider =
    FutureProvider.family<UserProfileVisibilityResult, String>((
      ref,
      userId,
    ) async {
      final service = ref.read(friendServiceProvider);
      return service.getUserProfile(userId);
    });

class FriendsNotifier extends StateNotifier<AsyncValue<List<FriendshipEdge>>> {
  final FriendService _service;

  FriendsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final friends = await _service.listFriends();
      state = AsyncValue.data(friends);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();

  Future<void> remove(String friendshipId) async {
    final success = await _service.removeFriend(friendshipId);
    if (success) {
      state.whenData((items) {
        state = AsyncValue.data(
          items.where((edge) => edge.id != friendshipId).toList(),
        );
      });
    }
  }
}

class FriendRequestsNotifier
    extends StateNotifier<AsyncValue<List<FriendshipEdge>>> {
  final FriendService _service;

  FriendRequestsNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final pending = await _service.listPendingRequests();
      state = AsyncValue.data(pending);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();

  Future<void> accept(String friendshipId) async {
    await _service.acceptRequest(friendshipId);
    await load();
  }

  Future<void> reject(String friendshipId) async {
    await _service.rejectRequest(friendshipId);
    await load();
  }

  Future<void> addOutgoing(FriendshipEdge edge) async {
    state.whenData((items) {
      state = AsyncValue.data([edge, ...items]);
    });
  }
}

class FriendActions {
  final Ref ref;
  final FriendService _service;

  FriendActions(this.ref) : _service = ref.read(friendServiceProvider);

  Future<void> sendRequest(String userId) async {
    final edge = await _service.sendFriendRequest(userId);
    await ref.read(friendRequestsProvider.notifier).addOutgoing(edge);
    await ref.read(friendRequestsProvider.notifier).refresh();
  }

  Future<void> accept(String friendshipId) async {
    await _service.acceptRequest(friendshipId);
    await ref.read(friendRequestsProvider.notifier).refresh();
    await ref.read(friendsListProvider.notifier).refresh();
  }

  Future<void> reject(String friendshipId) async {
    await _service.rejectRequest(friendshipId);
    await ref.read(friendRequestsProvider.notifier).refresh();
  }

  Future<void> removeFriend(String friendshipId) async {
    final ok = await _service.removeFriend(friendshipId);
    if (ok) {
      await ref.read(friendsListProvider.notifier).refresh();
    }
  }
}

final friendActionsProvider = Provider<FriendActions>(
  (ref) => FriendActions(ref),
);
