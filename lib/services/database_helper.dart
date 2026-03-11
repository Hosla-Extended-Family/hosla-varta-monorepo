import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/models/post_model.dart';

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
      version: 4,
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
        phone TEXT,
        isOnline INTEGER NOT NULL DEFAULT 0,
        lastSeen TEXT,
        syncedAt TEXT NOT NULL
      )
    ''');

    // Posts table
    await db.execute('''
      CREATE TABLE posts(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userAvatarUrl TEXT,
        content TEXT NOT NULL,
        imageUrl TEXT,
        tags TEXT,
        likeCount INTEGER NOT NULL DEFAULT 0,
        commentCount INTEGER NOT NULL DEFAULT 0,
        shareCount INTEGER NOT NULL DEFAULT 0,
        isLiked INTEGER NOT NULL DEFAULT 0,
        isSaved INTEGER NOT NULL DEFAULT 0,
        visibility TEXT NOT NULL DEFAULT 'PUBLIC',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        fetchedAt TEXT NOT NULL,
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

    // Comments table
    await db.execute('''
      CREATE TABLE comments(
        id TEXT PRIMARY KEY,
        postId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userAvatarUrl TEXT,
        content TEXT NOT NULL,
        parentId TEXT,
        likeCount INTEGER NOT NULL DEFAULT 0,
        isLiked INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL DEFAULT 'synced',
        FOREIGN KEY(postId) REFERENCES posts(id) ON DELETE CASCADE
      )
    ''');

    // Saved posts table
    await db.execute('''
      CREATE TABLE saved_posts(
        postId TEXT PRIMARY KEY,
        savedAt TEXT NOT NULL,
        FOREIGN KEY(postId) REFERENCES posts(id) ON DELETE CASCADE
      )
    ''');

    // Action queue table for offline sync
    await db.execute('''
      CREATE TABLE action_queue(
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_posts_userId ON posts(userId)');
    await db.execute('CREATE INDEX idx_posts_createdAt ON posts(createdAt)');
    await db.execute('CREATE INDEX idx_posts_isSaved ON posts(isSaved)');
    await db.execute('CREATE INDEX idx_posts_fetchedAt ON posts(fetchedAt)');
    await db.execute('CREATE INDEX idx_comments_postId ON comments(postId)');
    await db.execute('CREATE INDEX idx_comments_userId ON comments(userId)');
    await db.execute(
      'CREATE INDEX idx_comments_parentId ON comments(parentId)',
    );
    await db.execute(
      'CREATE INDEX idx_comments_syncStatus ON comments(syncStatus)',
    );
    await db.execute(
      'CREATE INDEX idx_saved_posts_savedAt ON saved_posts(savedAt)',
    );
    await db.execute(
      'CREATE INDEX idx_action_queue_type ON action_queue(type)',
    );
    await db.execute(
      'CREATE INDEX idx_action_queue_createdAt ON action_queue(createdAt)',
    );
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
    if (oldVersion < 2) {
      // Add fetchedAt column to posts table
      await db.execute(
        'ALTER TABLE posts ADD COLUMN fetchedAt TEXT NOT NULL DEFAULT ""',
      );

      // Create comments table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comments(
          id TEXT PRIMARY KEY,
          postId TEXT NOT NULL,
          userId TEXT NOT NULL,
          userName TEXT NOT NULL,
          userAvatarUrl TEXT,
          content TEXT NOT NULL,
          likeCount INTEGER NOT NULL DEFAULT 0,
          isLiked INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          syncStatus TEXT NOT NULL DEFAULT 'synced',
          FOREIGN KEY(postId) REFERENCES posts(id) ON DELETE CASCADE
        )
      ''');

      // Create saved_posts table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saved_posts(
          postId TEXT PRIMARY KEY,
          savedAt TEXT NOT NULL,
          FOREIGN KEY(postId) REFERENCES posts(id) ON DELETE CASCADE
        )
      ''');

      // Create action_queue table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS action_queue(
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          payload TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Create new indexes
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_posts_isSaved ON posts(isSaved)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_posts_fetchedAt ON posts(fetchedAt)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_comments_postId ON comments(postId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_comments_userId ON comments(userId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_comments_syncStatus ON comments(syncStatus)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_saved_posts_savedAt ON saved_posts(savedAt)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_action_queue_type ON action_queue(type)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_action_queue_createdAt ON action_queue(createdAt)',
      );
    }

    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE posts ADD COLUMN visibility TEXT NOT NULL DEFAULT 'PUBLIC'",
      );
    }

    if (oldVersion < 4) {
      // Add parentId column for comment threading
      try {
        await db.execute('ALTER TABLE comments ADD COLUMN parentId TEXT');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_comments_parentId ON comments(parentId)',
        );
      } catch (_) {
        // Column may already exist
      }
    }
  }

  // ============== USER OPERATIONS ==============

  /// Insert or update user
  Future<void> upsertUser(User user) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('users', {
      'id': user.id,
      'name': user.name,
      'avatarUrl': user.avatarUrl,
      'bio': user.bio,
      'email': user.email,
      'phone': user.phone,
      'isOnline': user.isOnline ? 1 : 0,
      'lastSeen': user.lastSeen?.toIso8601String(),
      'syncedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Insert or update multiple users
  Future<void> upsertUsers(List<User> users) async {
    if (kIsWeb) return;
    final db = await database;
    final batch = db.batch();

    for (final user in users) {
      batch.insert('users', {
        'id': user.id,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'bio': user.bio,
        'email': user.email,
        'phone': user.phone,
        'isOnline': user.isOnline ? 1 : 0,
        'lastSeen': user.lastSeen?.toIso8601String(),
        'syncedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get user by ID
  Future<User?> getUserById(String id) async {
    if (kIsWeb) return null;
    final db = await database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) return null;
    return _userFromMap(results.first);
  }

  /// Get all users
  Future<List<User>> getAllUsers() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query('users', orderBy: 'name ASC');
    return results.map((map) => _userFromMap(map)).toList();
  }

  /// Delete user
  Future<void> deleteUser(String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all users
  Future<void> deleteAllUsers() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('users');
  }

  // ============== MESSAGE OPERATIONS ==============

  /// Insert or update message
  Future<void> upsertMessage(Message message) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
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
    if (kIsWeb) return [];
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
    if (kIsWeb) return [];
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
    if (kIsWeb) return;
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete messages for a chat
  Future<void> deleteMessagesForChat(String chatId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('messages', where: 'chatId = ?', whereArgs: [chatId]);
  }

  /// Delete all messages
  Future<void> deleteAllMessages() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('messages');
  }

  /// Mark messages as read in a chat
  Future<void> markMessagesAsRead(String chatId) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
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
    if (kIsWeb) return;
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
    if (kIsWeb) return [];
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
    if (kIsWeb) return null;
    final db = await database;
    final results = await db.query('chats', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) return null;
    return await _chatFromMap(results.first);
  }

  /// Delete chat
  Future<void> deleteChat(String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('chats', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all chats
  Future<void> deleteAllChats() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('chats');
  }

  /// Update chat unread count
  Future<void> updateChatUnreadCount(String chatId, int count) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'chats',
      {'unreadCount': count},
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  // ============== UTILITY METHODS ==============

  /// Clear all data from database (used on logout)
  Future<void> clearAllData() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('users');
    await db.delete('messages');
    await db.delete('chats');
    await db.delete('posts');
    await db.delete('comments');
    await db.delete('saved_posts');
    await db.delete('action_queue');
  }

  /// Close database connection
  Future<void> close() async {
    if (kIsWeb) return;
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
      phone: map['phone'] as String?,
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

  // ============== POST OPERATIONS ==============

  /// Insert or update post
  Future<void> upsertPost(Post post) async {
    if (kIsWeb) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('posts', {
      'id': post.id,
      'userId': post.userId,
      'userName': post.userName,
      'userAvatarUrl': post.userAvatarUrl,
      'content': post.content,
      'imageUrl': post.imageUrl,
      'tags': post.tags.join(','),
      'likeCount': post.likeCount,
      'commentCount': post.commentCount,
      'shareCount': post.shareCount,
      'isLiked': post.isLiked ? 1 : 0,
      'isSaved': post.isSaved ? 1 : 0,
      'visibility': post.visibility,
      'createdAt': post.createdAt.toIso8601String(),
      'updatedAt': post.updatedAt?.toIso8601String(),
      'fetchedAt': now,
      'syncedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Insert or update multiple posts
  Future<void> upsertPosts(List<Post> posts) async {
    if (kIsWeb) return;
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final post in posts) {
      batch.insert('posts', {
        'id': post.id,
        'userId': post.userId,
        'userName': post.userName,
        'userAvatarUrl': post.userAvatarUrl,
        'content': post.content,
        'imageUrl': post.imageUrl,
        'tags': post.tags.join(','),
        'likeCount': post.likeCount,
        'commentCount': post.commentCount,
        'shareCount': post.shareCount,
        'isLiked': post.isLiked ? 1 : 0,
        'isSaved': post.isSaved ? 1 : 0,
        'visibility': post.visibility,
        'createdAt': post.createdAt.toIso8601String(),
        'updatedAt': post.updatedAt?.toIso8601String(),
        'fetchedAt': now,
        'syncedAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get post by ID
  Future<Post?> getPostById(String id) async {
    if (kIsWeb) return null;
    final db = await database;
    final results = await db.query('posts', where: 'id = ?', whereArgs: [id]);

    if (results.isEmpty) return null;
    return _postFromMap(results.first);
  }

  /// Get all posts
  Future<List<Post>> getAllPosts() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query('posts', orderBy: 'createdAt DESC');
    return results.map((map) => _postFromMap(map)).toList();
  }

  /// Delete post
  Future<void> deletePost(String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('posts', where: 'id = ?', whereArgs: [id]);
  }

  /// Convert database map to Post object
  Post _postFromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userAvatarUrl: map['userAvatarUrl'] as String?,
      content: map['content'] as String,
      imageUrl: map['imageUrl'] as String?,
      tags:
          (map['tags'] as String?)
              ?.split(',')
              .where((t) => t.isNotEmpty)
              .toList() ??
          [],
      likeCount: map['likeCount'] as int,
      commentCount: map['commentCount'] as int,
      shareCount: map['shareCount'] as int,
      isLiked: (map['isLiked'] as int) == 1,
      isSaved: (map['isSaved'] as int) == 1,
      visibility: map['visibility']?.toString().toUpperCase() ?? 'PUBLIC',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Get posts by user ID
  Future<List<Post>> getPostsByUserId(String userId) async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query(
      'posts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => _postFromMap(map)).toList();
  }

  /// Get saved posts
  Future<List<Post>> getSavedPosts() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.rawQuery('''
      SELECT p.* FROM posts p
      INNER JOIN saved_posts sp ON p.id = sp.postId
      ORDER BY sp.savedAt DESC
    ''');
    return results.map((map) => _postFromMap(map)).toList();
  }

  /// Update post (for edits)
  Future<void> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
    required List<String> tags,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'posts',
      {
        'content': content,
        'imageUrl': imageUrl,
        'tags': tags.join(','),
        'updatedAt': DateTime.now().toIso8601String(),
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [postId],
    );
  }

  /// Update post like status
  Future<void> updatePostLike(
    String postId,
    bool isLiked,
    int likeCount,
  ) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'posts',
      {
        'isLiked': isLiked ? 1 : 0,
        'likeCount': likeCount,
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [postId],
    );
  }

  /// Update post save status
  Future<void> updatePostSave(String postId, bool isSaved) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'posts',
      {
        'isSaved': isSaved ? 1 : 0,
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [postId],
    );
  }

  /// Delete old posts (retention policy)
  Future<void> deleteOldPosts({int retentionDays = 90}) async {
    if (kIsWeb) return;
    final db = await database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .toIso8601String();

    // Delete posts that are not saved and older than retention period
    await db.delete(
      'posts',
      where: 'isSaved = 0 AND fetchedAt < ?',
      whereArgs: [cutoffDate],
    );
  }

  // ============== SAVED POSTS OPERATIONS ==============

  /// Save a post
  Future<void> savePost(String postId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('saved_posts', {
      'postId': postId,
      'savedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Update isSaved flag in posts table
    await updatePostSave(postId, true);
  }

  /// Unsave a post
  Future<void> unsavePost(String postId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('saved_posts', where: 'postId = ?', whereArgs: [postId]);

    // Update isSaved flag in posts table
    await updatePostSave(postId, false);
  }

  /// Check if post is saved
  Future<bool> isPostSaved(String postId) async {
    if (kIsWeb) return false;
    final db = await database;
    final results = await db.query(
      'saved_posts',
      where: 'postId = ?',
      whereArgs: [postId],
    );
    return results.isNotEmpty;
  }

  // ============== COMMENT OPERATIONS ==============

  /// Insert or update comment
  Future<void> upsertComment(Comment comment) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('comments', {
      'id': comment.id,
      'postId': comment.postId,
      'userId': comment.userId,
      'userName': comment.userName,
      'userAvatarUrl': comment.userAvatarUrl,
      'content': comment.content,
      'parentId': comment.parentId,
      'likeCount': comment.likeCount,
      'isLiked': comment.isLiked ? 1 : 0,
      'createdAt': comment.createdAt.toIso8601String(),
      'syncStatus': comment.syncStatus.toJson(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get comments for a post
  Future<List<Comment>> getCommentsByPostId(String postId) async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query(
      'comments',
      where: 'postId = ?',
      whereArgs: [postId],
      orderBy: 'createdAt ASC',
    );
    return results.map((map) => _commentFromMap(map)).toList();
  }

  /// Get pending comments (not synced)
  Future<List<Comment>> getPendingComments() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query(
      'comments',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );
    return results.map((map) => _commentFromMap(map)).toList();
  }

  /// Update comment sync status
  Future<void> updateCommentSyncStatus(
    String commentId,
    SyncStatus status,
  ) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'comments',
      {'syncStatus': status.toJson()},
      where: 'id = ?',
      whereArgs: [commentId],
    );
  }

  /// Delete comment
  Future<void> deleteComment(String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('comments', where: 'id = ?', whereArgs: [id]);
  }

  /// Convert database map to Comment object
  Comment _commentFromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      postId: map['postId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userAvatarUrl: map['userAvatarUrl'] as String?,
      content: map['content'] as String,
      parentId: map['parentId'] as String?,
      likeCount: map['likeCount'] as int,
      isLiked: (map['isLiked'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      syncStatus: SyncStatus.fromJson(map['syncStatus'] as String),
    );
  }

  // ============== ACTION QUEUE OPERATIONS ==============

  /// Add action to queue
  Future<void> enqueueAction(ActionQueue action) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('action_queue', {
      'id': action.id,
      'type': action.type.toJson(),
      'payload': action.payload.toString(),
      'createdAt': action.createdAt.toIso8601String(),
      'attempts': action.attempts,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all queued actions
  Future<List<ActionQueue>> getQueuedActions() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query('action_queue', orderBy: 'createdAt ASC');
    return results.map((map) => _actionQueueFromMap(map)).toList();
  }

  /// Get queued actions by type
  Future<List<ActionQueue>> getQueuedActionsByType(ActionType type) async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query(
      'action_queue',
      where: 'type = ?',
      whereArgs: [type.toJson()],
      orderBy: 'createdAt ASC',
    );
    return results.map((map) => _actionQueueFromMap(map)).toList();
  }

  /// Update action queue attempts
  Future<void> updateActionAttempts(String actionId, int attempts) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'action_queue',
      {'attempts': attempts},
      where: 'id = ?',
      whereArgs: [actionId],
    );
  }

  /// Remove action from queue
  Future<void> dequeueAction(String actionId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('action_queue', where: 'id = ?', whereArgs: [actionId]);
  }

  /// Clear all queued actions
  Future<void> clearActionQueue() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('action_queue');
  }

  /// Convert database map to ActionQueue object
  ActionQueue _actionQueueFromMap(Map<String, dynamic> map) {
    return ActionQueue(
      id: map['id'] as String,
      type: ActionType.fromJson(map['type'] as String),
      payload: Map<String, dynamic>.from({}), // Simplified for now
      createdAt: DateTime.parse(map['createdAt'] as String),
      attempts: map['attempts'] as int,
    );
  }
}
