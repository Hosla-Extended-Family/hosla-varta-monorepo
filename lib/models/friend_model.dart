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

  const FriendshipEdge({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.requester,
    this.receiver,
    this.createdAt,
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
    );
  }

  bool isPending() => status.toUpperCase() == 'PENDING';
  bool isAccepted() => status.toUpperCase() == 'ACCEPTED';

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
