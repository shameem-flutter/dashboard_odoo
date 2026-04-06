import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF3F4F6); // Muted gray
  static const Color lightCardColor = Color(0xFFFFFFFF); // Solid white
  static const Color lightPrimaryText = Color(0xFF111827); // Near black
  static const Color lightSecondaryText = Color(0xFF4B5563); // Dark gray
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A); // Deep navy/slate
  static const Color darkCardColor = Color(0xFF1E293B); // Dark slate
  static const Color darkPrimaryText = Color(0xFFF9FAFB); // Off-white
  static const Color darkSecondaryText = Color(0xFF94A3B8); // Slate gray

  // Common Accent Colors
  static const Color primaryBlue = Color(0xFF2563EB); // Buttons, accents
  static const Color successGreen = Color(0xFF16A34A); // Excel buttons, growth
  static const Color dangerRed = Color(0xFFEF4444); // Reset button, returns

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: primaryBlue,
    cardColor: lightCardColor,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightPrimaryText),
      bodyMedium: TextStyle(color: lightSecondaryText),
      titleLarge: TextStyle(color: lightPrimaryText, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: lightSecondaryText, fontWeight: FontWeight.w600),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      surface: lightCardColor,
      error: dangerRed,
    ),
    iconTheme: const IconThemeData(color: lightPrimaryText),
    cardTheme: CardThemeData(
      color: lightCardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryBlue,
    cardColor: darkCardColor,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkPrimaryText),
      bodyMedium: TextStyle(color: darkSecondaryText),
      titleLarge: TextStyle(color: darkPrimaryText, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: darkSecondaryText, fontWeight: FontWeight.w600),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      surface: darkCardColor,
      error: dangerRed,
    ),
    iconTheme: const IconThemeData(color: darkPrimaryText),
    cardTheme: CardThemeData(
      color: darkCardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
