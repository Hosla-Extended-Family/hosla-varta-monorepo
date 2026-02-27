import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/pages/home/create_event_page.dart';

/// A reusable rectangular Floating Action Button for creating events.
///
/// Mirrors the [CreatePostFab] design: extended FAB with rounded-rectangle
/// shape, teal background, black text, and a subtle press animation.
class CreateEventFab extends StatelessWidget {
  const CreateEventFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FloatingActionButton.extended(
        heroTag: 'create_event_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventPage()),
          );
        },
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
        highlightElevation: 8,
        splashColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.event_note_rounded, size: 20),
        label: Text(
          'Create Event',
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
