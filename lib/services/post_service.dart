import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hosla/core/constants/api_constants.dart';
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
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}',
      );

      // Map to API spec: title/body/mediaUrls/tags
      final title = content.length > 60 ? content.substring(0, 60) : content;
      final requestBody = jsonEncode({
        'title': title.isNotEmpty ? title : null,
        'body': content,
        'mediaUrls': [if (imageUrl != null && imageUrl.isNotEmpty) imageUrl],
        'tags': tags,
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

      final response = await _httpClient
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

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
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId',
      );

      final requestBody = {
        'content': content,
        'imageUrl': imageUrl ?? '',
        'tags': tags,
      };

      final response = await _httpClient
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
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

      final response = await _httpClient
          .delete(url, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

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
  /// Toggles the like status of a post
  Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/like',
      );

      final response = await _httpClient
          .post(url, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

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

  /// Save or unsave a post
  ///
  /// Toggles the saved status of a post
  Future<Map<String, dynamic>> savePost(String postId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId/save',
      );

      final response = await _httpClient
          .post(url, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post saved',
          'data': responseData['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to save post',
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

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
