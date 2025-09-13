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

  /// Factory constructor for creating Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      chatId: json['chatId'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
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

  const Chat({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.type,
    required this.participantIds,
    this.lastMessageId,
    this.lastMessage,
    required this.lastActivity,
    this.unreadCount = 0,
    this.isMuted = false,
  });

  /// Factory constructor for creating Chat from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
      type: ChatType.values.firstWhere(
        (e) => e.toString() == 'ChatType.${json['type']}',
        orElse: () => ChatType.individual,
      ),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      lastMessageId: json['lastMessageId'],
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage']) 
          : null,
      lastActivity: DateTime.parse(json['lastActivity']),
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
    );
  }
}
