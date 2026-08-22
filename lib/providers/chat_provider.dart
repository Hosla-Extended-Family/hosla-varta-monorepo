import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/services/chat_service.dart';
import 'package:hosla/services/chat_socket_service.dart';

/// Provider for ChatService instance
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// Legacy current-user provider (kept for existing pages).
final currentUserProvider = StateProvider<User?>((ref) => null);

/// Tracks the currently active/open chat screen ID (to suppress notifications inside active chat).
final activeChatIdProvider = StateProvider<String?>((ref) => null);

/// Realtime socket singleton
final chatSocketProvider = Provider<ChatSocketService>(
  (ref) => ChatSocketService.instance,
);

/// Provider for list of chats
final chatsProvider =
    StateNotifierProvider<ChatsNotifier, AsyncValue<List<Chat>>>((ref) {
  final notifier = ChatsNotifier(ref.read(chatServiceProvider));
  ref.onDispose(notifier.disposeStreams);
  return notifier;
});

/// Provider for chat messages - takes chatId as parameter
final chatMessagesProvider = StateNotifierProvider.family<
    ChatMessagesNotifier, AsyncValue<List<Message>>, String>((ref, chatId) {
  final notifier = ChatMessagesNotifier(
    ref.read(chatServiceProvider),
    ref.read(chatSocketProvider),
    chatId,
  );
  ref.onDispose(notifier.disposeStreams);
  return notifier;
});

class ChatsNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  final ChatService _chatService;
  StreamSubscription? _messageSub;
  StreamSubscription? _refreshSub;

  ChatsNotifier(this._chatService) : super(const AsyncValue.loading()) {
    loadChats();
    _listenRealtime();
  }

  void _listenRealtime() {
    _refreshSub = ChatSocketService.instance.conversationRefresh.listen((_) {
      loadChats(silent: true);
    });
    _messageSub = ChatSocketService.instance.messages.listen((_) {
      loadChats(silent: true);
    });
  }

  Future<void> loadChats({bool silent = false}) async {
    try {
      if (!silent) state = const AsyncValue.loading();
      final chats = await _chatService.getChats();
      state = AsyncValue.data(chats);
    } catch (e, st) {
      if (state is! AsyncData<List<Chat>>) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => loadChats(silent: true);

  /// Kept for group-chat flow compatibility (groups are not live yet).
  Future<void> addChat(Chat chat) async {
    state = state.whenData((chats) => [chat, ...chats]);
  }

  void applyLocalUpdate(Chat updatedChat) {
    state = state.whenData((chats) {
      final exists = chats.any((c) => c.id == updatedChat.id);
      return exists
          ? chats.map((c) => c.id == updatedChat.id ? updatedChat : c).toList()
          : [updatedChat, ...chats];
    });
  }

  Future<void> markChatAsRead(String chatId) async {
    await _chatService.markMessagesAsRead(chatId);
    state = state.whenData(
      (chats) => chats
          .map((c) => c.id == chatId ? c.copyWith(unreadCount: 0) : c)
          .toList(),
    );
  }

  void disposeStreams() {
    _messageSub?.cancel();
    _refreshSub?.cancel();
  }
}

/// Tracks online user IDs in real-time via Socket.IO presence events.
final onlineUsersProvider =
    StateNotifierProvider<OnlineUsersNotifier, Set<String>>((ref) {
  return OnlineUsersNotifier(ChatSocketService.instance);
});

class OnlineUsersNotifier extends StateNotifier<Set<String>> {
  StreamSubscription? _presenceSub;

  OnlineUsersNotifier(ChatSocketService socket) : super(<String>{}) {
    _presenceSub = socket.presenceUpdates.listen((event) {
      final userId = event['userId']?.toString();
      final isOnline = event['isOnline'] == true;
      if (userId == null || userId.isEmpty) return;

      if (isOnline) {
        state = {...state, userId};
      } else {
        state = state.where((id) => id != userId).toSet();
      }
    });
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    super.dispose();
  }
}

/// Placeholder users list (contacts are resolved from friends search).
final usersProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  return UsersNotifier();
});

class UsersNotifier extends StateNotifier<List<User>> {
  UsersNotifier() : super(const []);

  void updateUserStatus(String userId, bool isOnline) {
    state = state
        .map((user) => user.id == userId
            ? user.copyWith(isOnline: isOnline, lastSeen: DateTime.now())
            : user)
        .toList();
  }
}

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final ChatService _chatService;
  final String chatId;
  StreamSubscription? _messageSub;
  StreamSubscription? _readSub;

  ChatMessagesNotifier(this._chatService, ChatSocketService socket, this.chatId)
      : super(const AsyncValue.loading()) {
    loadMessages();
    _listenRealtime(socket);
  }

  void _listenRealtime(ChatSocketService socket) {
    socket.joinChat(chatId);

    _messageSub = socket.messages.listen((msg) {
      if (msg['conversationId']?.toString() != chatId) return;

      // Persist content on THIS device before displaying.
      _chatService.saveIncoming(msg);

      final incoming = Message.fromJson(msg);
      state = state.whenData((messages) {
        if (messages.any((m) => m.id == incoming.id)) return messages;
        return [...messages, incoming];
      });
      markMessagesAsRead();
    });

    _readSub = socket.readReceipts.listen((receipt) {
      if (receipt['conversationId']?.toString() != chatId) return;
      state = state.whenData((messages) {
        return messages.map((m) {
          if (!m.isRead) {
            final updated = m.copyWith(isRead: true);
            _chatService.saveIncoming(updated.toJson());
            return updated;
          }
          return m;
        }).toList();
      });
    });
  }

  Future<void> loadMessages() async {
    try {
      state = const AsyncValue.loading();
      final messages = await _chatService.getChatMessages(chatId);
      state = AsyncValue.data(messages);

      await markMessagesAsRead();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final messages = await _chatService.getChatMessages(chatId);
      state = AsyncValue.data(messages);
    } catch (_) {}
  }

  /// Send via realtime socket (REST fallback inside the service).
  Future<bool> sendMessage(String content, {String? senderId}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    // 1. Instantly append temporary optimistic message for 0ms delay
    final tempId = 'tmp_${DateTime.now().microsecondsSinceEpoch}';
    final tempMsg = Message(
      id: tempId,
      senderId: senderId ?? '',
      chatId: chatId,
      content: trimmed,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    state = state.whenData((messages) {
      if (messages.any((m) => m.id == tempId)) return messages;
      return [...messages, tempMsg];
    });

    // 2. Deliver via socket / REST
    final sent = await _chatService.sendMessage(
      chatId: chatId,
      content: trimmed,
    );
    if (sent == null) return false;

    // 3. Reconcile temporary message with server-assigned ID & metadata
    state = state.whenData((messages) {
      final updated =
          messages.map((m) => m.id == tempId ? sent : m).toList();
      final Map<String, Message> dedup = {};
      for (final m in updated) {
        dedup[m.id] = m;
      }
      return dedup.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
    return true;
  }

  /// Optimistic local echo (used while awaiting server ack).
  void addPending(Message message) {
    state = state.whenData((messages) => [...messages, message]);
  }

  Future<void> markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(chatId);
  }

  void disposeStreams() {
    _messageSub?.cancel();
    _readSub?.cancel();
  }
}
