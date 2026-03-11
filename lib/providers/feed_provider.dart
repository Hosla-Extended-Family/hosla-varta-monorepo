import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/services/feed_service.dart';

/// Provider for FeedService instance
final feedServiceProvider = Provider<FeedService>((ref) => FeedService());

/// Provider for feed posts list
final feedPostsProvider =
    StateNotifierProvider<FeedPostsNotifier, AsyncValue<List<Post>>>((ref) {
      return FeedPostsNotifier(ref.read(feedServiceProvider));
    });

/// Provider for a single post
final postProvider = FutureProvider.family<Post?, String>((ref, postId) async {
  final feedService = ref.read(feedServiceProvider);
  return await feedService.getPostById(postId);
});

/// Provider for post comments
final postCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  postId,
) async {
  final feedService = ref.read(feedServiceProvider);
  return await feedService.getPostComments(postId);
});

/// Provider for users who liked a post
final postLikesProvider = FutureProvider.family<List<LikeUser>, String>((
  ref,
  postId,
) async {
  final feedService = ref.read(feedServiceProvider);
  return await feedService.getPostLikes(postId);
});

/// Provider for saved posts
final savedPostsProvider =
    StateNotifierProvider<SavedPostsNotifier, AsyncValue<List<Post>>>((ref) {
      return SavedPostsNotifier(ref.read(feedServiceProvider));
    });

/// Provider for user posts
final userPostsProvider = FutureProvider.family<List<Post>, String>((
  ref,
  userId,
) async {
  final feedService = ref.read(feedServiceProvider);
  return await feedService.getUserPosts(userId);
});

