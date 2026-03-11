import 'package:hosla/core/constants/api_constants.dart';

/// Model class for representing a post in the feed
class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String? title;
  final String content;
  final String? imageUrl;
  final List<String> mediaUrls;
  final String? youtubeVideoId;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;
  final bool isPinned;
  final bool canEdit;
  final bool canDelete;
  final bool canReport;
  final String visibility;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? savedAt;

  const Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.title,
    required this.content,
    this.imageUrl,
    this.mediaUrls = const [],
    this.youtubeVideoId,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isPinned = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canReport = false,
    this.visibility = 'PUBLIC',
    required this.createdAt,
    this.updatedAt,
    this.savedAt,
  });

  static String _extractTagName(dynamic raw) {
    if (raw == null) return '';

    if (raw is String) return raw;

    if (raw is Map) {
      // Most common shape from API: { id: ..., name: ... }
      final directName =
          raw['name'] ??
          raw['tagName'] ??
          raw['displayName'] ??
          raw['label'] ??
          raw['title'] ??
          raw['value'];
      if (directName != null) return directName.toString();

      // Sometimes nested: { tag: { name: ... } }
      final nested = raw['tag'];
      if (nested is Map) {
        final nestedName = nested['name'] ?? nested['tagName'];
        if (nestedName != null) return nestedName.toString();
      }
    }

    return raw.toString();
  }

  static DateTime _parseBackendDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    final s = raw.toString().trim();
    if (s.isEmpty) return DateTime.now();

    // ISO 8601 first
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // Backend format: "DD-MM-YYYY HH:MM:SS" or "DD-MM-YYYYHH:MM:SS"
    final re = RegExp(
      r'^(\d{2})-(\d{2})-(\d{4})[\sT]?(\d{2}):(\d{2}):(\d{2})$',
    );
    final m = re.firstMatch(s);
    if (m != null) {
      final d = int.tryParse(m.group(1)!) ?? 1;
      final mo = int.tryParse(m.group(2)!) ?? 1;
      final y = int.tryParse(m.group(3)!) ?? 1970;
      final h = int.tryParse(m.group(4)!) ?? 0;
      final mi = int.tryParse(m.group(5)!) ?? 0;
      final sec = int.tryParse(m.group(6)!) ?? 0;
      return DateTime(y, mo, d, h, mi, sec);
    }

    // Epoch millis fallback
    final epoch = int.tryParse(s);
    if (epoch != null) {
      return DateTime.fromMillisecondsSinceEpoch(epoch);
    }

    return DateTime.now();
  }

  static String _combineTitleBody({
    String? title,
    String? body,
    String? content,
  }) {
    final t = (title ?? '').trim();
    final b = (body ?? '').trim();
    if (t.isNotEmpty && b.isNotEmpty) return '$t\n\n$b';
    if (t.isNotEmpty) return t;
    if (b.isNotEmpty) return b;
    return (content ?? '').toString();
  }

  static String? _extractFirstMediaUrl(dynamic mediaUrls, dynamic imageUrl) {
    if (imageUrl != null) {
      final s = imageUrl.toString().trim();
      if (s.isNotEmpty) return s;
    }
    if (mediaUrls is List) {
      for (final e in mediaUrls) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  /// Factory constructor for creating Post from JSON
  factory Post.fromJson(Map<String, dynamic> json) {
    final authorId = json['authorId'] ?? json['userId'];
    final authorName = json['authorName'] ?? json['userName'];
    final authorProfilePicUrl =
        json['authorProfilePicUrl'] ?? json['userAvatarUrl'];

    final title = json['title']?.toString();
    final body = json['body']?.toString();
    final content = json['content']?.toString();

    final imageUrl = ApiConstants.resolveUrl(
      _extractFirstMediaUrl(json['mediaUrls'], json['imageUrl']),
    );

    // Parse tags - API may return tag objects; we only store tag names.
    // Also strip a leading '#' to keep display consistent.
    final tagsRaw = json['tags'];
    final tags = tagsRaw is List
        ? tagsRaw
              .map(_extractTagName)
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .map((s) => s.startsWith('#') ? s.substring(1).trim() : s)
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[];

    final mediaUrlsRaw = json['mediaUrls'];
    final mediaUrls = mediaUrlsRaw is List
        ? mediaUrlsRaw
              .map((e) => ApiConstants.resolveUrl(e?.toString()))
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList(growable: false)
        : <String>[];

    final likeCount =
        (json['likeCount'] as num?)?.toInt() ??
        (json['likes'] as num?)?.toInt() ??
        0;
    final commentCount =
        (json['commentCount'] as num?)?.toInt() ??
        (json['comments'] as num?)?.toInt() ??
        0;
    final shareCount = (json['shareCount'] as num?)?.toInt() ?? 0;

    final isLiked = json['isLikedByMe'] == true || json['isLiked'] == true;
    final visibility =
        (json['visibility'] ?? json['postVisibility'])
            ?.toString()
            .toUpperCase() ??
        'PUBLIC';

    return Post(
      id: json['id'] ?? '',
      userId: authorId?.toString() ?? '',
      userName: authorName?.toString() ?? 'Unknown User',
      userAvatarUrl: ApiConstants.resolveUrl(authorProfilePicUrl?.toString()),
      title: title,
      content: _combineTitleBody(title: title, body: body, content: content),
      imageUrl: imageUrl,
      mediaUrls: mediaUrls,
      youtubeVideoId: json['youtubeVideoId']?.toString(),
      tags: tags,
      likeCount: likeCount,
      commentCount: commentCount,
      shareCount: shareCount,
      isLiked: isLiked,
      isSaved: json['isSavedByMe'] == true || json['isSaved'] == true,
      isPinned: json['isPinned'] == true,
      canEdit: json['canEdit'] == true,
      canDelete: json['canDelete'] == true,
      canReport: json['canReport'] == true,
      visibility: visibility,
      createdAt: _parseBackendDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseBackendDate(json['updatedAt'])
          : null,
      savedAt: json['savedAt'] != null
          ? _parseBackendDate(json['savedAt'])
          : null,
    );
  }

  /// Convert Post to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'mediaUrls': mediaUrls,
      'youtubeVideoId': youtubeVideoId,
      'tags': tags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'isPinned': isPinned,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'canReport': canReport,
      'visibility': visibility,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'savedAt': savedAt?.toIso8601String(),
    };
  }

  /// Create a copy of Post with updated fields
  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? title,
    String? content,
    String? imageUrl,
    List<String>? mediaUrls,
    String? youtubeVideoId,
    List<String>? tags,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    bool? isSaved,
    bool? isPinned,
    bool? canEdit,
    bool? canDelete,
    bool? canReport,
    String? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? savedAt,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isPinned: isPinned ?? this.isPinned,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canReport: canReport ?? this.canReport,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  /// Get relative time string (e.g., "2 hours ago")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Post(id: $id, userName: $userName, content: $content, likeCount: $likeCount)';
  }
}

