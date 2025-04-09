import 'package:flutter/material.dart';

class AppTheme {
  // App colors
  static const Color primaryColor = Color(0xFF1DB954);      // Vibrant green
  static const Color errorColor = Color(0xFFE53935);        // Red
  static const Color backgroundColor = Color(0xFF121212);   // Deep dark
  static const Color surfaceColor = Color(0xFF1E1E1E);      // Dark gray
  static const Color textColor = Color(0xFFFFFFFF);         // White
  
  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    primarySwatch: Colors.green,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
      onPrimary: textColor,
      onSecondary: textColor,
      onBackground: textColor,
      onSurface: textColor,
      onError: textColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: textColor),
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}