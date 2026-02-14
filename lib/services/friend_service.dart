import 'dart:convert';

import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/models/friend_model.dart';
import 'package:hosla/services/api_client.dart';

class FriendService {
  final ApiClient _api = ApiClient.instance;

  Uri _friendUri([String path = '']) {
    final suffix = path.isNotEmpty ? '/$path' : '';
    return Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.friendsEndpoint}$suffix',
    );
  }

  /// Send a friend request to target user
  Future<FriendshipEdge> sendFriendRequest(String userId) async {
    final uri = _friendUri('request/$userId');
    final response = await _api.post(uri);

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
    final response = await _api.post(uri);

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
    final response = await _api.post(uri);

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
    final response = await _api.delete(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    return false;
  }

  /// Fetch accepted friends
  Future<List<FriendshipEdge>> listFriends() async {
    final uri = _friendUri();
    final response = await _api.get(uri);
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
    final response = await _api.get(uri);
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

  /// Fetch a user's profile honoring visibility
  Future<UserProfileVisibilityResult> getUserProfile(String userId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/$userId',
    );
    final response = await _api.get(uri);

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
