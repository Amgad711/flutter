import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryDark = Color(0xFF0060DF);
  static const Color primaryLight = Color(0xFF4DABF7);
  static const Color secondary = Color(0xFF30D158);
  static const Color accent = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFFD60A);
  static const Color success = Color(0xFF30D158);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF2F2F7);
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);

  static const Color sentBubble = Color(0xFF0A84FF);
  static const Color receivedBubble = Color(0xFFE9E9EB);
  static const Color sentBubbleText = Color(0xFFFFFFFF);
  static const Color receivedBubbleText = Color(0xFF1C1C1E);

  static const Color divider = Color(0xFFE5E5EA);
  static const Color inputBackground = Color(0xFFF2F2F7);
  static const Color onlineGreen = Color(0xFF30D158);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 16),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
        indent: 72,
      ),
    );
  }
}
