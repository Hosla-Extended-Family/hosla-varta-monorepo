import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/models/post_model.dart';
import 'package:hosla/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for handling post-related API calls
class PostService {
  final http.Client _httpClient;
  final ApiClient _api = ApiClient.instance;

  PostService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static String _formatBackendCreatedAt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}-${two(dt.month)}-${dt.year}${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  String _getClientPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Create a new post
  ///
  /// Sends a POST request to the server with post data
  /// Returns the created post on success
  Future<Map<String, dynamic>> createPost({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    List<String> mediaUrls = const [],
    List<String> tagIds = const [],
    String visibility = 'PUBLIC',
    String? title,
    String? id,
    DateTime? createdAt,
  }) async {
    try {
      // Authentication: Required
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null || accessToken.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
          'data': null,
        };
      }

      final primaryUrl = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}',
      );
      // Some environments expose this route without the /api prefix.
      final fallbackUrl = Uri.parse('${ApiConstants.baseUrl}/posts');

      // Map to API spec
      // IMPORTANT: Do not derive title from body.
      // If title == body, the client UI will show the caption twice
      // (because it combines title + body for display).
      final resolvedTitle = (title ?? '').trim();
      final normalizedMediaUrls = mediaUrls
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final normalizedTagIds = tagIds
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final allowedVisibility = const {'PUBLIC', 'FRIENDS', 'ONLY_ME'};
      final normalizedVisibility =
          allowedVisibility.contains(visibility.toUpperCase())
          ? visibility.toUpperCase()
          : 'PUBLIC';

      // Spec: createdAt is included.
      final effectiveCreatedAt = createdAt ?? DateTime.now();

      final payload = <String, dynamic>{
        if (id != null && id.trim().isNotEmpty) 'id': id.trim(),
        if (resolvedTitle.isNotEmpty) 'title': resolvedTitle,
        'body': content,
        'visibility': normalizedVisibility,
        'mediaUrls': normalizedMediaUrls,
        'tagIds': normalizedTagIds,
        'createdAt': _formatBackendCreatedAt(effectiveCreatedAt),

        // Requested Mapped Fields
        'authorId': userId,
        'authorName': userName,
        'authorProfilePicUrl': userAvatarUrl,
      };

      // Avoid sending explicit nulls.
      payload.removeWhere((_, v) => v == null);
      final requestBody = jsonEncode(payload);

      Future<http.Response> send(Uri u) =>
          _api.post(u, body: requestBody).timeout(ApiConstants.timeout);

      var response = await send(primaryUrl);
      if (response.statusCode == 404) {
        // Retry against the non-/api route if the backend is configured that way.
        response = await send(fallbackUrl);
      }

      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map) {
          decoded = raw.cast<String, dynamic>();
        }
      } catch (_) {
        decoded = null;
      }

      Map<String, dynamic>? extractPostJson() {
        final root = decoded;
        if (root == null) return null;

        dynamic data = root['data'];
        data ??= root['post'];

        if (data is Map) {
          final map = data.cast<String, dynamic>();
          final post = map['post'];
          if (post is Map) return post.cast<String, dynamic>();
          // If it already looks like the post.
          if (map['id'] != null ||
              map['body'] != null ||
              map['content'] != null) {
            return map;
          }
        }

        // Sometimes the entire payload is the post.
        if (root['id'] != null ||
            root['body'] != null ||
            root['content'] != null) {
          return root;
        }

        return null;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = decoded ?? <String, dynamic>{};
        final postJson = extractPostJson();
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post created successfully',
          // Return the post JSON directly for Post.fromJson.
          'data': postJson,
        };
      } else {
        final errorData = decoded ?? <String, dynamic>{};
        final message =
            errorData['message']?.toString().trim().isNotEmpty == true
            ? errorData['message']?.toString()
            : 'Failed to create post';
        return {'success': false, 'message': message, 'data': null};
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
      // Some environments expose uploads under /api; others do not.
      final primaryUrl = Uri.parse('${ApiConstants.baseUrl}/api/upload/image');
      final fallbackUrl = Uri.parse('${ApiConstants.baseUrl}/upload/image');

      Future<http.Response> send(Uri url) async {
        final request = http.MultipartRequest('POST', url);

        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');
        if (accessToken != null && accessToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $accessToken';
        }
        request.headers['X-Client-Platform'] = _getClientPlatform();

        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );

        final streamedResponse = await request.send().timeout(
          ApiConstants.timeout,
        );
        return http.Response.fromStream(streamedResponse);
      }

      var response = await send(primaryUrl);
      if (response.statusCode == 404) {
        response = await send(fallbackUrl);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (_) {
          responseData = null;
        }

        String? raw;
        if (responseData is Map) {
          raw =
              responseData['imageUrl']?.toString() ??
              responseData['url']?.toString();
          final data = responseData['data'];
          if ((raw == null || raw.isEmpty) && data is Map) {
            raw = data['imageUrl']?.toString() ?? data['url']?.toString();
          }
        }

        return ApiConstants.resolveUrl(raw);
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Create a new post with an image file using the same POST /posts endpoint.
  ///
  /// This avoids calling a separate /upload/image route when the backend
  /// expects images to be uploaded alongside the post.
  Future<Map<String, dynamic>> createPostWithImageFile({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    required String imagePath,
    List<String> tagIds = const [],
    String visibility = 'PUBLIC',
    String? title,
    String? id,
    DateTime? createdAt,
  }) async {
    return createPostWithMediaFiles(
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: content,
      mediaPaths: [imagePath],
      tagIds: tagIds,
      visibility: visibility,
      title: title,
      id: id,
      createdAt: createdAt,
    );
  }

  /// Create a new post with one or more media files using the same POST /posts
  /// endpoint.
  ///
  /// Backend expects multipart files under the `mediaUrls` field name and will
  /// return server-relative paths like `/path/image/folder/photo.jpg`.
  Future<Map<String, dynamic>> createPostWithMediaFiles({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    required List<String> mediaPaths,
    List<String> tagIds = const [],
    String visibility = 'PUBLIC',
    String? title,
    String? id,
    DateTime? createdAt,
  }) async {
    try {
      // Authentication: Required
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null || accessToken.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
          'data': null,
        };
      }

      final primaryUrl = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}',
      );
      final fallbackUrl = Uri.parse('${ApiConstants.baseUrl}/posts');

      final resolvedTitle = (title ?? '').trim();
      final normalizedMediaPaths = mediaPaths
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      if (normalizedMediaPaths.isEmpty) {
        return {
          'success': false,
          'message': 'Please attach at least one image.',
          'data': null,
        };
      }
      final normalizedTagIds = tagIds
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final allowedVisibility = const {'PUBLIC', 'FRIENDS', 'ONLY_ME'};
      final normalizedVisibility =
          allowedVisibility.contains(visibility.toUpperCase())
          ? visibility.toUpperCase()
          : 'PUBLIC';

      final effectiveCreatedAt = createdAt ?? DateTime.now();

      Future<http.Response> send(Uri url) async {
        // We need to send tagIds as a real multipart array.
        // `http.MultipartRequest.fields` is a Map and cannot represent repeated
        // keys (tagIds=...&tagIds=...), so we use Dio's FormData which supports
        // duplicate field names.
        final formData = dio.FormData();

        if (id != null && id.trim().isNotEmpty) {
          formData.fields.add(MapEntry('id', id.trim()));
        }
        if (resolvedTitle.isNotEmpty) {
          formData.fields.add(MapEntry('title', resolvedTitle));
        }

        formData.fields.add(MapEntry('body', content));
        formData.fields.add(MapEntry('visibility', normalizedVisibility));
        formData.fields.add(
          MapEntry('createdAt', _formatBackendCreatedAt(effectiveCreatedAt)),
        );
        formData.fields.add(MapEntry('authorId', userId));
        formData.fields.add(MapEntry('authorName', userName));
        if (userAvatarUrl != null && userAvatarUrl.trim().isNotEmpty) {
          formData.fields.add(
            MapEntry('authorProfilePicUrl', userAvatarUrl.trim()),
          );
        }

        // Backend API expects: tagIds: ["uuid1", "uuid2", ...]
        // In multipart/form-data, the most commonly parsed representation is
        // repeating the same key for each element.
        for (final tagId in normalizedTagIds) {
          formData.fields.add(MapEntry('tagIds', tagId));
        }

        debugPrint(
          '[CreatePostMultipart] tagIdsCount=${normalizedTagIds.length} '
          'tagIds=$normalizedTagIds mediaCount=${normalizedMediaPaths.length}',
        );

        for (final path in normalizedMediaPaths) {
          formData.files.add(
            MapEntry('mediaUrls', await dio.MultipartFile.fromFile(path)),
          );
        }

        final client = dio.Dio(
          dio.BaseOptions(
            connectTimeout: ApiConstants.timeout,
            sendTimeout: ApiConstants.timeout,
            receiveTimeout: ApiConstants.timeout,
            validateStatus: (status) => status != null && status < 600,
          ),
        );

        final response = await client.postUri(
          url,
          data: formData,
          options: dio.Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'X-Client-Platform': _getClientPlatform(),
            },
            contentType: 'multipart/form-data',
            responseType: dio.ResponseType.plain,
          ),
        );

        return http.Response(
          response.data?.toString() ?? '',
          response.statusCode ?? 0,
          headers: {
            for (final e in response.headers.map.entries)
              e.key: e.value.join(','),
          },
        );
      }

      var response = await send(primaryUrl);
      if (response.statusCode == 404) {
        response = await send(fallbackUrl);
      }

      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map) decoded = raw.cast<String, dynamic>();
      } catch (_) {
        decoded = null;
      }

      Map<String, dynamic>? extractPostJson() {
        final root = decoded;
        if (root == null) return null;
        dynamic data = root['data'];
        data ??= root['post'];
        if (data is Map) {
          final map = data.cast<String, dynamic>();
          final post = map['post'];
          if (post is Map) return post.cast<String, dynamic>();
          if (map['id'] != null ||
              map['body'] != null ||
              map['content'] != null) {
            return map;
          }
        }
        if (root['id'] != null ||
            root['body'] != null ||
            root['content'] != null) {
          return root;
        }
        return null;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = decoded ?? <String, dynamic>{};
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post created successfully',
          'data': extractPostJson(),
        };
      }

      final errorData = decoded ?? <String, dynamic>{};
      final message = errorData['message']?.toString().trim().isNotEmpty == true
          ? errorData['message']?.toString()
          : 'Failed to create post';

      return {'success': false, 'message': message, 'data': null};
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
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
    List<String> mediaUrls = const [],
    List<String> tagIds = const [],
    String visibility = 'PUBLIC',
    String? title,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    DateTime? createdAt,
  }) async {
    try {
      // Authentication: Required
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken == null || accessToken.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
          'data': null,
        };
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId',
      );
      final fallbackUrl = Uri.parse('${ApiConstants.baseUrl}/posts/$postId');

      final resolvedTitle = (title ?? '').trim();
      final normalizedMediaUrls = mediaUrls
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final normalizedTagIds = tagIds
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final allowedVisibility = const {'PUBLIC', 'FRIENDS', 'ONLY_ME'};
      final normalizedVisibility =
          allowedVisibility.contains(visibility.toUpperCase())
          ? visibility.toUpperCase()
          : 'PUBLIC';

      final requestBody = {
        'id': postId,
        'title': resolvedTitle.isNotEmpty ? resolvedTitle : null,
        'body': content,
        'visibility': normalizedVisibility,
        'mediaUrls': normalizedMediaUrls,
        'tagIds': normalizedTagIds,

        // Requested Mapped Fields (best-effort)
        if (userId != null) 'authorId': userId,
        if (userName != null) 'authorName': userName,
        if (userAvatarUrl != null) 'authorProfilePicUrl': userAvatarUrl,
        if (createdAt != null) 'createdAt': _formatBackendCreatedAt(createdAt),
      };

      // Avoid sending explicit nulls.
      requestBody.removeWhere((_, v) => v == null);

      Future<http.Response> send(Uri u) => _api
          .put(u, body: jsonEncode(requestBody))
          .timeout(ApiConstants.timeout);

      var response = await send(url);
      if (response.statusCode == 404) {
        response = await send(fallbackUrl);
      }

      Map<String, dynamic>? decoded;
      try {
        final raw = jsonDecode(response.body);
        if (raw is Map) decoded = raw.cast<String, dynamic>();
      } catch (_) {
        decoded = null;
      }

      Map<String, dynamic>? extractPostJson() {
        final root = decoded;
        if (root == null) return null;

        dynamic data = root['data'];
        data ??= root['post'];
        if (data is Map) {
          final map = data.cast<String, dynamic>();
          final post = map['post'];
          if (post is Map) return post.cast<String, dynamic>();
          if (map['id'] != null ||
              map['body'] != null ||
              map['content'] != null) {
            return map;
          }
        }

        if (root['id'] != null ||
            root['body'] != null ||
            root['content'] != null) {
          return root;
        }
        return null;
      }

      if (response.statusCode == 200) {
        final responseData =
            decoded ??
            (jsonDecode(response.body) as Map).cast<String, dynamic>();
        return {
          'success': true,
          'message': responseData['message'] ?? 'Post updated successfully',
          'data': extractPostJson() ?? responseData['data'],
        };
      } else if (response.statusCode == 409) {
        final errorData =
            decoded ??
            (jsonDecode(response.body) as Map).cast<String, dynamic>();
        return {
          'success': false,
          'message': 'Conflict: ${errorData['message']}',
          'data': null,
          'conflict': true,
        };
      } else {
        final errorData =
            decoded ??
            (jsonDecode(response.body) as Map).cast<String, dynamic>();
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

  /// Update only the visibility of a post (PUBLIC | FRIENDS | ONLY_ME)
  Future<Map<String, dynamic>> updateVisibility({
    required String postId,
    required String visibility,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.postsEndpoint}/$postId',
      );

      final response = await _api
          .put(url, body: jsonEncode({'visibility': visibility}))
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] == true,
          'message': responseData['message'] ?? 'Visibility updated',
          'data': responseData['data'],
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to update visibility',
        'data': null,
      };
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
