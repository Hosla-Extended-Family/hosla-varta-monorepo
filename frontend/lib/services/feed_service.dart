import 'dart:convert';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/services/api_client.dart';

/// Result model for feed API
class FeedResult {
  final List<Post> posts;
  final String? nextCursor;
  FeedResult({required this.posts, this.nextCursor});
}

/// Service class for handling feed-related API calls
class FeedService {
  // TODO: Add HTTP client dependency injection
  // final http.Client _httpClient;
  final ApiClient _api = ApiClient.instance;

  static String _formatBackendCreatedAt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}-${two(dt.month)}-${dt.year}${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  // NOTE: Feed is always loaded from the backend API.

  /// Get feed posts with pagination
  /// TODO: Implement actual API call
  /// Example: GET /api/feed?page=1&limit=10
  Future<FeedResult> getFeed({
    int limit = 20,
    String? cursor,
    bool includeHidden = false,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      if (includeHidden) 'includeHidden': 'true',
    };
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/feed',
    ).replace(queryParameters: query);
    final response = await _api.get(uri);

    if (response.statusCode != 200) {
      String errorMessage = 'Failed to load feed (${response.statusCode})';
      try {
        final decoded = json.decode(response.body);
        errorMessage = decoded['error']?['message'] ?? decoded['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      final message = body['error']?['message'] ?? body['message']?.toString();
      throw Exception(message?.isNotEmpty == true ? message : 'Feed failed');
    }

    final data = body['data'] as Map<String, dynamic>? ?? {};
    final postsJson = (data['posts'] as List?) ?? const [];
    final posts = postsJson
        .whereType<Map>()
        .map((j) => Post.fromJson(Map<String, dynamic>.from(j)))
        .toList();
    final nextCursor = data['nextCursor']?.toString();

    return FeedResult(posts: posts, nextCursor: nextCursor);
  }

  /// Get a single post by ID
  /// TODO: Implement actual API call
  /// Example: GET /api/posts/:id
  Future<Post?> getPostById(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId',
    );
    final response = await _api.get(uri);
    if (response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return Post.fromJson(data);
      }
      return null;
    }
    if (response.statusCode == 404) return null;
    throw Exception('Failed to load post: ${response.statusCode}');
  }

  /// Create a new post
  /// TODO: Implement actual API call
  /// Example: POST /api/posts
  Future<Post> createPost(CreatePostRequest request) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}',
    );
    final title = request.content.length > 60
        ? request.content.substring(0, 60)
        : request.content;
    final body = json.encode({
      'title': title.isNotEmpty ? title : null,
      'body': request.content,
      'mediaUrls': [
        if (request.imageUrl != null && request.imageUrl!.trim().isNotEmpty)
          request.imageUrl!.trim(),
      ],
      // For API v2+ this must be tag UUIDs
      'tagIds': request.tags,
      // createPost UI doesn't supply createdAt; server will set it.
      // If needed for offline sync, include it here.
      'createdAt': _formatBackendCreatedAt(DateTime.now()),
    });
    final response = await _api.post(uri, body: body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return Post.fromJson(data);
      }
      throw Exception('Create post returned unexpected payload');
    }
    throw Exception('Failed to create post: ${response.statusCode}');
  }

  /// Update a post
  /// TODO: Implement actual API call
  /// Example: PUT /api/posts/:id
  Future<Post> updatePost(String postId, CreatePostRequest request) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId',
    );
    final title = request.content.length > 60
        ? request.content.substring(0, 60)
        : request.content;
    final body = json.encode({
      'id': postId,
      'title': title.isNotEmpty ? title : null,
      'body': request.content,
      'mediaUrls': [
        if (request.imageUrl != null && request.imageUrl!.trim().isNotEmpty)
          request.imageUrl!.trim(),
      ],
      'tagIds': request.tags,
    });
    final response = await _api.put(uri, body: body);
    if (response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return Post.fromJson(data);
      }
      throw Exception('Update returned unexpected payload');
    }
    throw Exception('Failed to update post: ${response.statusCode}');
  }

  /// Delete a post
  /// TODO: Implement actual API call
  /// Example: DELETE /api/posts/:id
  Future<void> deletePost(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId',
    );
    final response = await _api.delete(uri);
    if (response.statusCode == 200 || response.statusCode == 204) return;
    if (response.statusCode == 404) return;
    throw Exception('Failed to delete post: ${response.statusCode}');
  }

  /// Like a post
  /// TODO: Implement actual API call
  /// Example: POST /api/posts/:id/like
  Future<Post> likePost(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/like',
    );
    final response = await _api.post(uri);
    if (response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final postJson = (data['post'] is Map<String, dynamic>)
            ? (data['post'] as Map<String, dynamic>)
            : data;
        return Post.fromJson(postJson);
      }
      throw Exception('Like returned unexpected payload');
    }
    throw Exception('Failed to like post: ${response.statusCode}');
  }

  /// Unlike a post
  /// TODO: Implement actual API call
  /// Example: DELETE /api/posts/:id/like
  Future<Post> unlikePost(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/like',
    );
    final response = await _api.delete(uri);
    if (response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final postJson = (data['post'] is Map<String, dynamic>)
            ? (data['post'] as Map<String, dynamic>)
            : data;
        return Post.fromJson(postJson);
      }
      throw Exception('Unlike returned unexpected payload');
    }
    throw Exception('Failed to unlike post: ${response.statusCode}');
  }

  /// Save a post
  Future<Post> savePost(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/save',
    );

    final response = await _api.post(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to save post: ${response.statusCode}');
    }

    final res = json.decode(response.body) as Map<String, dynamic>;
    final data = res['data'];

    Map<String, dynamic>? postJson;
    if (data is Map<String, dynamic> && data['post'] is Map) {
      postJson = (data['post'] as Map).cast<String, dynamic>();
    } else if (data is Map<String, dynamic> && data.containsKey('id')) {
      postJson = data;
    }

    if (postJson != null) return Post.fromJson(postJson);

    final refreshed = await getPostById(postId);
    if (refreshed != null) return refreshed;

    throw Exception('Save post returned unexpected payload');
  }

  /// Unsave a post
  Future<Post> unsavePost(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/save',
    );

    final response = await _api.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to unsave post: ${response.statusCode}');
    }

    final res = json.decode(response.body) as Map<String, dynamic>;
    final data = res['data'];

    Map<String, dynamic>? postJson;
    if (data is Map<String, dynamic> && data['post'] is Map) {
      postJson = (data['post'] as Map).cast<String, dynamic>();
    } else if (data is Map<String, dynamic> && data.containsKey('id')) {
      postJson = data;
    }

    if (postJson != null) return Post.fromJson(postJson);

    final refreshed = await getPostById(postId);
    if (refreshed != null) return refreshed;

    throw Exception('Unsave post returned unexpected payload');
  }

  /// Get comments for a post
  /// GET /posts/:postId/comments?page=1&limit=50
  /// Authentication: Optional
  Future<List<Comment>> getPostComments(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/comments',
    ).replace(queryParameters: {'page': '1', 'limit': '50'});

    final response = await _api.get(uri);
    if (response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];

      List<dynamic> commentsJson = const [];
      if (data is Map<String, dynamic> && data['comments'] is List) {
        commentsJson = data['comments'] as List<dynamic>;
      } else if (res['comments'] is List) {
        commentsJson = res['comments'] as List<dynamic>;
      }

      return commentsJson
          .whereType<Map>()
          .map((j) => Comment.fromJson(j.cast<String, dynamic>()))
          .toList();
    }

    throw Exception('Failed to load comments: ${response.statusCode}');
  }

  /// Get users who liked a post
  /// GET /api/posts/:postId/likes
  Future<List<LikeUser>> getPostLikes(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/likes',
    );

    final response = await _api.get(uri);
    if (response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((j) => LikeUser.fromJson(j.cast<String, dynamic>()))
            .toList();
      }
      return const [];
    }

    throw Exception('Failed to load likes: ${response.statusCode}');
  }

  /// Add a comment to a post
  /// POST /posts/:postId/comments
  /// Authentication: Required
  Future<Comment> addComment(String postId, String content) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/comments',
    );
    final response = await _api.post(
      uri,
      body: json.encode({'content': content}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];

      Map<String, dynamic>? commentJson;
      if (data is Map<String, dynamic> && data['comment'] is Map) {
        commentJson = (data['comment'] as Map).cast<String, dynamic>();
      } else if (data is Map<String, dynamic>) {
        commentJson = data;
      }

      if (commentJson != null) {
        return Comment.fromJson(commentJson);
      }

      throw Exception('Add comment returned unexpected payload');
    }

    throw Exception('Failed to add comment: ${response.statusCode}');
  }

  /// Share a post
  Future<void> sharePost(String postId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/share',
    );
    final response = await _api.post(uri);
    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw Exception('Failed to share post: ${response.statusCode}');
  }

  /// Report a post
  /// POST /reports
  /// Authentication: Required (Member+)
  Future<void> reportPost(String postId, String reason) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.reportsEndpoint}',
    );
    final response = await _api.post(
      uri,
      body: json.encode({'postId': postId, 'reason': reason}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) return;
    throw Exception('Failed to report post: ${response.statusCode}');
  }

  /// Get saved posts
  Future<List<Post>> getSavedPosts() async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/saved/list',
    ).replace(queryParameters: const {'page': '1', 'limit': '20'});

    final response = await _api.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load saved posts: ${response.statusCode}');
    }

    final res = json.decode(response.body) as Map<String, dynamic>;
    if (res['success'] != true) {
      final message = res['message']?.toString();
      throw Exception(
        message?.isNotEmpty == true ? message : 'Saved posts failed',
      );
    }

    final data = res['data'];
    List<dynamic> postsJson = const [];
    if (data is Map<String, dynamic>) {
      final raw = data['posts'] ?? data['items'] ?? data['savedPosts'];
      if (raw is List) postsJson = raw;
    } else if (data is List) {
      postsJson = data;
    }

    return postsJson
        .whereType<Map>()
        .map((j) => Post.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  /// Get user's posts
  Future<List<Post>> getUserPosts(String userId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/user/$userId',
    ).replace(queryParameters: const {'page': '1', 'limit': '20'});

    final response = await _api.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load user posts: ${response.statusCode}');
    }

    final res = json.decode(response.body) as Map<String, dynamic>;
    if (res['success'] != true) {
      final message = res['message']?.toString();
      throw Exception(
        message?.isNotEmpty == true ? message : 'User posts failed',
      );
    }

    final data = res['data'];
    List<dynamic> postsJson = const [];
    if (data is Map<String, dynamic>) {
      final raw = data['posts'] ?? data['items'] ?? data['data'];
      if (raw is List) postsJson = raw;
    } else if (data is List) {
      postsJson = data;
    }

    return postsJson
        .whereType<Map>()
        .map((j) => Post.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }
}
