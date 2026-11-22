import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

import 'package:hosla/core/constants/api_constants.dart';

/// Realtime chat connection to the backend via Socket.IO.
///
/// Events (server -> client):
///   connected                 { userId }
///   presence:update           { userId, isOnline }
///   chat:new_message          { id, conversationId, senderId, content, createdAt }
///   chat:typing               { conversationId, userId, isTyping }
///   chat:read_receipt         { conversationId, userId, readAt }
///   chat:refresh_conversations{ conversationId }
///
/// Events (client -> server):
///   chat:join     { conversationId }                     (ack)
///   chat:send     { conversationId, content }            (ack: { ok, data | error })
///   chat:typing   { conversationId, isTyping }
///   chat:read     { conversationId }
class ChatSocketService {
  ChatSocketService._();
  static final ChatSocketService instance = ChatSocketService._();

  sio.Socket? _socket;
  bool _connecting = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _refreshController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get typing => _typingController.stream;
  Stream<Map<String, dynamic>> get readReceipts => _readController.stream;
  Stream<Map<String, dynamic>> get conversationRefresh => _refreshController.stream;
  Stream<Map<String, dynamic>> get presenceUpdates => _presenceController.stream;
  Stream<bool> get connectionState => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  String? _lastToken;

  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        _connecting = false;
        return;
      }

      if (isConnected && _lastToken == token) return;
      if (_connecting) return;
      _connecting = true;

      _socket?.disconnect();
      _socket?.dispose();

      _lastToken = token;
      final socket = sio.io(
        ApiConstants.socketUrl,
        sio.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      socket.onConnect((_) {
        _connecting = false;
        _connectionController.add(true);
      });

      socket.onDisconnect((_) {
        _connectionController.add(false);
      });

      socket.onConnectError((data) {
        _connecting = false;
        _connectionController.add(false);
      });

      socket.on('presence:update', (data) {
        if (data is Map) {
          _presenceController.add(Map<String, dynamic>.from(data));
        }
      });

      socket.on('chat:new_message', (data) {
        if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
        }
      });

      socket.on('chat:typing', (data) {
        if (data is Map) {
          _typingController.add(Map<String, dynamic>.from(data));
        }
      });

      socket.on('chat:read_receipt', (data) {
        if (data is Map) {
          _readController.add(Map<String, dynamic>.from(data));
        }
      });

      socket.on('chat:refresh_conversations', (data) {
        if (data is Map) {
          _refreshController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket = socket;
    } catch (_) {
      _connecting = false;
    }
  }

  void joinChat(String conversationId) {
    _socket?.emit('chat:join', {'conversationId': conversationId});
  }

  /// Sends a message and completes with the ack response.
  Future<Map<String, dynamic>?> sendMessage(String conversationId, String content) {
    final socket = _socket;
    if (socket == null || !socket.connected) return Future.value(null);

    final completer = Completer<Map<String, dynamic>?>();
    socket.emitWithAck(
      'chat:send',
      {'conversationId': conversationId, 'content': content},
      ack: (data) {
        if (!completer.isCompleted) {
          completer.complete(
            data is Map ? Map<String, dynamic>.from(data) : null,
          );
        }
      },
    );
    return completer.future.timeout(const Duration(seconds: 2), onTimeout: () => null);
  }

  void sendTyping(String conversationId, bool isTyping) {
    if (!isConnected) return;
    _socket?.emit('chat:typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  void markRead(String conversationId) {
    if (!isConnected) return;
    _socket?.emit('chat:read', {'conversationId': conversationId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connecting = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _readController.close();
    _refreshController.close();
    _connectionController.close();
  }
}
