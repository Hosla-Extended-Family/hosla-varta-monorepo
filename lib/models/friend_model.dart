class FriendUserSummary {
  final String id;
  final String name;
  final String? profilePicUrl;

  const FriendUserSummary({
    required this.id,
    required this.name,
    this.profilePicUrl,
  });

  factory FriendUserSummary.fromJson(Map<String, dynamic> json) {
    return FriendUserSummary(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      profilePicUrl:
          json['profilePicUrl']?.toString() ??
          json['profilePic']?.toString() ??
          json['profilePicture']?.toString() ??
          json['avatarUrl']?.toString(),
    );
  }
}

class FriendshipEdge {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status; // PENDING | ACCEPTED | REJECTED
  final FriendUserSummary? requester;
  final FriendUserSummary? receiver;
  final DateTime? createdAt;

  /// 'incoming' | 'outgoing' when returned by the pending-requests endpoint.
  final String? direction;

  const FriendshipEdge({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.requester,
    this.receiver,
    this.createdAt,
    this.direction,
  });

  factory FriendshipEdge.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt']?.toString();
    DateTime? created;
    if (createdRaw != null && createdRaw.isNotEmpty) {
      created = DateTime.tryParse(createdRaw);
    }

    return FriendshipEdge(
      id: json['id']?.toString() ?? '',
      requesterId: json['requesterId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      requester: json['requester'] is Map<String, dynamic>
          ? FriendUserSummary.fromJson(
              json['requester'] as Map<String, dynamic>,
            )
          : null,
      receiver: json['receiver'] is Map<String, dynamic>
          ? FriendUserSummary.fromJson(json['receiver'] as Map<String, dynamic>)
          : null,
      createdAt: created,
      direction: json['direction']?.toString(),
    );
  }

  bool isPending() => status.toUpperCase() == 'PENDING';
  bool isAccepted() => status.toUpperCase() == 'ACCEPTED';
  bool isOutgoing(String currentUserId) =>
      direction?.toLowerCase() == 'outgoing' || requesterId == currentUserId;

  FriendUserSummary? otherParty(String currentUserId) {
    if (requesterId == currentUserId) return receiver ?? requester;
    if (receiverId == currentUserId) return requester ?? receiver;
    return receiver ?? requester;
  }
}

class UserProfileVisibilityResult {
  final FriendUserSummary user;
  final String? bio;
  final String visibility; // PUBLIC | FRIENDS
  final String? role;
  final bool isFriend;

  const UserProfileVisibilityResult({
    required this.user,
    required this.visibility,
    required this.isFriend,
    this.bio,
    this.role,
  });

  factory UserProfileVisibilityResult.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    return UserProfileVisibilityResult(
      user: FriendUserSummary.fromJson(userMap),
      bio: userMap['bio']?.toString(),
      visibility:
          userMap['profileVisibility']?.toString().toUpperCase() ?? 'PUBLIC',
      role: userMap['role']?.toString(),
      isFriend: json['isFriend'] == true,
    );
  }
}

/// A single user result from the search API.
class SearchUserResult {
  final String id;
  final String name;
  final String? profilePicUrl;
  final String? bio;
  final String friendshipStatus; // NOT_FRIENDS | PENDING | FRIENDS
  final String? friendshipId;

  const SearchUserResult({
    required this.id,
    required this.name,
    this.profilePicUrl,
    this.bio,
    required this.friendshipStatus,
    this.friendshipId,
  });

  factory SearchUserResult.fromJson(Map<String, dynamic> json) {
    return SearchUserResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      profilePicUrl:
          json['profilePicUrl']?.toString() ??
          json['profilePic']?.toString() ??
          json['profilePicture']?.toString() ??
          json['avatarUrl']?.toString(),
      bio: json['bio']?.toString(),
      friendshipStatus:
          json['friendshipStatus']?.toString().toUpperCase() ?? 'NOT_FRIENDS',
      friendshipId: json['friendshipId']?.toString(),
    );
  }
}

/// Paginated response wrapper for the search API.
class SearchUsersResponse {
  final List<SearchUserResult> users;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  const SearchUsersResponse({
    required this.users,
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.hasMore = false,
  });

  factory SearchUsersResponse.fromJson(Map<String, dynamic> json) {
    // API response: { data: { users: [...], pagination: {...} } }
    final data = json['data'];
    List<dynamic> rawList;
    Map<String, dynamic> pagination;

    if (data is Map<String, dynamic>) {
      // Nested format: { data: { users: [...], pagination: {...} } }
      rawList = data['users'] as List<dynamic>? ?? const [];
      pagination =
          data['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};
    } else {
      // Flat fallback: { data: [...], pagination: {...} }
      rawList =
          data as List<dynamic>? ?? json['users'] as List<dynamic>? ?? const [];
      pagination =
          json['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};
    }

    final users = rawList
        .whereType<Map>()
        .map((e) => SearchUserResult.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final page = pagination['page'] as int? ?? json['page'] as int? ?? 1;
    final limit = pagination['limit'] as int? ?? json['limit'] as int? ?? 20;
    final total = pagination['total'] as int? ?? json['total'] as int? ?? 0;
    final totalPages = pagination['totalPages'] as int? ?? 1;
    final hasMore = pagination['hasMore'] as bool? ?? (page < totalPages);

    return SearchUsersResponse(
      users: users,
      page: page,
      limit: limit,
      total: total,
      hasMore: hasMore,
    );
  }
}
