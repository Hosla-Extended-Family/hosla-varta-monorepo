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
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: ThemeColors.lightCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ThemeColors.lightTextColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: ThemeColors.lightTextColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: ThemeColors.lightSecondaryTextColor,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ThemeColors.lightSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeColors.lightBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeColors.lightBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeColors.primaryColor),
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: ThemeColors.lightTextColor,
        elevation: 2,
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
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: ThemeColors.darkCardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ThemeColors.darkTextColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: ThemeColors.darkTextColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Quicksand',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: ThemeColors.darkSecondaryTextColor,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ThemeColors.darkSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeColors.darkBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeColors.darkBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeColors.primaryColor),
      ),
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeColors.primaryColor,
        foregroundColor: ThemeColors.darkTextColor,
        elevation: 2,
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