/// Model for creating a new post
class CreatePostRequest {
  final String content;
  final String? imageUrl;
  final List<String> tags;
  final String? location;
  final List<String> taggedUserIds;

  const CreatePostRequest({
    required this.content,
    this.imageUrl,
    this.tags = const [],
    this.location,
    this.taggedUserIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'imageUrl': imageUrl,
      'tags': tags,
      'location': location,
      'taggedUserIds': taggedUserIds,
    };
  }
}

/// Sync status enum for offline support
enum SyncStatus {
  synced,
  pending,
  failed;

  String toJson() => name;
  static SyncStatus fromJson(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}

/// A user who liked a post — returned by GET /api/posts/:id/likes
class LikeUser {
  final String id;
  final String name;
  final String? profilePicUrl;

  const LikeUser({
    required this.id,
    required this.name,
    this.profilePicUrl,
  });

  factory LikeUser.fromJson(Map<String, dynamic> json) {
    return LikeUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      profilePicUrl: ApiConstants.resolveUrl(json['profilePicUrl']?.toString()),
    );
  }
}

/// Model for comment on a post
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final String? parentId;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  /// Whether this comment was soft-deleted (content replaced with placeholder).
  final bool isDeleted;

  /// Number of direct replies (from server metadata).
  final int replyCount;

  /// In-memory child comments (populated from tree-structured API response).
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    this.parentId,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.syncStatus = SyncStatus.synced,
    this.isDeleted = false,
    this.replyCount = 0,
    this.replies = const [],
  });

  static DateTime _parseBackendDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    final s = raw.toString().trim();
    if (s.isEmpty) return DateTime.now();

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // Backend format: "DD-MM-YYYY HH:MM:SS" or "DD-MM-YYYYHH:MM:SS"
    final re = RegExp(
      r'^(\d{2})-(\d{2})-(\d{4})[\sT]?(\d{2}):(\d{2}):(\d{2})$',
    );
    final m = re.firstMatch(s);
    if (m != null) {
      final d = int.tryParse(m.group(1)!) ?? 1;
      final mo = int.tryParse(m.group(2)!) ?? 1;
      final y = int.tryParse(m.group(3)!) ?? 1970;
      final h = int.tryParse(m.group(4)!) ?? 0;
      final mi = int.tryParse(m.group(5)!) ?? 0;
      final sec = int.tryParse(m.group(6)!) ?? 0;
      return DateTime(y, mo, d, h, mi, sec);
    }

    // Epoch millis fallback
    final epoch = int.tryParse(s);
    if (epoch != null) {
      return DateTime.fromMillisecondsSinceEpoch(epoch);
    }

    return DateTime.now();
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Handle nested author object: { author: { id, name, profilePicUrl } }
    final authorObj = json['author'];
    String userId;
    String userName;
    String? userAvatarUrl;
    if (authorObj is Map<String, dynamic>) {
      userId = (authorObj['id'] ?? authorObj['_id'] ?? '').toString();
      userName = (authorObj['name'] ?? authorObj['userName'] ?? 'Unknown User')
          .toString();
      userAvatarUrl = ApiConstants.resolveUrl(
        (authorObj['profilePicUrl'] ?? authorObj['avatarUrl'])?.toString(),
      );
    } else {
      userId = (json['userId'] ?? json['authorId'] ?? json['user'] ?? '')
          .toString();
      userName = (json['userName'] ?? json['authorName'] ?? 'Unknown User')
          .toString();
      userAvatarUrl = ApiConstants.resolveUrl(
        (json['userAvatarUrl'] ?? json['authorProfilePicUrl'])?.toString(),
      );
    }

    // Parse nested replies array (tree-structured response)
    final repliesJson = json['replies'];
    final List<Comment> replies;
    if (repliesJson is List) {
      replies = repliesJson
          .whereType<Map>()
          .map((r) => Comment.fromJson(r.cast<String, dynamic>()))
          .toList();
    } else {
      replies = const [];
    }

    return Comment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      postId: (json['postId'] ?? '').toString(),
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      content: json['content'] ?? '',
      parentId: json['parentId']?.toString(),
      likeCount: json['likeCount'] ?? json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? json['liked'] ?? false,
      createdAt: _parseBackendDate(json['createdAt']),
      syncStatus: json['syncStatus'] != null
          ? SyncStatus.fromJson(json['syncStatus'])
          : SyncStatus.synced,
      isDeleted: json['isDeleted'] ?? json['deleted'] ?? false,
      replyCount: json['replyCount'] ?? json['repliesCount'] ?? replies.length,
      replies: replies,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'parentId': parentId,
      'likeCount': likeCount,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus.toJson(),
      'isDeleted': isDeleted,
      'replyCount': replyCount,
    };
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    String? parentId,
    int? likeCount,
    bool? isLiked,
    DateTime? createdAt,
    SyncStatus? syncStatus,
    bool? isDeleted,
    int? replyCount,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      replyCount: replyCount ?? this.replyCount,
      replies: replies ?? this.replies,
    );
  }
}

