import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/services/api_client.dart';
import 'package:hosla/services/chat_socket_service.dart';
import 'package:hosla/services/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent Web message store backed by browser localStorage (SharedPreferences)
/// with in-memory caching for zero-latency lookups.
class _WebStorageMessageStore {
  static final Map<String, List<Message>> _memoryCache = {};

  String _key(String chatId) => 'hosla_chat_messages_$chatId';

  Future<void> upsert(Message message) async {
    final list = await byChat(message.chatId);
    final idx = list.indexWhere((m) => m.id == message.id);
    if (idx >= 0) {
      list[idx] = message;
    } else {
      list.add(message);
    }
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _memoryCache[message.chatId] = list;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((m) => m.toJson()).toList();
      await prefs.setString(_key(message.chatId), jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> remove(String messageId, String chatId) async {
    final list = await byChat(chatId);
    list.removeWhere((m) => m.id == messageId);
    _memoryCache[chatId] = list;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((m) => m.toJson()).toList();
      await prefs.setString(_key(chatId), jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<Message>> byChat(String chatId) async {
    if (_memoryCache.containsKey(chatId)) {
      return List<Message>.from(
        _memoryCache[chatId]!.where((m) => m.content.trim().isNotEmpty),
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(chatId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final list = decoded
            .whereType<Map>()
            .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
            .where((m) => m.content.trim().isNotEmpty)
            .toList();
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _memoryCache[chatId] = list;
        return List<Message>.from(list);
      }
    } catch (_) {}

    return [];
  }

  Future<Message?> byId(String chatId, String messageId) async {
    final list = await byChat(chatId);
    for (final m in list) {
      if (m.id == messageId) return m;
    }
    return null;
  }
}

class _SqfliteMessageStore {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> upsert(Message message) => _db.upsertMessage(message);

  Future<void> remove(String messageId, String chatId) async {
    final all = await _db.getMessagesByChatId(chatId);
    for (final m in all.where((m) => m.id == messageId)) {
      await _db.deleteMessage(m.id);
    }
  }

  Future<List<Message>> byChat(String chatId) =>
      _db.getMessagesByChatId(chatId);

  Future<Message?> byId(String chatId, String messageId) async {
    final all = await _db.getMessagesByChatId(chatId);
    for (final m in all) {
      if (m.id == messageId) return m;
    }
    return null;
  }
}

/// Live chat service backed by the Hosla REST API + Socket.IO.
///
/// PRIVACY MODEL: the backend stores only metadata (message ids, sender,
/// timestamps). Message CONTENT exists solely on the participants' devices:
///  - outgoing/incoming texts are persisted here via [_localStore]
///  - the server relays payloads live over Socket.IO and queues them in a
///    short-lived Redis buffer (48h) for offline recipients
/// History shown in a chat comes from this device's local store.
class ChatService {
  final ApiClient _api = ApiClient.instance;

  static final _WebStorageMessageStore _webStore = _WebStorageMessageStore();
  _SqfliteMessageStore? _sqfliteStore;

  dynamic get _localStore {
    if (kIsWeb) return _webStore;
    return _sqfliteStore ??= _SqfliteMessageStore();
  }

  Uri _chatUri([String path = '']) {
    final suffix = path.isNotEmpty ? '/$path' : '';
    return Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatsEndpoint}$suffix');
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Chat API error ${response.statusCode}: ${response.body}');
  }

  /// All DIRECT conversations for the current user, newest activity first.
  Future<List<Chat>> getChats() async {
    final response = await _api.get(_chatUri());
    final body = _decode(response);
    final data = body['data'] as List<dynamic>? ?? const [];
    final chats = data
        .whereType<Map>()
        .map((item) => Chat.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    // Server metadata carries no content - enrich previews from local store.
    final enriched = <Chat>[];
    for (final chat in chats) {
      final localMsgs = await _listMessagesLocally(chat.id);
      Message? latest = localMsgs.isNotEmpty ? localMsgs.last : null;

      // If local store is empty, sync from server to populate local store
      if (latest == null) {
        final fetched = await getChatMessages(chat.id);
        if (fetched.isNotEmpty) {
          latest = fetched.last;
        }
      }

      if (latest != null && latest.content.isNotEmpty) {
        final lastActivity = latest.timestamp.isAfter(chat.lastActivity)
            ? latest.timestamp
            : chat.lastActivity;
        enriched.add(chat.copyWith(
          lastMessage: latest,
          lastActivity: lastActivity,
        ));
      } else {
        enriched.add(chat);
      }
    }
    enriched.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return enriched;
  }

  Future<Chat?> getChatById(String chatId) async {
    final all = await getChats();
    for (final c in all) {
      if (c.id == chatId) return c;
    }
    return null;
  }

  /// Create or fetch an existing 1-on-1 chat with another user.
  Future<Chat> startIndividualChat(String targetUserId) async {
    final response = await _api.post(_chatUri('direct/$targetUserId'));
    final body = _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return Chat.fromJson(data);
  }

  /// Get-or-create the DIRECT conversation with an accepted friend.
  Future<Chat> getOrCreateDirectChat(String friendId) => startIndividualChat(friendId);

  /// History for a chat: reconciles local device storage with server history.
  Future<List<Message>> getChatMessages(String chatId, {int page = 1}) async {
    final local = await _listMessagesLocally(chatId);

    try {
      final response =
          await _api.get(_chatUri('$chatId/messages?page=$page&limit=50'));
      final body = _decode(response);
      final data = body['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final metaList = data['messages'] as List<dynamic>? ?? const [];

      // 1. Parse server messages
      final List<Message> serverMessages = [];
      for (final raw in metaList.whereType<Map>()) {
        try {
          final sMsg = Message.fromJson(Map<String, dynamic>.from(raw));
          if (sMsg.id.isNotEmpty) {
            serverMessages.add(sMsg);
          }
        } catch (_) {}
      }

      // 2. Map existing local messages by ID for fast lookup
      final Map<String, Message> localById = {
        for (final m in local) m.id: m
      };

      // 3. Merge server and local messages
      final Map<String, Message> merged = {};

      for (final sMsg in serverMessages) {
        final localMsg = localById[sMsg.id];
        final effectiveContent = sMsg.content.isNotEmpty
            ? sMsg.content
            : (localMsg?.content ?? '');
        final effectiveMsg = sMsg.copyWith(
          content: effectiveContent,
          senderId: sMsg.senderId.isNotEmpty
              ? sMsg.senderId
              : (localMsg?.senderId ?? ''),
        );
        merged[effectiveMsg.id] = effectiveMsg;
        await _upsertMessageLocally(effectiveMsg);
      }

      // Keep any pending local messages (tmp_)
      for (final lMsg in local) {
        if (lMsg.id.startsWith('tmp_') && !merged.containsKey(lMsg.id)) {
          merged[lMsg.id] = lMsg;
        }
      }

      final result = merged.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return result;
    } catch (_) {
      return local;
    }
  }

  /// Send a text message.
  ///
  /// Saves optimistically on-device, delivers via the realtime socket and
  /// adopts the server-assigned id/timestamp from the ack. Falls back to
  /// REST when the socket is unavailable. Returns the final message or null.
  Future<Message?> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id') ?? '';

    final temp = Message(
      id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
      senderId: currentUserId,
      chatId: chatId,
      content: trimmed,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );
    await _upsertMessageLocally(temp);

    Map<String, dynamic>? savedMeta;
    final ack = await ChatSocketService.instance.sendMessage(chatId, trimmed);
    if (ack != null && ack['ok'] == true && ack['data'] is Map) {
      savedMeta = Map<String, dynamic>.from(ack['data'] as Map);
    }

    if (savedMeta == null) {
      try {
        final response = await _api.post(
          _chatUri('$chatId/messages'),
          body: json.encode({'content': trimmed}),
        );
        final body = _decode(response);
        savedMeta = body['data'] as Map<String, dynamic>?;
      } catch (_) {}
    }

    if (savedMeta == null || !savedMeta.containsKey('id')) {
      // Delivery failed entirely - keep the optimistic copy so the user can
      // retry/copy it, but signal failure upstream.
      return null;
    }

    final deliveredAtRaw = savedMeta['createdAt']?.toString();
    final serverSenderId = savedMeta['senderId']?.toString();
    final finalMsg = Message(
      id: savedMeta['id']?.toString() ?? temp.id,
      senderId: (serverSenderId != null && serverSenderId.isNotEmpty)
          ? serverSenderId
          : (currentUserId.isNotEmpty ? currentUserId : temp.senderId),
      chatId: chatId,
      content: trimmed,
      type: MessageType.text,
      timestamp: DateTime.tryParse(deliveredAtRaw ?? '') ?? temp.timestamp,
    );

    await _removeMessageLocally(temp.id, chatId);
    await _upsertMessageLocally(finalMsg);
    return finalMsg;
  }

  /// Persist an incoming realtime message on this device.
  Future<void> saveIncoming(Map<String, dynamic> payload) async {
    if (!payload.containsKey('id')) return;
    final msg = Message.fromJson(payload);
    if (msg.content.isEmpty) return;
    await _upsertMessageLocally(msg);
  }

  /// Mark all incoming messages of a conversation as read.
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      ChatSocketService.instance.markRead(chatId);
      await _api.post(_chatUri('$chatId/read'));
    } catch (_) {}
  }

  // ── local store helpers ─────────────────────────────────────────

  Future<Message?> _getMessageLocally(String chatId, String messageId) async {
    final store = _localStore;
    if (store is _WebStorageMessageStore) {
      return store.byId(chatId, messageId);
    }
    return (store as _SqfliteMessageStore).byId(chatId, messageId);
  }

  Future<List<Message>> _listMessagesLocally(String chatId) async {
    final store = _localStore;
    if (store is _WebStorageMessageStore) {
      return store.byChat(chatId);
    }
    return (store as _SqfliteMessageStore).byChat(chatId);
  }

  Future<void> _upsertMessageLocally(Message message) async {
    final store = _localStore;
    if (store is _WebStorageMessageStore) {
      await store.upsert(message);
    } else {
      await (store as _SqfliteMessageStore).upsert(message);
    }
  }

  Future<void> _removeMessageLocally(String messageId, String chatId) async {
    final store = _localStore;
    if (store is _WebStorageMessageStore) {
      await store.remove(messageId, chatId);
    } else {
      await (store as _SqfliteMessageStore).remove(messageId, chatId);
    }
  }
}
