import 'package:flutter/material.dart';

abstract final class Brand {
  static const navy = Color(0xFF1D3E82);
  static const amber = Color(0xFFF6A623);
  static const canvas = Color(0xFFF4F6FA);
  static const ink = Color(0xFF0F2148);
  static const muted = Color(0xFF5C6B8A);
  static const line = Color(0xFFDCE2EE);
  static const space = 16.0;
  static const radius = 8.0;
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: amber,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: ink,
      toolbarHeight: 64,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: muted),
      bodyLarge: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: ink,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.6,
        color: muted,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: line),
        foregroundColor: navy,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedColor: const Color(0xFFE8ECF7),
      side: const BorderSide(color: line),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: navy, width: 2),
      ),
      labelStyle: const TextStyle(color: muted, fontSize: 12),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFE8ECF7),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
