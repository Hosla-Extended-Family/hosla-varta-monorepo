import 'dart:convert';

import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/services/api_client.dart';
import 'package:http/http.dart' as http;

class FriendService {
  final ApiClient _api = ApiClient.instance;

  Uri _friendUri([String path = '']) {
    final suffix = path.isNotEmpty ? '/$path' : '';
    return Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.friendsEndpoint}$suffix',
    );
  }

  // Some environments expose these routes without the `/api` prefix.
  Uri _friendFallbackUri([String path = '']) {
    final suffix = path.isNotEmpty ? '/$path' : '';
    return Uri.parse('${ApiConstants.baseUrl}/friends$suffix');
  }

  Future<http.Response> _getWithFallback(Uri primary, Uri fallback) async {
    var response = await _api.get(primary);
    if (response.statusCode == 404) {
      response = await _api.get(fallback);
    }
    return response;
  }

  Future<http.Response> _postWithFallback(
    Uri primary,
    Uri fallback, {
    Object? body,
  }) async {
    var response = await _api.post(primary, body: body);
    if (response.statusCode == 404) {
      response = await _api.post(fallback, body: body);
    }
    return response;
  }

  Future<http.Response> _deleteWithFallback(
    Uri primary,
    Uri fallback, {
    Object? body,
  }) async {
    var response = await _api.delete(primary, body: body);
    if (response.statusCode == 404) {
      response = await _api.delete(fallback, body: body);
    }
    return response;
  }

  /// Send a friend request to target user
  Future<FriendshipEdge> sendFriendRequest(String userId) async {
    final uri = _friendUri('request/$userId');
    final fallback = _friendFallbackUri('request/$userId');
    final response = await _postWithFallback(uri, fallback);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return FriendshipEdge.fromJson(data);
    }

    throw Exception('Failed to send friend request');
  }

  /// Accept a pending friend request
  Future<List<FriendshipEdge>> acceptRequest(String friendshipId) async {
    final uri = _friendUri('accept/$friendshipId');
    final fallback = _friendFallbackUri('accept/$friendshipId');
    final response = await _postWithFallback(uri, fallback);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? const [];
      return list
          .whereType<Map>()
          .map(
            (item) => FriendshipEdge.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    throw Exception('Failed to accept friend request');
  }

  /// Reject a pending friend request
  Future<FriendshipEdge> rejectRequest(String friendshipId) async {
    final uri = _friendUri('reject/$friendshipId');
    final fallback = _friendFallbackUri('reject/$friendshipId');
    final response = await _postWithFallback(uri, fallback);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      return FriendshipEdge.fromJson(data);
    }

    throw Exception('Failed to reject friend request');
  }

  /// Remove an existing friendship
  Future<bool> removeFriend(String friendshipId) async {
    final uri = _friendUri(friendshipId);
    final fallback = _friendFallbackUri(friendshipId);
    final response = await _deleteWithFallback(uri, fallback);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    return false;
  }

  /// Fetch accepted friends
  Future<List<FriendshipEdge>> listFriends() async {
    final uri = _friendUri();
    final fallback = _friendFallbackUri();
    final response = await _getWithFallback(uri, fallback);
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map>()
          .map(
            (item) => FriendshipEdge.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    throw Exception('Failed to load friends');
  }

  /// Fetch pending friend requests (incoming/outgoing)
  Future<List<FriendshipEdge>> listPendingRequests() async {
    final uri = _friendUri('requests');
    final fallback = _friendFallbackUri('requests');
    final response = await _getWithFallback(uri, fallback);
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map>()
          .map(
            (item) => FriendshipEdge.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    throw Exception('Failed to load requests');
  }

  /// Search users by name / query string.
  ///
  /// GET /api/users/search?q=<query>&page=<page>&limit=<limit>
  Future<SearchUsersResponse> searchUsers(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/search'
      '?q=${Uri.encodeQueryComponent(query)}&page=$page&limit=$limit',
    );
    final fallback = Uri.parse(
      '${ApiConstants.baseUrl}/users/search'
      '?q=${Uri.encodeQueryComponent(query)}&page=$page&limit=$limit',
    );

    final response = await _getWithFallback(uri, fallback);

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return SearchUsersResponse.fromJson(body);
    }

    throw Exception('Failed to search users');
  }

  /// Fetch a user's profile honoring visibility
  Future<UserProfileVisibilityResult> getUserProfile(String userId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/$userId',
    );
    final fallback = Uri.parse('${ApiConstants.baseUrl}/users/$userId');

    var response = await _api.get(uri);
    if (response.statusCode == 404) {
      response = await _api.get(fallback);
    }

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      return UserProfileVisibilityResult.fromJson(data);
    }

    if (response.statusCode == 404) {
      throw Exception('Profile not accessible');
    }

    throw Exception('Failed to fetch profile');
  }
}