/// Notifier for managing feed posts
class FeedPostsNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final FeedService _feedService;
  String? _nextCursor;
  bool _hasMore = true;

  FeedPostsNotifier(this._feedService) : super(const AsyncValue.loading()) {
    loadPosts();
  }

  /// Update/insert a post in the current feed list without hitting network.
  void upsertLocalPost(Post updatedPost) {
    state.whenData((currentPosts) {
      final index = currentPosts.indexWhere((p) => p.id == updatedPost.id);
      if (index == -1) return;
      final next = [...currentPosts];
      next[index] = updatedPost;
      state = AsyncValue.data(next);
    });
  }

  /// Remove a post from the current feed list without hitting network.
  void removeLocalPost(String postId) {
    state.whenData((currentPosts) {
      state = AsyncValue.data(
        currentPosts.where((p) => p.id != postId).toList(),
      );
    });
  }

  /// Load initial posts
  Future<void> loadPosts() async {
    state = const AsyncValue.loading();
    try {
      final result = await _feedService.getFeed(limit: 20);
      _nextCursor = result.nextCursor;
      _hasMore = result.posts.isNotEmpty && _nextCursor != null;
      state = AsyncValue.data(result.posts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh posts
  Future<void> refreshPosts() async {
    try {
      final result = await _feedService.getFeed(limit: 20);
      _nextCursor = result.nextCursor;
      _hasMore = result.posts.isNotEmpty && _nextCursor != null;
      state = AsyncValue.data(result.posts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (!_hasMore) return;

    state.whenData((currentPosts) async {
      try {
        final result = await _feedService.getFeed(
          limit: 20,
          cursor: _nextCursor,
        );
        final newPosts = result.posts;
        _nextCursor = result.nextCursor;
        _hasMore = _nextCursor != null && newPosts.isNotEmpty;
        if (newPosts.isNotEmpty) {
          state = AsyncValue.data([...currentPosts, ...newPosts]);
        }
      } catch (e, stackTrace) {
        // Keep current posts on error
        state = AsyncValue.error(e, stackTrace);
      }
    });
  }

  /// Create a new post
  Future<void> createPost(CreatePostRequest request) async {
    try {
      final newPost = await _feedService.createPost(request);

      state.whenData((currentPosts) {
        state = AsyncValue.data([newPost, ...currentPosts]);
      });
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  /// Update a post
  Future<void> updatePost(String postId, CreatePostRequest request) async {
    try {
      final updatedPost = await _feedService.updatePost(postId, request);

      state.whenData((currentPosts) {
        final index = currentPosts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          final updatedPosts = [...currentPosts];
          updatedPosts[index] = updatedPost;
          state = AsyncValue.data(updatedPosts);
        }
      });
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _feedService.deletePost(postId);

      state.whenData((currentPosts) {
        final updatedPosts = currentPosts
            .where((post) => post.id != postId)
            .toList();
        state = AsyncValue.data(updatedPosts);
      });
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  /// Toggle like on a post
  Future<void> toggleLike(String postId) async {
    // Optimistic update
    state.whenData((currentPosts) {
      final index = currentPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = currentPosts[index];
        final updatedPost = post.copyWith(
          isLiked: !post.isLiked,
          likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
        );
        final updatedPosts = [...currentPosts];
        updatedPosts[index] = updatedPost;
        state = AsyncValue.data(updatedPosts);
      }
    });

    try {
      // Get current like status
      final currentPost = state.value?.firstWhere((post) => post.id == postId);
      if (currentPost != null) {
        if (currentPost.isLiked) {
          await _feedService.likePost(postId);
        } else {
          await _feedService.unlikePost(postId);
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Revert optimistic update on error
      await loadPosts();
    }
  }

  /// Toggle save on a post
  Future<void> toggleSave(String postId) async {
    // Optimistic update
    state.whenData((currentPosts) {
      final index = currentPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = currentPosts[index];
        final updatedPost = post.copyWith(isSaved: !post.isSaved);
        final updatedPosts = [...currentPosts];
        updatedPosts[index] = updatedPost;
        state = AsyncValue.data(updatedPosts);
      }
    });

    try {
      // Get current save status
      final currentPost = state.value?.firstWhere((post) => post.id == postId);
      if (currentPost != null) {
        if (currentPost.isSaved) {
          await _feedService.savePost(postId);
        } else {
          await _feedService.unsavePost(postId);
        }
      }
    } catch (e) {
      print('Error toggling save: $e');
      // Revert optimistic update on error
      await loadPosts();
    }
  }

  /// Add a comment to a post
  Future<Comment> addComment(String postId, String content) async {
    try {
      final comment = await _feedService.addComment(postId, content);

      // Update comment count
      state.whenData((currentPosts) {
        final index = currentPosts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          final post = currentPosts[index];
          final updatedPost = post.copyWith(
            commentCount: post.commentCount + 1,
          );
          final updatedPosts = [...currentPosts];
          updatedPosts[index] = updatedPost;
          state = AsyncValue.data(updatedPosts);
        }
      });

      return comment;
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Share a post
  Future<void> sharePost(String postId) async {
    try {
      await _feedService.sharePost(postId);

      // Update share count
      state.whenData((currentPosts) {
        final index = currentPosts.indexWhere((post) => post.id == postId);
        if (index != -1) {
          final post = currentPosts[index];
          final updatedPost = post.copyWith(shareCount: post.shareCount + 1);
          final updatedPosts = [...currentPosts];
          updatedPosts[index] = updatedPost;
          state = AsyncValue.data(updatedPosts);
        }
      });
    } catch (e) {
      print('Error sharing post: $e');
      rethrow;
    }
  }

  /// Report a post
  Future<void> reportPost(String postId, String reason) async {
    try {
      await _feedService.reportPost(postId, reason);
    } catch (e) {
      print('Error reporting post: $e');
      rethrow;
    }
  }

  bool get hasMore => _hasMore;
}

/// Notifier for managing saved posts
class SavedPostsNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final FeedService _feedService;

  SavedPostsNotifier(this._feedService) : super(const AsyncValue.loading()) {
    loadSavedPosts();
  }

  /// Load saved posts
  Future<void> loadSavedPosts() async {
    state = const AsyncValue.loading();
    try {
      final posts = await _feedService.getSavedPosts();
      state = AsyncValue.data(posts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh saved posts
  Future<void> refreshSavedPosts() async {
    try {
      final posts = await _feedService.getSavedPosts();
      state = AsyncValue.data(posts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Remove a post from saved
  Future<void> unsavePost(String postId) async {
    try {
      await _feedService.unsavePost(postId);

      state.whenData((currentPosts) {
        final updatedPosts = currentPosts
            .where((post) => post.id != postId)
            .toList();
        state = AsyncValue.data(updatedPosts);
      });
    } catch (e) {
      print('Error unsaving post: $e');
      rethrow;
    }
  }
}
