import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';

class Button extends StatelessWidget {
  final String text;
  final void Function()? onPressed;
  const Button({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.primaryColor,
          foregroundColor: Colors.black,
          disabledBackgroundColor: ThemeColors.primaryColor.withValues(
            alpha: 0.5,
          ),
          disabledForegroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        ),
        child: Text(text, style: TextThemes.getButtonStyle(context)),
      ),
    );
  }
}
