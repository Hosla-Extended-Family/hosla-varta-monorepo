import 'package:flutter/material.dart';
import 'package:hosla/core/constants/theme_colors.dart';

class TextThemes {
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: ThemeColors.secondaryColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: ThemeColors.textColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: ThemeColors.textColor,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ThemeColors.textColor,
  );
}
