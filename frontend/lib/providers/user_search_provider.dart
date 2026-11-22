import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/providers/friend_provider.dart';

/// Holds the current search query text (debounced externally).
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Paginated search state.
class UserSearchState {
  final List<SearchUserResult> users;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;

  const UserSearchState({
    this.users = const [],
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.error,
  });

  UserSearchState copyWith({
    List<SearchUserResult>? users,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
  }) {
    return UserSearchState(
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Notifier for paginated user search.
class UserSearchNotifier extends StateNotifier<AsyncValue<UserSearchState>> {
  final Ref ref;
  static const int _pageSize = 20;

  UserSearchNotifier(this.ref)
    : super(const AsyncValue.data(UserSearchState()));

  /// Perform a fresh search (page 1).
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data(UserSearchState());
      return;
    }

    state = const AsyncValue.loading();

    try {
      final service = ref.read(friendServiceProvider);
      final response = await service.searchUsers(
        query,
        page: 1,
        limit: _pageSize,
      );
      state = AsyncValue.data(
        UserSearchState(
          users: response.users,
          currentPage: 1,
          hasMore: response.hasMore,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load the next page of results.
  Future<void> loadMore(String query) async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final service = ref.read(friendServiceProvider);
      final nextPage = current.currentPage + 1;
      final response = await service.searchUsers(
        query,
        page: nextPage,
        limit: _pageSize,
      );
      state = AsyncValue.data(
        current.copyWith(
          users: [...current.users, ...response.users],
          currentPage: nextPage,
          hasMore: response.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  /// Clear search results.
  void clear() {
    state = const AsyncValue.data(UserSearchState());
  }
}

/// Global search notifier provider.
final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, AsyncValue<UserSearchState>>(
      (ref) => UserSearchNotifier(ref),
    );
