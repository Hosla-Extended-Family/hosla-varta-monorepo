import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/services/local_post_repository.dart';
import 'package:hosla/services/post_service.dart';
import 'package:hosla/services/sync_service.dart';
import 'package:hosla/providers/feed_provider.dart' as feed;

/// Provider for PostService instance
final postServiceProvider = Provider<PostService>((ref) => PostService());

/// Provider for LocalPostRepository instance
final localPostRepositoryProvider = Provider<LocalPostRepository>(
  (ref) => LocalPostRepository(),
);

/// Provider for SyncService instance
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

/// Provider for user posts
final userPostsProvider =
    StateNotifierProvider.family<
      UserPostsNotifier,
      AsyncValue<List<Post>>,
      String
    >((ref, userId) {
      return UserPostsNotifier(
        userId: userId,
        postService: ref.read(postServiceProvider),
        localRepo: ref.read(localPostRepositoryProvider),
        syncService: ref.read(syncServiceProvider),
      );
    });

/// Provider for saved posts
final savedPostsProvider =
    StateNotifierProvider<SavedPostsNotifier, AsyncValue<List<Post>>>((ref) {
      return SavedPostsNotifier(
        localRepo: ref.read(localPostRepositoryProvider),
      );
    });

/// Notifier for managing user posts
class UserPostsNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final String userId;
  final PostService postService;
  final LocalPostRepository localRepo;
  final SyncService syncService;

  UserPostsNotifier({
    required this.userId,
    required this.postService,
    required this.localRepo,
    required this.syncService,
  }) : super(const AsyncValue.loading()) {
    loadPosts();
  }

  /// Load posts (from cache first, then from server)
  Future<void> loadPosts() async {
    try {
      // Load from cache immediately
      final cachedPosts = await localRepo.getPostsByUserId(userId);
      if (cachedPosts.isNotEmpty) {
        state = AsyncValue.data(cachedPosts);
      }

      // Fetch from server and update
      await refreshPosts();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh posts from server
  Future<void> refreshPosts() async {
    try {
      final posts = await syncService.syncUserPosts(userId);
      state = AsyncValue.data(posts);
    } catch (e, stack) {
      // Keep existing data if refresh fails
      if (state.value != null) {
        state = AsyncValue.data(state.value!);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Update a post in the list (optimistic update)
  void updatePost(Post updatedPost) {
    state.whenData((posts) {
      final index = posts.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        final updatedPosts = List<Post>.from(posts);
        updatedPosts[index] = updatedPost;
        state = AsyncValue.data(updatedPosts);
      }
    });
  }

  /// Remove a post from the list
  void removePost(String postId) {
    state.whenData((posts) {
      final updatedPosts = posts.where((p) => p.id != postId).toList();
      state = AsyncValue.data(updatedPosts);
    });
  }

  /// Add a new post to the list
  void addPost(Post post) {
    state.whenData((posts) {
      final updatedPosts = [post, ...posts];
      state = AsyncValue.data(updatedPosts);
    });
  }
}

/// Notifier for managing saved posts
class SavedPostsNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final LocalPostRepository localRepo;

  SavedPostsNotifier({required this.localRepo})
    : super(const AsyncValue.loading()) {
    loadSavedPosts();
  }

  /// Load saved posts from local database
  Future<void> loadSavedPosts() async {
    try {
      final savedPosts = await localRepo.getSavedPosts();
      state = AsyncValue.data(savedPosts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh saved posts
  Future<void> refresh() async {
    await loadSavedPosts();
  }

  /// Update a post in the list
  void updatePost(Post updatedPost) {
    state.whenData((posts) {
      final index = posts.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        final updatedPosts = List<Post>.from(posts);
        updatedPosts[index] = updatedPost;
        state = AsyncValue.data(updatedPosts);
      }
    });
  }

  /// Remove a post from saved list
  void removePost(String postId) {
    state.whenData((posts) {
      final updatedPosts = posts.where((p) => p.id != postId).toList();
      state = AsyncValue.data(updatedPosts);
    });
  }

  /// Add a post to saved list
  void addPost(Post post) {
    state.whenData((posts) {
      final updatedPosts = [post, ...posts];
      state = AsyncValue.data(updatedPosts);
    });
  }
}

/// Provider for post actions (like, save, edit, delete)
final postActionsProvider = Provider<PostActions>((ref) {
  return PostActions(
    postService: ref.read(postServiceProvider),
    localRepo: ref.read(localPostRepositoryProvider),
    syncService: ref.read(syncServiceProvider),
    ref: ref,
  );
});

/// Class for managing post actions with optimistic updates
class PostActions {
  final PostService postService;
  final LocalPostRepository localRepo;
  final SyncService syncService;
  final Ref ref;

  PostActions({
    required this.postService,
    required this.localRepo,
    required this.syncService,
    required this.ref,
  });

  /// Like or unlike a post
  Future<bool> toggleLike(Post post) async {
    final newLikeState = !post.isLiked;
    final newLikeCount = newLikeState
        ? post.likeCount + 1
        : (post.likeCount - 1 < 0 ? 0 : post.likeCount - 1);

    // Optimistic update in local DB
    await localRepo.updatePostLike(post.id, newLikeState, newLikeCount);

    // Update UI immediately
    final updatedPost = post.copyWith(
      isLiked: newLikeState,
      likeCount: newLikeCount,
    );
    _updatePostInProviders(updatedPost);

    // Try to sync with server
    try {
      final result = newLikeState
          ? await postService.likePost(post.id)
          : await postService.unlikePost(post.id);

      if (result['success'] == true && result['data'] != null) {
        // Server returned updated post data, use it
        final data = result['data'];
        final dynamic postJson =
            (data is Map<String, dynamic> && data['post'] is Map)
            ? data['post']
            : data;
        final serverPost = Post.fromJson(
          (postJson as Map).cast<String, dynamic>(),
        );
        await localRepo.savePost(serverPost);
        _updatePostInProviders(serverPost);
        return true;
      } else {
        // Server call failed, queue for retry
        await syncService.queueAction(
          type: newLikeState ? ActionType.like : ActionType.unlike,
          payload: {'postId': post.id},
        );
        return false;
      }
    } catch (e) {
      // Network error, queue for retry
      await syncService.queueAction(
        type: newLikeState ? ActionType.like : ActionType.unlike,
        payload: {'postId': post.id},
      );
      return false;
    }
  }

  /// Save or unsave a post
  Future<bool> toggleSave(Post post) async {
    final newSaveState = !post.isSaved;

    // Optimistic update in local DB
    if (newSaveState) {
      await localRepo.savePostToFavorites(post.id);
    } else {
      await localRepo.unsavePostFromFavorites(post.id);
    }

    // Update UI immediately
    final updatedPost = post.copyWith(isSaved: newSaveState);
    _updatePostInProviders(updatedPost);

    // Update saved posts provider
    if (newSaveState) {
      ref.read(savedPostsProvider.notifier).addPost(updatedPost);
    } else {
      ref.read(savedPostsProvider.notifier).removePost(post.id);
    }

    // Try to sync with server
    try {
      final result = await postService.savePost(post.id);

      if (result['success'] == true && result['data'] != null) {
        // Server returned updated post data
        final serverPost = Post.fromJson(result['data']['post']);
        await localRepo.savePost(serverPost);
        _updatePostInProviders(serverPost);
        return true;
      } else {
        // Server call failed, queue for retry
        await syncService.queueAction(
          type: newSaveState ? ActionType.save : ActionType.unsave,
          payload: {'postId': post.id},
        );
        return false;
      }
    } catch (e) {
      // Network error, queue for retry
      await syncService.queueAction(
        type: newSaveState ? ActionType.save : ActionType.unsave,
        payload: {'postId': post.id},
      );
      return false;
    }
  }

  /// Edit a post
  Future<Map<String, dynamic>> editPost({
    required Post post,
    required String content,
    String? imageUrl,
    required List<String> tags,
  }) async {
    // Optimistic update in local DB
    await localRepo.updatePost(
      postId: post.id,
      content: content,
      imageUrl: imageUrl,
      tags: tags,
    );

    // Update UI immediately
    final updatedPost = post.copyWith(
      content: content,
      imageUrl: imageUrl,
      tags: tags,
      updatedAt: DateTime.now(),
    );
    _updatePostInProviders(updatedPost);

    // Try to sync with server
    try {
      final result = await postService.updatePost(
        postId: post.id,
        content: content,
        imageUrl: imageUrl,
        tags: tags,
      );

      if (result['success'] == true && result['data'] != null) {
        // Server returned updated post data
        final serverPost = Post.fromJson(result['data']);
        await localRepo.savePost(serverPost);
        _updatePostInProviders(serverPost);
        return {'success': true, 'message': result['message']};
      } else if (result['conflict'] == true) {
        // Conflict detected, return for user resolution
        return {
          'success': false,
          'conflict': true,
          'message': result['message'],
        };
      } else {
        // Server call failed, queue for retry
        await syncService.queueAction(
          type: ActionType.edit,
          payload: {
            'postId': post.id,
            'content': content,
            'imageUrl': imageUrl,
            'tags': tags,
          },
        );
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      // Network error, queue for retry
      await syncService.queueAction(
        type: ActionType.edit,
        payload: {
          'postId': post.id,
          'content': content,
          'imageUrl': imageUrl,
          'tags': tags,
        },
      );
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Delete a post
  Future<bool> deletePost(Post post) async {
    // Optimistic update - remove from local DB and UI
    await localRepo.deletePost(post.id);
    _removePostFromProviders(post.id);

    // Try to sync with server
    try {
      final result = await postService.deletePost(post.id);

      if (result['success'] == true) {
        return true;
      } else {
        // Server call failed, queue for retry
        await syncService.queueAction(
          type: ActionType.delete,
          payload: {'postId': post.id},
        );
        return false;
      }
    } catch (e) {
      // Network error, queue for retry
      await syncService.queueAction(
        type: ActionType.delete,
        payload: {'postId': post.id},
      );
      return false;
    }
  }

  /// Add a comment to a post
  Future<bool> addComment({
    required Post post,
    required String content,
    required String userId,
    required String userName,
    String? userAvatarUrl,
    String? parentId,
  }) async {
    final pendingComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: post.id,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: content,
      createdAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    // Save to local DB
    await localRepo.saveComment(pendingComment);

    // Update comment count in post
    final updatedPost = post.copyWith(commentCount: post.commentCount + 1);
    await localRepo.savePost(updatedPost);
    _updatePostInProviders(updatedPost);

    // Queue for sync (when backend endpoint is available)
    try {
      final serverComment = await postService.addComment(
        postId: post.id,
        content: content,
        parentId: parentId,
      );

      // Replace pending comment with server comment
      await localRepo.deleteComment(pendingComment.id);
      await localRepo.saveComment(serverComment);
      return true;
    } catch (_) {
      await syncService.queueAction(
        type: ActionType.comment,
        payload: {
          'postId': post.id,
          'commentId': pendingComment.id,
          'content': content,
          if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
        },
      );
      return true;
    }
  }

  /// Update post in all relevant providers
  void _updatePostInProviders(Post post) {
    // Update in user posts provider if available
    try {
      ref.read(userPostsProvider(post.userId).notifier).updatePost(post);
    } catch (e) {
      // Provider may not be initialized
    }

    // Update in saved posts provider if saved
    if (post.isSaved) {
      try {
        ref.read(savedPostsProvider.notifier).updatePost(post);
      } catch (e) {
        // Provider may not be initialized
      }
    }

    // Update in feed provider (if active)
    try {
      ref.read(feed.feedPostsProvider.notifier).upsertLocalPost(post);
    } catch (_) {
      // Feed provider may not be in use on current screen
    }
  }

  /// Remove post from all providers
  void _removePostFromProviders(String postId) {
    // This would need to know the userId to update the right provider
    // For now, just update saved posts
    try {
      ref.read(savedPostsProvider.notifier).removePost(postId);
    } catch (e) {
      // Provider may not be initialized
    }

    try {
      ref.read(feed.feedPostsProvider.notifier).removeLocalPost(postId);
    } catch (_) {
      // Feed provider may not be in use on current screen
    }
  }
}
