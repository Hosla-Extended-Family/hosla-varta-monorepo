import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/models/chat_model.dart';

/// Database helper class for local data storage
/// Manages SQLite database for caching users and chat messages
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hosla_varta.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatarUrl TEXT,
        bio TEXT,
        email TEXT,
        isOnline INTEGER NOT NULL DEFAULT 0,
        lastSeen TEXT,
        syncedAt TEXT NOT NULL
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages(
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        chatId TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        imageUrl TEXT,
        syncedAt TEXT NOT NULL
      )
    ''');

    // Chats table
    await db.execute('''
      CREATE TABLE chats(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatarUrl TEXT,
        type TEXT NOT NULL,
        participantIds TEXT NOT NULL,
        lastMessageId TEXT,
        lastActivity TEXT NOT NULL,
        unreadCount INTEGER NOT NULL DEFAULT 0,
        isMuted INTEGER NOT NULL DEFAULT 0,
        syncedAt TEXT NOT NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_messages_chatId ON messages(chatId)');
    await db.execute(
      'CREATE INDEX idx_messages_timestamp ON messages(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_chats_lastActivity ON chats(lastActivity)',
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema changes
  }

  // ============== USER OPERATIONS ==============

  /// Insert or update user
  Future<void> upsertUser(User user) async {
    final db = await database;
    await db.insert('users', {
      'id': user.id,
      'name': user.name,
      'avatarUrl': user.avatarUrl,
      'bio': user.bio,
      'email': user.email,
      'isOnline': user.isOnline ? 1 : 0,
      'lastSeen': user.lastSeen?.toIso8601String(),
      'syncedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Insert or update multiple users
  Future<void> upsertUsers(List<User> users) async {
    final db = await database;
    final batch = db.batch();

    for (final user in users) {
      batch.insert('users', {
        'id': user.id,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'bio': user.bio,
        'email': user.email,
        'isOnline': user.isOnline ? 1 : 0,
        'lastSeen': user.lastSeen?.toIso8601String(),
        'syncedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get user by ID
  Future<User?> getUserById(String id) async {
    final db = await database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) return null;
    return _userFromMap(results.first);
  }

  /// Get all users
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final results = await db.query('users', orderBy: 'name ASC');
    return results.map((map) => _userFromMap(map)).toList();
  }

  /// Delete user
  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all users
  Future<void> deleteAllUsers() async {
    final db = await database;
    await db.delete('users');
  }

  // ============== MESSAGE OPERATIONS ==============

  /// Insert or update message
  Future<void> upsertMessage(Message message) async {
    final db = await database;
    await db.insert('messages', {
      'id': message.id,
      'senderId': message.senderId,
      'chatId': message.chatId,
      'content': message.content,
      'type': message.type.toString().split('.').last,
      'timestamp': message.timestamp.toIso8601String(),
      'isRead': message.isRead ? 1 : 0,
      'imageUrl': message.imageUrl,
      'syncedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Insert or update multiple messages
  Future<void> upsertMessages(List<Message> messages) async {
    final db = await database;
    final batch = db.batch();

    for (final message in messages) {
      batch.insert('messages', {
        'id': message.id,
        'senderId': message.senderId,
        'chatId': message.chatId,
        'content': message.content,
        'type': message.type.toString().split('.').last,
        'timestamp': message.timestamp.toIso8601String(),
        'isRead': message.isRead ? 1 : 0,
        'imageUrl': message.imageUrl,
        'syncedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get messages for a chat
  Future<List<Message>> getMessagesByChatId(String chatId) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return results.map((map) => _messageFromMap(map)).toList();
  }

  /// Get recent messages for a chat (with limit)
  Future<List<Message>> getRecentMessages(
    String chatId, {
    int limit = 50,
  }) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return results
        .map((map) => _messageFromMap(map))
        .toList()
        .reversed
        .toList();
  }

  /// Delete message
  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete messages for a chat
  Future<void> deleteMessagesForChat(String chatId) async {
    final db = await database;
    await db.delete('messages', where: 'chatId = ?', whereArgs: [chatId]);
  }

  /// Delete all messages
  Future<void> deleteAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  /// Mark messages as read in a chat
  Future<void> markMessagesAsRead(String chatId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'chatId = ? AND isRead = 0',
      whereArgs: [chatId],
    );
  }

  // ============== CHAT OPERATIONS ==============

  /// Insert or update chat
  Future<void> upsertChat(Chat chat) async {
    final db = await database;
    await db.insert('chats', {
      'id': chat.id,
      'name': chat.name,
      'avatarUrl': chat.avatarUrl,
      'type': chat.type.toString().split('.').last,
      'participantIds': chat.participantIds.join(','),
      'lastMessageId': chat.lastMessageId,
      'lastActivity': chat.lastActivity.toIso8601String(),
      'unreadCount': chat.unreadCount,
      'isMuted': chat.isMuted ? 1 : 0,
      'syncedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Insert or update multiple chats
  Future<void> upsertChats(List<Chat> chats) async {
    final db = await database;
    final batch = db.batch();

    for (final chat in chats) {
      batch.insert('chats', {
        'id': chat.id,
        'name': chat.name,
        'avatarUrl': chat.avatarUrl,
        'type': chat.type.toString().split('.').last,
        'participantIds': chat.participantIds.join(','),
        'lastMessageId': chat.lastMessageId,
        'lastActivity': chat.lastActivity.toIso8601String(),
        'unreadCount': chat.unreadCount,
        'isMuted': chat.isMuted ? 1 : 0,
        'syncedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get all chats
  Future<List<Chat>> getAllChats() async {
    final db = await database;
    final results = await db.query('chats', orderBy: 'lastActivity DESC');

    final chats = <Chat>[];
    for (final map in results) {
      final chat = await _chatFromMap(map);
      chats.add(chat);
    }
    return chats;
  }

  /// Get chat by ID
  Future<Chat?> getChatById(String id) async {
    final db = await database;
    final results = await db.query('chats', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) return null;
    return await _chatFromMap(results.first);
  }

  /// Delete chat
  Future<void> deleteChat(String id) async {
    final db = await database;
    await db.delete('chats', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all chats
  Future<void> deleteAllChats() async {
    final db = await database;
    await db.delete('chats');
  }

  /// Update chat unread count
  Future<void> updateChatUnreadCount(String chatId, int count) async {
    final db = await database;
    await db.update(
      'chats',
      {'unreadCount': count},
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  // ============== UTILITY METHODS ==============

  /// Clear all data from database
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('messages');
    await db.delete('chats');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ============== HELPER METHODS ==============

  /// Convert map to User object
  User _userFromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String?,
      email: map['email'] as String?,
      isOnline: (map['isOnline'] as int) == 1,
      lastSeen: map['lastSeen'] != null
          ? DateTime.parse(map['lastSeen'] as String)
          : null,
    );
  }

  /// Convert map to Message object
  Message _messageFromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      chatId: map['chatId'] as String,
      content: map['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: (map['isRead'] as int) == 1,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  /// Convert map to Chat object
  Future<Chat> _chatFromMap(Map<String, dynamic> map) async {
    final participantIds = (map['participantIds'] as String).split(',');
    final chatType = ChatType.values.firstWhere(
      (e) => e.toString() == 'ChatType.${map['type']}',
      orElse: () => ChatType.individual,
    );

    // Get last message if lastMessageId exists
    Message? lastMessage;
    if (map['lastMessageId'] != null) {
      final db = await database;
      final messageResults = await db.query(
        'messages',
        where: 'id = ?',
        whereArgs: [map['lastMessageId']],
      );
      if (messageResults.isNotEmpty) {
        lastMessage = _messageFromMap(messageResults.first);
      }
    }

    return Chat(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      type: chatType,
      participantIds: participantIds,
      lastMessageId: map['lastMessageId'] as String?,
      lastMessage: lastMessage,
      lastActivity: DateTime.parse(map['lastActivity'] as String),
      unreadCount: map['unreadCount'] as int,
      isMuted: (map['isMuted'] as int) == 1,
    );
  }
}
