/// Message types supported in chat
enum MessageType { text, image, emoji }

/// Message model for chat functionality
class Message {
  final String id;
  final String senderId;
  final String chatId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  const Message({
    required this.id,
    required this.senderId,
    required this.chatId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  /// Factory constructor for creating Message from JSON.
  ///
  /// Accepts the live API shape:
  ///   { id, conversationId, senderId, content, createdAt }
  /// plus legacy/local keys (chatId/timestamp/isRead).
  factory Message.fromJson(Map<String, dynamic> json) {
    final createdRaw =
        json['createdAt']?.toString() ?? json['timestamp']?.toString() ?? '';
    final parsed = createdRaw.isNotEmpty ? DateTime.tryParse(createdRaw) : null;
    final created = parsed ?? DateTime.now();

    return Message(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      chatId:
          json['conversationId']?.toString() ?? json['chatId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: created,
      isRead: json['isRead'] == true,
      imageUrl: json['imageUrl'],
    );
  }

  /// Convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'chatId': chatId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  /// Create a copy of Message with updated fields
  Message copyWith({
    String? id,
    String? senderId,
    String? chatId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Chat types - individual or group chat
enum ChatType { individual, group }

/// Chat model for chat list and management
class Chat {
  final String id;
  final String name;
  final String? avatarUrl;
  final ChatType type;
  final List<String> participantIds;
  final String? lastMessageId;
  final Message? lastMessage;
  final DateTime lastActivity;
  final int unreadCount;
  final bool isMuted;

  /// Last message preview content resolved from THIS device's local store.
  /// Server metadata never includes message text.
  final String? lastMessageContent;

  const Chat({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.type,
    required this.participantIds,
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageContent,
    required this.lastActivity,
    this.unreadCount = 0,
    this.isMuted = false,
  });

  /// Factory constructor for creating Chat from JSON.
  ///
  /// Accepts the live API shape:
  ///   { id, type: 'DIRECT', name, photoUrl, participants: [...],
  ///     lastMessage, unreadCount, updatedAt }
  factory Chat.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toUpperCase() ?? 'DIRECT';
    final participants = (json['participants'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((m) => m['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    DateTime activity;
    final updatedRaw = json['updatedAt']?.toString();
    final lastActivityRaw = json['lastActivity']?.toString();
    if (updatedRaw != null && updatedRaw.isNotEmpty) {
      activity = DateTime.tryParse(updatedRaw) ?? DateTime.now();
    } else if (lastActivityRaw != null && lastActivityRaw.isNotEmpty) {
      activity = DateTime.tryParse(lastActivityRaw) ?? DateTime.now();
    } else {
      activity = DateTime.now();
    }

    return Chat(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['photoUrl']?.toString() ?? json['avatarUrl']?.toString(),
      type: rawType == 'GROUP' ? ChatType.group : ChatType.individual,
      participantIds: participants.isNotEmpty
          ? participants
          : List<String>.from(json['participantIds'] ?? []),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(
              Map<String, dynamic>.from(json['lastMessage'] as Map),
            )
          : null,
      lastActivity: activity,
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
    );
  }

  /// Convert Chat to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'type': type.toString().split('.').last,
      'participantIds': participantIds,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage?.toJson(),
      'lastActivity': lastActivity.toIso8601String(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
    };
  }

  /// Create a copy of Chat with updated fields
  Chat copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    ChatType? type,
    List<String>? participantIds,
    String? lastMessageId,
    Message? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
    bool? isMuted,
    String? lastMessageContent,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
    );
  }
}
