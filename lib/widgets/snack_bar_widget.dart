import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/theme_colors.dart';

class SnackBarWidget {
  static void show(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextThemes.getBodySmallStyle(context).copyWith(
            color: isDark ? ThemeColors.darkTextColor : ThemeColors.lightTextColor,
          ),
        ),
        backgroundColor: isDark ? ThemeColors.darkCardColor : ThemeColors.lightCardColor,
        elevation: 10,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
