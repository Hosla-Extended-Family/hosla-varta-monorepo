import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/models/chat_model.dart';
import 'package:hosla/pages/chat_detail_page.dart';
import 'package:hosla/providers/chat_provider.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/services/chat_socket_service.dart';
import 'package:hosla/widgets/profile_pic.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class InAppNotificationHost extends ConsumerStatefulWidget {
  final Widget child;
  const InAppNotificationHost({super.key, required this.child});

  @override
  ConsumerState<InAppNotificationHost> createState() =>
      _InAppNotificationHostState();
}

class _NotificationData {
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? avatarUrl;
  final String messageText;
  final DateTime timestamp;

  _NotificationData({
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.avatarUrl,
    required this.messageText,
    required this.timestamp,
  });
}

class _InAppNotificationHostState extends ConsumerState<InAppNotificationHost>
    with SingleTickerProviderStateMixin {
  StreamSubscription? _msgSub;
  _NotificationData? _activeNotification;
  Timer? _autoDismissTimer;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _listenForIncomingMessages();
  }

  void _listenForIncomingMessages() {
    _msgSub = ChatSocketService.instance.messages.listen((msg) async {
      final conversationId = msg['conversationId']?.toString() ?? '';
      final senderId = msg['senderId']?.toString() ?? '';
      final content = msg['content']?.toString() ?? '';

      if (conversationId.isEmpty || content.trim().isEmpty) return;

      final currentUserId = ref.read(currentUserProfileProvider)?.id ?? '';
      if (senderId.isNotEmpty && senderId == currentUserId) return;

      // Don't show notification if user is currently looking at this specific chat
      final currentChatId = ref.read(activeChatIdProvider);
      if (currentChatId == conversationId) return;

      // Resolve sender name from chat list or chat service
      String senderName = 'New Message';
      String? avatarUrl;

      final chats = ref.read(chatsProvider).value ?? [];
      final found = chats.where((c) => c.id == conversationId).firstOrNull;
      if (found != null) {
        senderName = found.name;
        avatarUrl = found.avatarUrl;
      }

      if (mounted) {
        _showNotification(
          _NotificationData(
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            avatarUrl: avatarUrl,
            messageText: content,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  void _showNotification(_NotificationData data) {
    _autoDismissTimer?.cancel();
    setState(() {
      _activeNotification = data;
    });
    _animController.forward(from: 0.0);

    _autoDismissTimer = Timer(const Duration(seconds: 4), () {
      _dismissNotification();
    });
  }

  void _dismissNotification() {
    _autoDismissTimer?.cancel();
    if (_activeNotification == null) return;
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeNotification = null;
        });
      }
    });
  }

  Future<void> _openChat(_NotificationData data) async {
    _dismissNotification();
    final service = ref.read(chatServiceProvider);
    Chat? targetChat = await service.getChatById(data.conversationId);

    targetChat ??= Chat(
      id: data.conversationId,
      name: data.senderName,
      avatarUrl: data.avatarUrl,
      type: ChatType.individual,
      participantIds: [data.senderId],
      lastActivity: data.timestamp,
      unreadCount: 0,
      isMuted: false,
    );

    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => ChatDetailPage(chat: targetChat!)),
    );
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        if (_activeNotification != null)
          Positioned(
            top: topPadding + 10,
            left: 14,
            right: 14,
            child: SlideTransition(
              position: _offsetAnimation,
              child: GestureDetector(
                onTap: () => _openChat(_activeNotification!),
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! < -4) {
                    _dismissNotification();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E24).withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: ThemeColors.primaryColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeColors.primaryColor.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            ProfilePic(
                              radius: 20,
                              imageUrl: _activeNotification!.avatarUrl ?? '',
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: ThemeColors.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF1E1E24)
                                        : Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _activeNotification!.senderName,
                                      style: TextThemes.getBodyMediumStyle(context)
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'now',
                                    style: TextThemes.getBodySmallStyle(context)
                                        .copyWith(
                                          color: ThemeColors.primaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _activeNotification!.messageText,
                                style: TextThemes.getBodySmallStyle(context).copyWith(
                                  color: ThemeColors.getSecondaryTextColor(context),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Close / Action icon
                        GestureDetector(
                          onTap: _dismissNotification,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: ThemeColors.getSecondaryTextColor(context)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: ThemeColors.getSecondaryTextColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
