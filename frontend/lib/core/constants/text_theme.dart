import 'package:flutter/material.dart';
import 'package:hosla/core/constants/theme_colors.dart';

class TextThemes {
  static const TextStyle title = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ThemeColors.textColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: ThemeColors.secondaryColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: ThemeColors.textColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: ThemeColors.textColor,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Quicksand',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ThemeColors.textColor,
  );

  // Context-aware text styles
  static TextStyle getTitleStyle(BuildContext context) {
    return title.copyWith(color: ThemeColors.getTextColor(context));
  }

  static TextStyle getBodySmallStyle(BuildContext context) {
    return bodySmall.copyWith(color: ThemeColors.getSecondaryTextColor(context));
  }

  static TextStyle getBodyMediumStyle(BuildContext context) {
    return bodyMedium.copyWith(color: ThemeColors.getTextColor(context));
  }

  static TextStyle getBodyLargeStyle(BuildContext context) {
    return bodyLarge.copyWith(color: ThemeColors.getTextColor(context));
  }

  static TextStyle getButtonStyle(BuildContext context) {
    return button.copyWith(color: Colors.black);
    //ThemeColors.getTextColor(context));
  }
}
