import 'dart:async';
import 'dart:math';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/services/local_post_repository.dart';
import 'package:hosla/services/post_service.dart';

/// Service for synchronizing local data with server
/// Handles offline queue processing and retry logic
class SyncService {
  final LocalPostRepository _localRepo = LocalPostRepository();
  final PostService _postService = PostService();

  // Configuration
  static const int maxRetries = 5;
  static const Duration initialBackoff = Duration(seconds: 2);
  static const int backoffMultiplier = 2;

  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

  /// Start periodic sync (every 5 minutes)
  void startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncAll(),
    );
  }

  /// Stop periodic sync
  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Sync all queued actions
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;

    try {
      // Get all queued actions
      final actions = await _localRepo.getQueuedActions();

      for (final action in actions) {
        final result = await _processAction(action);

        if (result) {
          syncedCount++;
          await _localRepo.dequeueAction(action.id);
        } else {
          failedCount++;
          // Update attempts count
          final newAttempts = action.attempts + 1;

          if (newAttempts >= maxRetries) {
            // Mark as failed permanently
            await _localRepo.dequeueAction(action.id);
          } else {
            await _localRepo.updateActionAttempts(action.id, newAttempts);
            // Wait with exponential backoff before next retry
            await _exponentialBackoff(newAttempts);
          }
        }
      }

      // Sync pending comments
      await _syncPendingComments();

      return SyncResult(
        success: failedCount == 0,
        message: failedCount == 0
            ? 'All actions synced successfully'
            : '$failedCount actions failed to sync',
        syncedCount: syncedCount,
        failedCount: failedCount,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync error: ${e.toString()}',
        syncedCount: syncedCount,
        failedCount: failedCount,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Process a single action from the queue
  Future<bool> _processAction(ActionQueue action) async {
    try {
      switch (action.type) {
        case ActionType.like:
        case ActionType.unlike:
          final postId = action.payload['postId'] as String?;
          if (postId == null) return false;
          final result = action.type == ActionType.like
              ? await _postService.likePost(postId)
              : await _postService.unlikePost(postId);
          return result['success'] ?? false;

        case ActionType.save:
        case ActionType.unsave:
          final postId = action.payload['postId'] as String?;
          if (postId == null) return false;
          final result = await _postService.savePost(postId);
          return result['success'] ?? false;

        case ActionType.edit:
          final postId = action.payload['postId'] as String?;
          final content = action.payload['content'] as String?;
          final imageUrl = action.payload['imageUrl'] as String?;
          final tagIds = action.payload['tagIds'] as List<String>?;

          if (postId == null || content == null) return false;

          final result = await _postService.updatePost(
            postId: postId,
            content: content,
            mediaUrls: [if (imageUrl != null && imageUrl.isNotEmpty) imageUrl],
            tagIds: tagIds ?? [],
          );
          return result['success'] ?? false;

        case ActionType.delete:
          final postId = action.payload['postId'] as String?;
          if (postId == null) return false;
          final result = await _postService.deletePost(postId);
          return result['success'] ?? false;

        case ActionType.comment:
          final postId = action.payload['postId'] as String?;
          final commentId = action.payload['commentId'] as String?;
          final content = action.payload['content'] as String?;
          final parentId = action.payload['parentId'] as String?;
          if (postId == null || commentId == null || content == null)
            return false;

          final serverComment = await _postService.addComment(
            postId: postId,
            content: content,
            parentId: parentId,
          );

          // Replace the pending comment with the server comment
          await _localRepo.deleteComment(commentId);
          await _localRepo.saveComment(serverComment);
          return true;
      }
    } catch (e) {
      print('Error processing action ${action.type}: $e');
      return false;
    }
  }

  /// Sync pending comments
  Future<void> _syncPendingComments() async {
    final pendingComments = await _localRepo.getPendingComments();

    for (final comment in pendingComments) {
      try {
        // TODO: Implement comment API endpoint when available
        // For now, mark as synced after a delay
        await Future.delayed(const Duration(milliseconds: 100));
        await _localRepo.updateCommentSyncStatus(comment.id, SyncStatus.synced);
      } catch (e) {
        await _localRepo.updateCommentSyncStatus(comment.id, SyncStatus.failed);
      }
    }
  }

  /// Exponential backoff delay
  Future<void> _exponentialBackoff(int attempts) async {
    final delayMs =
        initialBackoff.inMilliseconds * pow(backoffMultiplier, attempts - 1);
    final maxDelayMs = const Duration(minutes: 5).inMilliseconds;
    final actualDelayMs = min(delayMs.toInt(), maxDelayMs);

    await Future.delayed(Duration(milliseconds: actualDelayMs));
  }

  /// Queue an action for offline sync
  Future<void> queueAction({
    required ActionType type,
    required Map<String, dynamic> payload,
  }) async {
    final action = ActionQueue(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
      attempts: 0,
    );

    await _localRepo.enqueueAction(action);
  }

  /// Sync user posts from server
  Future<List<Post>> syncUserPosts(String userId) async {
    try {
      final result = await _postService.getPostsByUserId(userId);

      if (result['success'] == true) {
        final postsData = result['data'] as List<dynamic>;
        final posts = postsData.map((json) => Post.fromJson(json)).toList();

        // Save to local database
        await _localRepo.savePosts(posts);

        return posts;
      }

      return [];
    } catch (e) {
      print('Error syncing user posts: $e');
      // Return cached posts on error
      return await _localRepo.getPostsByUserId(userId);
    }
  }

  /// Clean up old data
  Future<void> cleanupOldData({int retentionDays = 90}) async {
    await _localRepo.cleanupOldPosts(retentionDays: retentionDays);
  }

  /// Dispose resources
  void dispose() {
    stopPeriodicSync();
    _postService.dispose();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
  });
}
