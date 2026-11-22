import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/pages/home/create_post_page.dart';

/// A reusable rectangular Floating Action Button for creating posts.
///
/// Uses rounded-rectangle shape with the primary teal colour, black text,
/// and a subtle press animation. Designed to sit in the bottom-right of
/// Feed / Events pages without overlapping important content.
class CreatePostFab extends StatelessWidget {
  const CreatePostFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FloatingActionButton.extended(
        heroTag: 'create_post_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          );
        },
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
        highlightElevation: 8,
        splashColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: Text(
          'Create Post',
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
