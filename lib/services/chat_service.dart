import 'package:hosla/models/chat_model.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/services/database_helper.dart';

/// Service class for handling chat-related API calls and data management
/// Implements offline-first approach with local database caching
class ChatService {
  // TODO: Add HTTP client dependency injection
  // final http.Client _httpClient;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Dummy data for testing - replace with actual API calls
  static final List<User> _dummyUsers = [
    User(
      id: '1',
      name: 'Alice Johnson',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b784?w=150&h=150&fit=crop&crop=face',
      bio: 'Love exploring new places!',
      email: 'alice@example.com',
      isOnline: true,
    ),
    User(
      id: '2',
      name: 'Bob Smith',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      bio: 'Tech enthusiast and coffee lover',
      email: 'bob@example.com',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    User(
      id: '3',
      name: 'Carol Williams',
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      bio: 'Artist and nature photographer',
      email: 'carol@example.com',
      isOnline: true,
    ),
    User(
      id: '4',
      name: 'Study Group',
      avatarUrl:
          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=150&h=150&fit=crop',
      bio: 'Computer Science study group',
      isOnline: false,
    ),
  ];

  static final List<Message> _dummyMessages = [
    Message(
      id: '1',
      senderId: '1',
      chatId: 'chat_1',
      content: 'Hey! How are you doing?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
    ),
    Message(
      id: '2',
      senderId: 'current_user',
      chatId: 'chat_1',
      content: 'I\'m good! Just finished my project. What about you?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isRead: true,
    ),
    Message(
      id: '3',
      senderId: '1',
      chatId: 'chat_1',
      content:
          'That\'s awesome! I\'m planning a trip to the mountains this weekend.',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
    ),
    Message(
      id: '4',
      senderId: '2',
      chatId: 'chat_2',
      content: 'Did you see the new Flutter update?',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    Message(
      id: '5',
      senderId: '3',
      chatId: 'chat_3',
      content: '📸 Check out this amazing sunset!',
      type: MessageType.emoji,
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      isRead: false,
    ),
  ];

  static final List<Chat> _dummyChats = [
    Chat(
      id: 'chat_1',
      name: 'Alice Johnson',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108755-2616b612b784?w=150&h=150&fit=crop&crop=face',
      type: ChatType.individual,
      participantIds: ['current_user', '1'],
      lastMessage: _dummyMessages[2],
      lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
      unreadCount: 1,
    ),
    Chat(
      id: 'chat_2',
      name: 'Bob Smith',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      type: ChatType.individual,
      participantIds: ['current_user', '2'],
      lastMessage: _dummyMessages[3],
      lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
    ),
    Chat(
      id: 'chat_3',
      name: 'Carol Williams',
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      type: ChatType.individual,
      participantIds: ['current_user', '3'],
      lastMessage: _dummyMessages[4],
      lastActivity: DateTime.now().subtract(const Duration(hours: 6)),
      unreadCount: 1,
    ),
    Chat(
      id: 'chat_4',
      name: 'Study Group',
      avatarUrl:
          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=150&h=150&fit=crop',
      type: ChatType.group,
      participantIds: ['current_user', '1', '2', '3'],
      lastMessage: Message(
        id: '6',
        senderId: '2',
        chatId: 'chat_4',
        content: 'Let\'s meet tomorrow at 3 PM in the library',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
    ),
  ];

  /// Get all chats for the current user
  /// Implements offline-first: returns cached data immediately, then syncs with API
  Future<List<Chat>> getChats() async {
    try {
      // First, try to get cached chats from local database
      final cachedChats = await _dbHelper.getAllChats();

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.get(Uri.parse('$baseUrl/chats'));
      //   if (response.statusCode == 200) {
      //     final List<dynamic> jsonList = json.decode(response.body);
      //     final chats = jsonList.map((json) => Chat.fromJson(json)).toList();
      //
      //     // Cache the fetched chats
      //     await _dbHelper.upsertChats(chats);
      //     return chats;
      //   }
      // } catch (e) {
      //   // Network error - return cached data if available
      //   print('Network error, using cached chats: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Cache dummy data
      await _dbHelper.upsertChats(_dummyChats);

      return cachedChats.isNotEmpty ? cachedChats : _dummyChats;
    } catch (e) {
      print('Error loading chats: $e');
      rethrow;
    }
  }

  /// Get messages for a specific chat
  /// Implements offline-first: returns cached messages immediately, then syncs with API
  Future<List<Message>> getChatMessages(String chatId) async {
    try {
      // First, get cached messages from local database
      final cachedMessages = await _dbHelper.getMessagesByChatId(chatId);

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.get(Uri.parse('$baseUrl/chats/$chatId/messages'));
      //   if (response.statusCode == 200) {
      //     final List<dynamic> jsonList = json.decode(response.body);
      //     final messages = jsonList.map((json) => Message.fromJson(json)).toList();
      //
      //     // Cache the fetched messages
      //     await _dbHelper.upsertMessages(messages);
      //     return messages;
      //   }
      // } catch (e) {
      //   // Network error - return cached data if available
      //   print('Network error, using cached messages: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      final messages = _dummyMessages
          .where((message) => message.chatId == chatId)
          .toList();

      // Cache dummy data
      if (messages.isNotEmpty) {
        await _dbHelper.upsertMessages(messages);
      }

      return cachedMessages.isNotEmpty ? cachedMessages : messages;
    } catch (e) {
      print('Error loading messages: $e');
      rethrow;
    }
  }

  /// Send a message to a chat
  /// Saves to local database first, then syncs with API
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    String? imageUrl,
  }) async {
    try {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'current_user',
        chatId: chatId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );

      // Save to local database immediately
      await _dbHelper.upsertMessage(message);

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.post(
      //     Uri.parse('$baseUrl/chats/$chatId/messages'),
      //     headers: {'Content-Type': 'application/json'},
      //     body: json.encode({
      //       'content': content,
      //       'type': type.toString().split('.').last,
      //       'imageUrl': imageUrl,
      //     }),
      //   );
      //   if (response.statusCode == 201) {
      //     final serverMessage = Message.fromJson(json.decode(response.body));
      //     // Update local database with server response
      //     await _dbHelper.upsertMessage(serverMessage);
      //     return serverMessage;
      //   }
      // } catch (e) {
      //   // Network error - message is already saved locally
      //   print('Network error sending message, saved locally: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 200));

      return message;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Create a new chat
  /// Saves to local database first, then syncs with API
  Future<Chat> createChat(Chat chat) async {
    try {
      // Save to local database immediately
      await _dbHelper.upsertChat(chat);

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.post(
      //     Uri.parse('$baseUrl/chats'),
      //     headers: {'Content-Type': 'application/json'},
      //     body: json.encode(chat.toJson()),
      //   );
      //   if (response.statusCode == 201) {
      //     final serverChat = Chat.fromJson(json.decode(response.body));
      //     // Update local database with server response
      //     await _dbHelper.upsertChat(serverChat);
      //     return serverChat;
      //   }
      // } catch (e) {
      //   // Network error - chat is already saved locally
      //   print('Network error creating chat, saved locally: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      return chat;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  /// Mark a chat as read
  /// Updates local database first, then syncs with API
  Future<void> markChatAsRead(String chatId) async {
    try {
      // Update local database immediately
      await _dbHelper.updateChatUnreadCount(chatId, 0);

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.put(Uri.parse('$baseUrl/chats/$chatId/read'));
      //   if (response.statusCode != 200) {
      //     throw Exception('Failed to mark chat as read on server');
      //   }
      // } catch (e) {
      //   // Network error - already updated locally
      //   print('Network error marking chat as read, updated locally: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error marking chat as read: $e');
      rethrow;
    }
  }

  /// Mark messages in a chat as read
  /// Updates local database first, then syncs with API
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      // Update local database immediately
      await _dbHelper.markMessagesAsRead(chatId);

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.put(Uri.parse('$baseUrl/chats/$chatId/messages/read'));
      //   if (response.statusCode != 200) {
      //     throw Exception('Failed to mark messages as read on server');
      //   }
      // } catch (e) {
      //   // Network error - already updated locally
      //   print('Network error marking messages as read, updated locally: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  /// Get all users (for contacts/participants)
  /// Implements offline-first: returns cached users, then syncs with API
  Future<List<User>> getUsers() async {
    try {
      // First, try to get cached users from local database
      final cachedUsers = await _dbHelper.getAllUsers();

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.get(Uri.parse('$baseUrl/users'));
      //   if (response.statusCode == 200) {
      //     final List<dynamic> jsonList = json.decode(response.body);
      //     final users = jsonList.map((json) => User.fromJson(json)).toList();
      //
      //     // Cache the fetched users
      //     await _dbHelper.upsertUsers(users);
      //     return users;
      //   }
      // } catch (e) {
      //   // Network error - return cached data if available
      //   print('Network error, using cached users: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 400));

      // Cache dummy data
      await _dbHelper.upsertUsers(_dummyUsers);

      return cachedUsers.isNotEmpty ? cachedUsers : _dummyUsers;
    } catch (e) {
      print('Error loading users: $e');
      rethrow;
    }
  }

  /// Search users by name or email
  /// Searches local database for offline support
  Future<List<User>> searchUsers(String query) async {
    try {
      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.get(Uri.parse('$baseUrl/users/search?q=$query'));
      //   if (response.statusCode == 200) {
      //     final List<dynamic> jsonList = json.decode(response.body);
      //     return jsonList.map((json) => User.fromJson(json)).toList();
      //   }
      // } catch (e) {
      //   // Network error - search local database
      //   print('Network error, searching cached users: $e');
      // }

      // Get all users from local database and filter
      final allUsers = await _dbHelper.getAllUsers();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      // If no cached users, use dummy data
      final users = allUsers.isNotEmpty ? allUsers : _dummyUsers;

      return users
          .where(
            (user) =>
                user.name.toLowerCase().contains(query.toLowerCase()) ||
                (user.email?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }
}
