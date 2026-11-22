import 'package:flutter/material.dart';

class ThemeColors {
  // Primary colors (consistent across themes)
  static const Color primaryColor = Color(0xFF12EBC7);
  static const Color secondaryColor = Color(0xFF618A82);

  // Light theme colors
  static const Color lightBackgroundColor = Color(0xFFFAFAFA);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightTextColor = Color(0xFF1A1A1A);
  static const Color lightSecondaryTextColor = Color(0xFF757575);
  static const Color lightNavBarColor = Color(0xFFFFFFFF);
  static const Color lightNavBarIconColor = Color(0xFF424242);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightBorderColor = Color(0xFFE0E0E0);

  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF0A0A0A);
  static const Color darkSurfaceColor = Color(0xFF1C1C1E);
  static const Color darkTextColor = Color(0xFFFFFFFF);
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
  static const Color darkNavBarColor = Color(0xFF1C1C1E);
  static const Color darkNavBarIconColor = Color(0xFFE0E0E0);
  static const Color darkCardColor = Color(0xFF2C2C2E);
  static const Color darkBorderColor = Color(0xFF48484A);

  // Additional semantic colors for better UI
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color successColor = Color(0xFF30D158);
  static const Color infoColor = Color(0xFF007AFF);

  // Light semantic surface colors
  static const Color lightErrorSurface = Color(0xFFFFEBEE);
  static const Color lightWarningSurface = Color(0xFFFFF3E0);
  static const Color lightSuccessSurface = Color(0xFFE8F5E8);
  static const Color lightInfoSurface = Color(0xFFE3F2FD);

  // Dark semantic surface colors
  static const Color darkErrorSurface = Color(0xFF3E2723);
  static const Color darkWarningSurface = Color(0xFF3E2E00);
  static const Color darkSuccessSurface = Color(0xFF1B3B1B);
  static const Color darkInfoSurface = Color(0xFF0D47A1);

  // Legacy getters for backward compatibility (will be updated to use context-aware colors)
  static const Color backgroundColor = lightBackgroundColor;
  static const Color textColor = lightTextColor;
  static const Color navBarColor = lightNavBarColor;
  static const Color navBarIconColor = lightNavBarIconColor;

  // Context-aware color getters
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackgroundColor
        : lightBackgroundColor;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceColor
        : lightSurfaceColor;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextColor
        : lightTextColor;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSecondaryTextColor
        : lightSecondaryTextColor;
  }

  static Color getNavBarColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkNavBarColor
        : lightNavBarColor;
  }

  static Color getNavBarIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkNavBarIconColor
        : lightNavBarIconColor;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardColor
        : lightCardColor;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorderColor
        : lightBorderColor;
  }

  // Semantic color getters
  static Color getErrorColor(BuildContext context) => errorColor;

  static Color getWarningColor(BuildContext context) => warningColor;

  static Color getSuccessColor(BuildContext context) => successColor;

  static Color getInfoColor(BuildContext context) => infoColor;

  static Color getErrorSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkErrorSurface
        : lightErrorSurface;
  }

  static Color getWarningSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkWarningSurface
        : lightWarningSurface;
  }

  static Color getSuccessSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSuccessSurface
        : lightSuccessSurface;
  }

  static Color getInfoSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkInfoSurface
        : lightInfoSurface;
  }

  // Modern overlay colors for better UI feedback
  static Color getOverlayColor(BuildContext context, {double opacity = 0.1}) {
    return getTextColor(context).withValues(alpha: opacity);
  }

  static Color getDisabledColor(BuildContext context) {
    return getSecondaryTextColor(context).withValues(alpha: 0.6);
  }
}