/// Model for saved posts
class SavedPost {
  final String postId;
  final DateTime savedAt;

  const SavedPost({required this.postId, required this.savedAt});

  factory SavedPost.fromJson(Map<String, dynamic> json) {
    return SavedPost(
      postId: json['postId'] ?? '',
      savedAt: json['savedAt'] != null
          ? DateTime.parse(json['savedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'postId': postId, 'savedAt': savedAt.toIso8601String()};
  }
}

/// Action types for offline queue
enum ActionType {
  like,
  unlike,
  save,
  unsave,
  edit,
  delete,
  comment;

  String toJson() => name;
  static ActionType fromJson(String value) {
    return ActionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActionType.like,
    );
  }
}

/// Model for action queue (offline sync)
class ActionQueue {
  final String id;
  final ActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  const ActionQueue({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  factory ActionQueue.fromJson(Map<String, dynamic> json) {
    return ActionQueue(
      id: json['id'] ?? '',
      type: ActionType.fromJson(json['type'] ?? 'like'),
      payload: json['payload'] is String
          ? Map<String, dynamic>.from(
              // Handle JSON string payload
              (json['payload'] as String).isNotEmpty ? {} : {},
            )
          : Map<String, dynamic>.from(json['payload'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      attempts: json['attempts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'attempts': attempts,
    };
  }

  ActionQueue copyWith({
    String? id,
    ActionType? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? attempts,
  }) {
    return ActionQueue(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
    );
  }
}
