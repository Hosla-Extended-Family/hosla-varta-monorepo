import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';

/// A reusable rectangular Floating Action Button for starting new chats.
///
/// Identical design to [CreatePostFab] and [CreateEventFab]:
/// extended FAB with rounded-rectangle shape, teal background, black text,
/// and a subtle press animation for visual consistency across the app.
class NewChatFab extends StatelessWidget {
  final VoidCallback onPressed;
  const NewChatFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FloatingActionButton.extended(
        heroTag: 'new_chat_fab',
        onPressed: onPressed,
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
        highlightElevation: 8,
        splashColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.edit_note_rounded, size: 20),
        label: Text(
          'New Chat',
          style: TextThemes.getButtonStyle(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
