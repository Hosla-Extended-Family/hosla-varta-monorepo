import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/services/api_client.dart';

/// Service class for handling post-related API calls
class PostService {
  final http.Client _httpClient;
  final ApiClient _api = ApiClient.instance;

  PostService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Create a new post
  ///
  /// Sends a POST request to the server with post data
  /// Returns the created post on success
  Future<Map<String, dynamic>> createPost({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    String? imageUrl,
    List<String> tags = const [],
    String? id,
    DateTime? createdAt,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}',
      );

      // Map to API spec
      final title = content.length > 60 ? content.substring(0, 60) : content;
      final requestBody = jsonEncode({
        if (id != null && id.isNotEmpty) 'id': id,
        'title': title.isNotEmpty ? title : null,
        'body': content,
        'mediaUrls': [if (imageUrl != null && imageUrl.isNotEmpty) imageUrl],
        'tags': tags,

        // Requested Mapped Fields
        'authorId': userId,
        'authorName': userName,
        'authorProfilePicUrl': userAvatarUrl,

        // createdAt is server-controlled in most APIs, but supported by spec
        if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
      });

      final response = await _api
          .post(url, body: requestBody)
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post created successfully',
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create post',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Fetch the main feed with optional pagination
  ///
  /// GET /posts/feed?limit=20&cursor=...&includeHidden=true
  /// Authentication: Optional (handled by ApiClient)
  Future<Map<String, dynamic>> getFeed({
    int limit = 20,
    String? cursor,
    bool includeHidden = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (includeHidden) 'includeHidden': 'true',
      };

      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/feed',
      ).replace(queryParameters: queryParams);

