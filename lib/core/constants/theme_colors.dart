import 'package:flutter/material.dart';

class ThemeColors {
  // Primary colors (consistent across themes)
  static const Color primaryColor = Color(0xFF12EBC7);
  static const Color secondaryColor = Color(0xFF618A82);
  
  // Light theme colors
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightTextColor = Color(0xFF000000);
  static const Color lightSecondaryTextColor = Color(0xFF666666);
  static const Color lightNavBarColor = Color(0xFFFFFFFF);
  static const Color lightNavBarIconColor = Color(0xFF000000);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightBorderColor = Color(0xFFE0E0E0);
  
  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFFFFFFF);
  static const Color darkSecondaryTextColor = Color(0xFFB3B3B3);
  static const Color darkNavBarColor = Color(0xFF1E1E1E);
  static const Color darkNavBarIconColor = Color(0xFFFFFFFF);
  static const Color darkCardColor = Color(0xFF2C2C2C);
  static const Color darkBorderColor = Color(0xFF404040);

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
}