import 'package:hosla/models/post_model.dart';
import 'package:hosla/services/database_helper.dart';

/// Repository for local post data operations
/// Provides abstraction layer over database operations
class LocalPostRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ============== POST OPERATIONS ==============

  /// Get all posts from local database
  Future<List<Post>> getAllPosts() async {
    return await _dbHelper.getAllPosts();
  }

  /// Get posts by user ID
  Future<List<Post>> getPostsByUserId(String userId) async {
    return await _dbHelper.getPostsByUserId(userId);
  }

  /// Get a single post by ID
  Future<Post?> getPostById(String postId) async {
    return await _dbHelper.getPostById(postId);
  }

  /// Save a single post to local database
  Future<void> savePost(Post post) async {
    await _dbHelper.upsertPost(post);
  }

  /// Save multiple posts to local database
  Future<void> savePosts(List<Post> posts) async {
    await _dbHelper.upsertPosts(posts);
  }

  /// Update post content
  Future<void> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
    required List<String> tags,
  }) async {
    await _dbHelper.updatePost(
      postId: postId,
      content: content,
      imageUrl: imageUrl,
      tags: tags,
    );
  }

  /// Delete a post from local database
  Future<void> deletePost(String postId) async {
    await _dbHelper.deletePost(postId);
  }

  /// Update post like status
  Future<void> updatePostLike(
    String postId,
    bool isLiked,
    int likeCount,
  ) async {
    await _dbHelper.updatePostLike(postId, isLiked, likeCount);
  }

  /// Update post save status
  Future<void> updatePostSave(String postId, bool isSaved) async {
    await _dbHelper.updatePostSave(postId, isSaved);
  }

  /// Delete old posts based on retention policy
  Future<void> cleanupOldPosts({int retentionDays = 90}) async {
    await _dbHelper.deleteOldPosts(retentionDays: retentionDays);
  }

  // ============== SAVED POSTS OPERATIONS ==============

  /// Get all saved posts
  Future<List<Post>> getSavedPosts() async {
    return await _dbHelper.getSavedPosts();
  }

  /// Save a post (add to saved_posts table)
  Future<void> savePostToFavorites(String postId) async {
    await _dbHelper.savePost(postId);
  }

  /// Unsave a post (remove from saved_posts table)
  Future<void> unsavePostFromFavorites(String postId) async {
    await _dbHelper.unsavePost(postId);
  }

  /// Check if a post is saved
  Future<bool> isPostSaved(String postId) async {
    return await _dbHelper.isPostSaved(postId);
  }

  // ============== COMMENT OPERATIONS ==============

  /// Get comments for a post
  Future<List<Comment>> getCommentsByPostId(String postId) async {
    return await _dbHelper.getCommentsByPostId(postId);
  }

  /// Save a comment
  Future<void> saveComment(Comment comment) async {
    await _dbHelper.upsertComment(comment);
  }

  /// Get pending comments (not synced)
  Future<List<Comment>> getPendingComments() async {
    return await _dbHelper.getPendingComments();
  }

  /// Update comment sync status
  Future<void> updateCommentSyncStatus(
    String commentId,
    SyncStatus status,
  ) async {
    await _dbHelper.updateCommentSyncStatus(commentId, status);
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _dbHelper.deleteComment(commentId);
  }

  // ============== ACTION QUEUE OPERATIONS ==============

  /// Add action to queue
  Future<void> enqueueAction(ActionQueue action) async {
    await _dbHelper.enqueueAction(action);
  }

  /// Get all queued actions
  Future<List<ActionQueue>> getQueuedActions() async {
    return await _dbHelper.getQueuedActions();
  }

  /// Get queued actions by type
  Future<List<ActionQueue>> getQueuedActionsByType(ActionType type) async {
    return await _dbHelper.getQueuedActionsByType(type);
  }

  /// Update action attempts count
  Future<void> updateActionAttempts(String actionId, int attempts) async {
    await _dbHelper.updateActionAttempts(actionId, attempts);
  }

  /// Remove action from queue
  Future<void> dequeueAction(String actionId) async {
    await _dbHelper.dequeueAction(actionId);
  }

  /// Clear all queued actions
  Future<void> clearActionQueue() async {
    await _dbHelper.clearActionQueue();
  }
}
