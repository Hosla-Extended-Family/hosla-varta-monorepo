/// User model for profile management and chat participants
class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final String? email;
  final bool isOnline;
  final DateTime? lastSeen;

  const User({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.email,
    this.isOnline = false,
    this.lastSeen,
  });

  /// Factory constructor for creating User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      email: json['email'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'email': email,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? bio,
    String? email,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
