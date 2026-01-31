import 'package:flutter/material.dart';
import 'package:hosla/core/constants/theme_colors.dart';

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: _createMaterialColor(ThemeColors.primaryColor),
    primaryColor: ThemeColors.primaryColor,
    scaffoldBackgroundColor: ThemeColors.lightBackgroundColor,
    cardColor: ThemeColors.lightCardColor,
    dividerColor: ThemeColors.lightBorderColor,
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: ThemeColors.lightSurfaceColor,
      foregroundColor: ThemeColors.lightTextColor,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: ThemeColors.lightBorderColor,
      titleTextStyle: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ThemeColors.lightTextColor,
      ),
      iconTheme: IconThemeData(color: ThemeColors.lightTextColor),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ThemeColors.lightNavBarColor,
      selectedItemColor: ThemeColors.primaryColor,
      unselectedItemColor: ThemeColors.lightNavBarIconColor,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: ThemeColors.lightCardColor,
      elevation: 4,
      shadowColor: ThemeColors.lightBorderColor.withValues(alpha: 0.5),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: ThemeColors.lightTextColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ThemeColors.lightTextColor,
        letterSpacing: -0.25,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: ThemeColors.lightTextColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: ThemeColors.lightSecondaryTextColor,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: ThemeColors.lightSecondaryTextColor,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ThemeColors.lightTextColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ThemeColors.lightTextColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ThemeColors.lightTextColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: ThemeColors.lightTextColor,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ThemeColors.lightSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ThemeColors.lightBorderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ThemeColors.lightBorderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ThemeColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ThemeColors.errorColor, width: 1.5),
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ThemeColors.lightSecondaryTextColor,
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: ThemeColors.lightTextColor,
        elevation: 4,
        shadowColor: ThemeColors.primaryColor.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ThemeColors.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ThemeColors.primaryColor,
      foregroundColor: ThemeColors.lightTextColor,
      elevation: 8,
      shape: CircleBorder(),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: ThemeColors.lightTextColor,
    ),
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: ThemeColors.primaryColor,
      secondary: ThemeColors.secondaryColor,
      surface: ThemeColors.lightSurfaceColor,
      onPrimary: ThemeColors.lightTextColor,
      onSecondary: ThemeColors.lightTextColor,
      onSurface: ThemeColors.lightTextColor,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: _createMaterialColor(ThemeColors.primaryColor),
    primaryColor: ThemeColors.primaryColor,
    scaffoldBackgroundColor: ThemeColors.darkBackgroundColor,
    cardColor: ThemeColors.darkCardColor,
    dividerColor: ThemeColors.darkBorderColor,
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: ThemeColors.darkSurfaceColor,
      foregroundColor: ThemeColors.darkTextColor,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: ThemeColors.darkBorderColor,
      titleTextStyle: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ThemeColors.darkTextColor,
      ),
      iconTheme: IconThemeData(color: ThemeColors.darkTextColor),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ThemeColors.darkNavBarColor,
      selectedItemColor: ThemeColors.primaryColor,
      unselectedItemColor: ThemeColors.darkNavBarIconColor,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: ThemeColors.darkCardColor,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: ThemeColors.darkTextColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ThemeColors.darkTextColor,
        letterSpacing: -0.25,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: ThemeColors.darkTextColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: ThemeColors.darkSecondaryTextColor,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: ThemeColors.darkSecondaryTextColor,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ThemeColors.darkTextColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ThemeColors.darkTextColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ThemeColors.darkTextColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: ThemeColors.darkTextColor,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ThemeColors.darkSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ThemeColors.darkBorderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ThemeColors.darkBorderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ThemeColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ThemeColors.errorColor, width: 1.5),
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ThemeColors.darkSecondaryTextColor,
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: ThemeColors.darkTextColor,
        elevation: 6,
        shadowColor: ThemeColors.primaryColor.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ThemeColors.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ThemeColors.primaryColor,
      foregroundColor: ThemeColors.darkTextColor,
      elevation: 12,
      shape: CircleBorder(),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: ThemeColors.darkTextColor,
    ),
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: ThemeColors.primaryColor,
      secondary: ThemeColors.secondaryColor,
      surface: ThemeColors.darkSurfaceColor,
      onPrimary: ThemeColors.darkTextColor,
      onSecondary: ThemeColors.darkTextColor,
      onSurface: ThemeColors.darkTextColor,
    ),
  );

  // Helper method to create MaterialColor from Color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = <int, Color>{};
    final int r = (color.r * 255).round(), g = (color.g * 255).round(), b = (color.b * 255).round();

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