      final response = await _api.get(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] == true,
          'data': responseData['data'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch feed',
          'data': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {},
      };
    }
  }

  /// Upload image to server
  ///
  /// Returns the URL of the uploaded image
  Future<String?> uploadImage(String imagePath) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/upload/image');
      final request = http.MultipartRequest('POST', url);

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send().timeout(
        ApiConstants.timeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['imageUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Get posts by user ID
  ///
  /// Fetches all posts created by a specific user
  Future<Map<String, dynamic>> getPostsByUserId(String userId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/user/$userId',
      );

      final response = await _api.get(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'count': responseData['count'] ?? 0,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch posts',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': [],
      };
    }
  }

  /// Update a post
  ///
  /// Updates an existing post with new content, image, or tags
  Future<Map<String, dynamic>> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
    List<String> tags = const [],
    String? userId,
    String? userName,
    String? userAvatarUrl,
    DateTime? createdAt,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId',
      );

      final title = content.length > 60 ? content.substring(0, 60) : content;
      final requestBody = {
        'id': postId,
        'title': title.isNotEmpty ? title : null,
        'body': content,
        'mediaUrls': [if (imageUrl != null && imageUrl.isNotEmpty) imageUrl],
        'tags': tags,

        // Requested Mapped Fields (best-effort)
        if (userId != null) 'authorId': userId,
        if (userName != null) 'authorName': userName,
        if (userAvatarUrl != null) 'authorProfilePicUrl': userAvatarUrl,
        if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
      };

      final response = await _api
          .put(url, body: jsonEncode(requestBody))
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post updated successfully',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 409) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': 'Conflict: ${errorData['message']}',
          'data': null,
          'conflict': true,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update post',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Delete a post
  ///
  /// Permanently deletes a post
  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId',
      );

      final response = await _api.delete(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post deleted successfully',
        };
      } else if (response.statusCode == 404) {
        // Post already deleted on server
        return {'success': true, 'message': 'Post already deleted'};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete post',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Like or unlike a post
  ///
  /// Likes a post
  Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/like',
      );

      final response = await _api.post(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post liked',
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to like post',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Unlike a post
  Future<Map<String, dynamic>> unlikePost(String postId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/like',
      );

      final response = await _api.delete(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post unliked',
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to unlike post',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Save a post
  ///
  /// POST /api/posts/{postId}/save
  Future<Map<String, dynamic>> savePost(String postId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/save',
      );

      final response = await _api.post(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post saved successfully',
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['error']?['message'] ??
              errorData['message'] ??
              'Failed to save post',
          'errorCode': errorData['error']?['code'],
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Unsave a post
  ///
  /// DELETE /api/posts/{postId}/save
  Future<Map<String, dynamic>> unsavePost(String postId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/save',
      );

      final response = await _api.delete(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post unsaved successfully',
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['error']?['message'] ??
              errorData['message'] ??
              'Failed to unsave post',
          'errorCode': errorData['error']?['code'],
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get user profile grid posts
  ///
  /// GET /api/posts/user/{userId}?page=1&limit=20
  Future<Map<String, dynamic>> getUserPostsGrid({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/user/$userId',
      ).replace(queryParameters: queryParams);

      final response = await _api.get(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] == true,
          'data': responseData['data'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch user posts',
          'data': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {},
      };
    }
  }

  /// Get saved posts list
  ///
  /// GET /api/posts/saved/list?page=1&limit=20
  Future<Map<String, dynamic>> getSavedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/saved/list',
      ).replace(queryParameters: queryParams);

      final response = await _api.get(url).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] == true,
          'data': responseData['data'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch saved posts',
          'data': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': {},
      };
    }
  }

  /// Get comments for a post
  ///
  /// GET /posts/:postId/comments?page=1&limit=50
  /// Authentication: Optional
  Future<List<Comment>> getComments({
    required String postId,
    int page = 1,
    int limit = 50,
  }) async {
    final uri =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/comments',
        ).replace(
          queryParameters: {'page': page.toString(), 'limit': limit.toString()},
        );

    final response = await _api.get(uri).timeout(ApiConstants.timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }

    final res = jsonDecode(response.body) as Map<String, dynamic>;
    final data = res['data'];
    final commentsJson =
        (data is Map<String, dynamic> && data['comments'] is List)
        ? (data['comments'] as List)
        : (res['comments'] is List ? (res['comments'] as List) : const []);

    return commentsJson
        .whereType<Map>()
        .map((j) => Comment.fromJson(j.cast<String, dynamic>()))
        .toList();
  }

  /// Add a comment to a post
  ///
  /// POST /posts/:postId/comments
  /// Authentication: Required
  Future<Comment> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/comments',
    );
    final body = jsonEncode({
      'content': content,
      if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
    });

    final response = await _api
        .post(uri, body: body)
        .timeout(ApiConstants.timeout);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }

    final res = jsonDecode(response.body) as Map<String, dynamic>;
    final data = res['data'];
    final dynamic commentJson =
        (data is Map<String, dynamic> && data['comment'] is Map)
        ? data['comment']
        : data;

    if (commentJson is Map) {
      return Comment.fromJson(commentJson.cast<String, dynamic>());
    }

    throw Exception('Add comment returned unexpected payload');
  }

  /// Delete a comment
  ///
  /// DELETE /comments/:id
  /// Authentication: Comment author or admin
  Future<void> deleteComment({required String commentId}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.commentsEndpoint}/$commentId',
    );

    final response = await _api.delete(uri).timeout(ApiConstants.timeout);
    if (response.statusCode == 200 || response.statusCode == 204) return;
    if (response.statusCode == 404) return;
    throw Exception('Failed to delete comment: ${response.statusCode}');
  }

  /// Like a comment
  ///
  /// POST /api/comments/:id/like
  /// Authentication: Required
  Future<Map<String, dynamic>> likeComment({required String commentId}) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.commentsEndpoint}/$commentId/like',
      );

      final response = await _api.post(uri).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] == true,
          'liked': responseData['liked'] == true,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to like comment',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Unlike a comment
  ///
  /// DELETE /api/comments/:id/like
  /// Authentication: Required
  Future<Map<String, dynamic>> unlikeComment({
    required String commentId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.commentsEndpoint}/$commentId/like',
      );

      final response = await _api.delete(uri).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] == true,
          'liked': responseData['liked'] == false,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to unlike comment',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Report content (post)
  ///
  /// POST /reports
  /// Authentication: Required (Member+)
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.reportsEndpoint}',
    );
    final response = await _api
        .post(uri, body: jsonEncode({'postId': postId, 'reason': reason}))
        .timeout(ApiConstants.timeout);

    if (response.statusCode == 201 || response.statusCode == 200) return;
    throw Exception('Failed to report post: ${response.statusCode}');
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
