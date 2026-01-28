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

  /// Dummy posts data for testing
  static final List<Post> _dummyPosts = [
    Post(
      id: '1',
      userId: 'user1',
      userName: 'Priya Sharma',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop&crop=face',
      content:
          'Just attended an amazing mental health awareness workshop! It\'s so important to prioritize our mental well-being. Remember, it\'s okay to ask for help. 💚',
      imageUrl:
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=600&h=400&fit=crop',
      tags: ['#MentalHealth', '#Wellness', '#Community'],
      likeCount: 124,
      commentCount: 18,
      shareCount: 7,
      isLiked: false,
      isSaved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Post(
      id: '2',
      userId: 'user2',
      userName: 'Rahul Kumar',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      content:
          'Excited to announce our upcoming community yoga session this Saturday! Join us for a morning of relaxation and mindfulness. All levels welcome! 🧘‍♂️',
      imageUrl:
          'https://images.unsplash.com/photo-1588286840104-8957b019727f?w=600&h=400&fit=crop',
      tags: ['#Yoga', '#Wellness', '#Event'],
      likeCount: 89,
      commentCount: 12,
      shareCount: 15,
      isLiked: true,
      isSaved: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Post(
      id: '3',
      userId: 'user3',
      userName: 'Anjali Patel',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      content:
          'Small steps lead to big changes. Started my daily meditation practice and already feeling more centered and peaceful. What are your self-care routines? Share below! ✨',
      tags: ['#SelfCare', '#Meditation', '#MindfulLiving'],
      likeCount: 156,
      commentCount: 23,
      shareCount: 9,
      isLiked: false,
      isSaved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    Post(
      id: '4',
      userId: 'user4',
      userName: 'Vikram Singh',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
      content:
          'Thank you all for the overwhelming support during the peer support group yesterday. It means the world to connect with others who truly understand. Together we are stronger! 💪',
      imageUrl:
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&h=400&fit=crop',
      tags: ['#Support', '#Community', '#MentalHealth'],
      likeCount: 203,
      commentCount: 34,
      shareCount: 12,
      isLiked: true,
      isSaved: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Post(
      id: '5',
      userId: 'user5',
      userName: 'Sneha Reddy',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150&h=150&fit=crop&crop=face',
      content:
          'Reminder: Your mental health is just as important as your physical health. Don\'t hesitate to reach out if you need someone to talk to. We\'re all in this together! 🌟',
      tags: ['#MentalHealthAwareness', '#Support'],
      likeCount: 178,
      commentCount: 15,
      shareCount: 24,
      isLiked: false,
      isSaved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

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
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final postsJson = (data['posts'] as List?) ?? [];
      final posts = postsJson
          .map<Post>((j) => _mapBackendPost(j as Map<String, dynamic>))
          .toList();
      final nextCursor = data['nextCursor']?.toString();
      return FeedResult(posts: posts, nextCursor: nextCursor);
    }
    // Fallback to dummy on non-200 for now
    return FeedResult(posts: _dummyPosts, nextCursor: null);
  }

  /// Get a single post by ID
  /// TODO: Implement actual API call
  /// Example: GET /api/posts/:id
  Future<Post?> getPostById(String postId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/posts/$postId'));
    // if (response.statusCode == 200) {
    //   return Post.fromJson(json.decode(response.body));
    // } else if (response.statusCode == 404) {
    //   return null;
    // }
    // throw Exception('Failed to load post');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      return _dummyPosts.firstWhere((post) => post.id == postId);
    } catch (e) {
      return null;
    }
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
      'mediaUrls': [if (request.imageUrl != null) request.imageUrl!],
      'tags': request.tags,
    });
    final response = await _api.post(uri, body: body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      final res = json.decode(response.body) as Map<String, dynamic>;
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        return _mapBackendPost(data);
      }
      // If backend returns different shape, create local from request
      return Post(
        id:
            res['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user',
        userName: 'Anonymous',
        content: request.content,
        imageUrl: request.imageUrl,
        tags: request.tags,
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        isLiked: false,
        isSaved: false,
        createdAt: DateTime.now(),
      );
    }
    throw Exception('Failed to create post: ${response.statusCode}');
  }

  Post _mapBackendPost(Map<String, dynamic> j) {
    final title = j['title']?.toString();
    final body = j['body']?.toString();
    final content = body ?? title ?? '';
    final mediaUrls =
        (j['mediaUrls'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final imageUrl = mediaUrls.isNotEmpty ? mediaUrls.first : null;
    return Post(
      id: j['id']?.toString() ?? '',
      userId: j['userId']?.toString() ?? '',
      userName: j['userName']?.toString() ?? 'Unknown User',
      userAvatarUrl: j['userAvatarUrl']?.toString(),
      content: content,
      imageUrl: imageUrl,
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (j['commentCount'] as num?)?.toInt() ?? 0,
      shareCount: (j['shareCount'] as num?)?.toInt() ?? 0,
      isLiked: j['isLikedByMe'] == true || j['isLiked'] == true,
      isSaved: j['isSavedByMe'] == true || j['isSaved'] == true,
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: j['updatedAt'] != null
          ? DateTime.tryParse(j['updatedAt'].toString())
          : null,
    );
  }

  /// Update a post
  /// TODO: Implement actual API call
  /// Example: PUT /api/posts/:id
  Future<Post> updatePost(String postId, CreatePostRequest request) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.put(
    //   Uri.parse('$baseUrl/posts/$postId'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(request.toJson()),
    // );
    // if (response.statusCode == 200) {
    //   return Post.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to update post');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _dummyPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final updatedPost = _dummyPosts[index].copyWith(
        content: request.content,
        imageUrl: request.imageUrl,
        tags: request.tags,
        updatedAt: DateTime.now(),
      );
      _dummyPosts[index] = updatedPost;
      return updatedPost;
    }

    throw Exception('Post not found');
  }

  /// Delete a post
  /// TODO: Implement actual API call
  /// Example: DELETE /api/posts/:id
  Future<void> deletePost(String postId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.delete(Uri.parse('$baseUrl/posts/$postId'));
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to delete post');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _dummyPosts.removeWhere((post) => post.id == postId);
  }

  /// Like a post
  /// TODO: Implement actual API call
  /// Example: POST /api/posts/:id/like
  Future<Post> likePost(String postId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(Uri.parse('$baseUrl/posts/$postId/like'));
    // if (response.statusCode == 200) {
    //   return Post.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to like post');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _dummyPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _dummyPosts[index];
      final updatedPost = post.copyWith(
        isLiked: true,
        likeCount: post.likeCount + 1,
      );
      _dummyPosts[index] = updatedPost;
      return updatedPost;
    }

    throw Exception('Post not found');
  }

  /// Unlike a post
  /// TODO: Implement actual API call
  /// Example: DELETE /api/posts/:id/like
  Future<Post> unlikePost(String postId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.delete(Uri.parse('$baseUrl/posts/$postId/like'));
    // if (response.statusCode == 200) {
    //   return Post.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to unlike post');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _dummyPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _dummyPosts[index];
      final updatedPost = post.copyWith(
        isLiked: false,
        likeCount: post.likeCount - 1 >= 0 ? post.likeCount - 1 : 0,
      );
      _dummyPosts[index] = updatedPost;
      return updatedPost;
    }

    throw Exception('Post not found');
  }

  /// Save a post
  /// TODO: Implement actual API call
  /// Example: POST /api/posts/:id/save
  Future<Post> savePost(String postId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(Uri.parse('$baseUrl/posts/$postId/save'));
    // if (response.statusCode == 200) {
    //   return Post.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to save post');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _dummyPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final updatedPost = _dummyPosts[index].copyWith(isSaved: true);
      _dummyPosts[index] = updatedPost;
      return updatedPost;
    }

    throw Exception('Post not found');
  }

  /// Unsave a post
  /// TODO: Implement actual API call
  /// Example: DELETE /api/posts/:id/save
  Future<Post> unsavePost(String postId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.delete(Uri.parse('$baseUrl/posts/$postId/save'));
    // if (response.statusCode == 200) {
    //   return Post.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to unsave post');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _dummyPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final updatedPost = _dummyPosts[index].copyWith(isSaved: false);
      _dummyPosts[index] = updatedPost;
      return updatedPost;
    }

    throw Exception('Post not found');
  }

  /// Get comments for a post
  /// TODO: Implement actual API call
  /// Example: GET /api/posts/:id/comments
  Future<List<Comment>> getPostComments(String postId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/posts/$postId/comments'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body)['comments'];
    //   return jsonList.map((json) => Comment.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load comments');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    // Return dummy comments
    return [
      Comment(
        id: '1',
        postId: postId,
        userId: 'user6',
        userName: 'Amit Verma',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face',
        content: 'Great post! This is really helpful.',
        likeCount: 5,
        isLiked: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Comment(
        id: '2',
        postId: postId,
        userId: 'user7',
        userName: 'Kavita Sharma',
        userAvatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
        content: 'Thanks for sharing! 💚',
        likeCount: 3,
        isLiked: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  /// Add a comment to a post
  /// TODO: Implement actual API call
  /// Example: POST /api/posts/:id/comments
  Future<Comment> addComment(String postId, String content) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(
    //   Uri.parse('$baseUrl/posts/$postId/comments'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({'content': content}),
    // );
    // if (response.statusCode == 201) {
    //   return Comment.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to add comment');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Update comment count
    final index = _dummyPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _dummyPosts[index];
      _dummyPosts[index] = post.copyWith(commentCount: post.commentCount + 1);
    }

    return Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: postId,
      userId: 'current_user',
      userName: 'John Doe',
      userAvatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
      content: content,
      likeCount: 0,
      isLiked: false,
      createdAt: DateTime.now(),
    );
  }

  /// Share a post
  /// TODO: Implement actual API call
  /// Example: POST /api/posts/:id/share
  Future<void> sharePost(String postId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(Uri.parse('$baseUrl/posts/$postId/share'));
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to share post');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    // Update share count
    final index = _dummyPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _dummyPosts[index];
      _dummyPosts[index] = post.copyWith(shareCount: post.shareCount + 1);
    }
  }

  /// Report a post
  /// TODO: Implement actual API call
  /// Example: POST /api/posts/:id/report
  Future<void> reportPost(String postId, String reason) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(
    //   Uri.parse('$baseUrl/posts/$postId/report'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({'reason': reason}),
    // );
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to report post');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Get saved posts
  /// TODO: Implement actual API call
  /// Example: GET /api/posts/saved
  Future<List<Post>> getSavedPosts() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/posts/saved'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body)['posts'];
    //   return jsonList.map((json) => Post.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load saved posts');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _dummyPosts.where((post) => post.isSaved).toList();
  }

  /// Get user's posts
  /// TODO: Implement actual API call
  /// Example: GET /api/users/:userId/posts
  Future<List<Post>> getUserPosts(String userId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/users/$userId/posts'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body)['posts'];
    //   return jsonList.map((json) => Post.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load user posts');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _dummyPosts.where((post) => post.userId == userId).toList();
  }
}
