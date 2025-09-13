import 'package:hosla/models/chat_model.dart';
import 'package:hosla/models/user_model.dart';

/// Service class for handling chat-related API calls and data management
class ChatService {
  // TODO: Add HTTP client dependency injection
  // final http.Client _httpClient;
  
  /// Dummy data for testing - replace with actual API calls
  static final List<User> _dummyUsers = [
    User(
      id: '1',
      name: 'Alice Johnson',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b784?w=150&h=150&fit=crop&crop=face',
      bio: 'Love exploring new places!',
      email: 'alice@example.com',
      isOnline: true,
    ),
    User(
      id: '2',
      name: 'Bob Smith',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      bio: 'Tech enthusiast and coffee lover',
      email: 'bob@example.com',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    User(
      id: '3',
      name: 'Carol Williams',
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      bio: 'Artist and nature photographer',
      email: 'carol@example.com',
      isOnline: true,
    ),
    User(
      id: '4',
      name: 'Study Group',
      avatarUrl: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=150&h=150&fit=crop',
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
      content: 'That\'s awesome! I\'m planning a trip to the mountains this weekend.',
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
      avatarUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b784?w=150&h=150&fit=crop&crop=face',
      type: ChatType.individual,
      participantIds: ['current_user', '1'],
      lastMessage: _dummyMessages[2],
      lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
      unreadCount: 1,
    ),
    Chat(
      id: 'chat_2',
      name: 'Bob Smith',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      type: ChatType.individual,
      participantIds: ['current_user', '2'],
      lastMessage: _dummyMessages[3],
      lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
    ),
    Chat(
      id: 'chat_3',
      name: 'Carol Williams',
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      type: ChatType.individual,
      participantIds: ['current_user', '3'],
      lastMessage: _dummyMessages[4],
      lastActivity: DateTime.now().subtract(const Duration(hours: 6)),
      unreadCount: 1,
    ),
    Chat(
      id: 'chat_4',
      name: 'Study Group',
      avatarUrl: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=150&h=150&fit=crop',
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
  /// TODO: Implement actual API call
  /// Example: GET /api/chats
  Future<List<Chat>> getChats() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/chats'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => Chat.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load chats');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _dummyChats;
  }

  /// Get messages for a specific chat
  /// TODO: Implement actual API call
  /// Example: GET /api/chats/{chatId}/messages
  Future<List<Message>> getChatMessages(String chatId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/chats/$chatId/messages'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => Message.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load messages');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _dummyMessages.where((message) => message.chatId == chatId).toList();
  }

  /// Send a message to a chat
  /// TODO: Implement actual API call
  /// Example: POST /api/chats/{chatId}/messages
  Future<Message> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    String? imageUrl,
  }) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(
    //   Uri.parse('$baseUrl/chats/$chatId/messages'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({
    //     'content': content,
    //     'type': type.toString().split('.').last,
    //     'imageUrl': imageUrl,
    //   }),
    // );
    // if (response.statusCode == 201) {
    //   return Message.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to send message');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_user',
      chatId: chatId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );
    
    return message;
  }

  /// Create a new chat
  /// TODO: Implement actual API call
  /// Example: POST /api/chats
  Future<Chat> createChat(Chat chat) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(
    //   Uri.parse('$baseUrl/chats'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(chat.toJson()),
    // );
    // if (response.statusCode == 201) {
    //   return Chat.fromJson(json.decode(response.body));
    // }
    // throw Exception('Failed to create chat');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return chat;
  }

  /// Mark a chat as read
  /// TODO: Implement actual API call
  /// Example: PUT /api/chats/{chatId}/read
  Future<void> markChatAsRead(String chatId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.put(Uri.parse('$baseUrl/chats/$chatId/read'));
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to mark chat as read');
    // }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Mark messages in a chat as read
  /// TODO: Implement actual API call
  /// Example: PUT /api/chats/{chatId}/messages/read
  Future<void> markMessagesAsRead(String chatId) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.put(Uri.parse('$baseUrl/chats/$chatId/messages/read'));
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to mark messages as read');
    // }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Get all users (for contacts/participants)
  /// TODO: Implement actual API call
  /// Example: GET /api/users
  Future<List<User>> getUsers() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/users'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => User.fromJson(json)).toList();
    // }
    // throw Exception('Failed to load users');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    return _dummyUsers;
  }

  /// Search users by name or email
  /// TODO: Implement actual API call
  /// Example: GET /api/users/search?q={query}
  Future<List<User>> searchUsers(String query) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/users/search?q=$query'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonList = json.decode(response.body);
    //   return jsonList.map((json) => User.fromJson(json)).toList();
    // }
    // throw Exception('Failed to search users');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _dummyUsers.where((user) => 
      user.name.toLowerCase().contains(query.toLowerCase()) ||
      (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }
}
