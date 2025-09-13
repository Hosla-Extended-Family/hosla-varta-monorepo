import 'package:riverpod/riverpod.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/services/chat_service.dart';

/// Provider for ChatService instance
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// Provider for current user
final currentUserProvider = StateProvider<User?>((ref) => null);

/// Provider for list of chats
final chatsProvider = StateNotifierProvider<ChatsNotifier, List<Chat>>((ref) {
  return ChatsNotifier(ref.read(chatServiceProvider));
});

/// Provider for chat messages - takes chatId as parameter
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, List<Message>, String>((ref, chatId) {
  return ChatMessagesNotifier(ref.read(chatServiceProvider), chatId);
});

/// Provider for users list (for contacts/participants)
final usersProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  return UsersNotifier(ref.read(chatServiceProvider));
});

/// Notifier for managing chats list
class ChatsNotifier extends StateNotifier<List<Chat>> {
  final ChatService _chatService;

  ChatsNotifier(this._chatService) : super([]) {
    loadChats();
  }

  /// Load all chats for current user
  Future<void> loadChats() async {
    try {
      // TODO: Implement API call
      final chats = await _chatService.getChats();
      state = chats;
    } catch (e) {
      // Handle error - could use error provider
      print('Error loading chats: $e');
    }
  }

  /// Add a new chat
  Future<void> addChat(Chat chat) async {
    try {
      // TODO: Implement API call
      await _chatService.createChat(chat);
      state = [...state, chat];
    } catch (e) {
      print('Error adding chat: $e');
    }
  }

  /// Update chat (e.g., when new message arrives)
  void updateChat(Chat updatedChat) {
    state = state.map((chat) {
      return chat.id == updatedChat.id ? updatedChat : chat;
    }).toList();
  }

  /// Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      // TODO: Implement API call
      await _chatService.markChatAsRead(chatId);
      
      state = state.map((chat) {
        return chat.id == chatId ? chat.copyWith(unreadCount: 0) : chat;
      }).toList();
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }
}

/// Notifier for managing messages in a specific chat
class ChatMessagesNotifier extends StateNotifier<List<Message>> {
  final ChatService _chatService;
  final String chatId;

  ChatMessagesNotifier(this._chatService, this.chatId) : super([]) {
    loadMessages();
  }

  /// Load messages for this chat
  Future<void> loadMessages() async {
    try {
      // TODO: Implement API call
      final messages = await _chatService.getChatMessages(chatId);
      state = messages;
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  /// Send a new message
  Future<void> sendMessage(String content, MessageType type, {String? imageUrl}) async {
    try {
      // TODO: Implement API call
      final message = await _chatService.sendMessage(
        chatId: chatId,
        content: content,
        type: type,
        imageUrl: imageUrl,
      );
      
      state = [...state, message];
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead() async {
    try {
      // TODO: Implement API call
      await _chatService.markMessagesAsRead(chatId);
      
      state = state.map((message) => message.copyWith(isRead: true)).toList();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Add a message (e.g., when received from real-time updates)
  void addMessage(Message message) {
    state = [...state, message];
  }
}

/// Notifier for managing users list
class UsersNotifier extends StateNotifier<List<User>> {
  final ChatService _chatService;

  UsersNotifier(this._chatService) : super([]) {
    loadUsers();
  }

  /// Load all users
  Future<void> loadUsers() async {
    try {
      // TODO: Implement API call
      final users = await _chatService.getUsers();
      state = users;
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  /// Update user status
  void updateUserStatus(String userId, bool isOnline) {
    state = state.map((user) {
      return user.id == userId 
          ? user.copyWith(isOnline: isOnline, lastSeen: DateTime.now())
          : user;
    }).toList();
  }
}
