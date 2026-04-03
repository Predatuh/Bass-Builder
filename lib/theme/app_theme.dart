import 'package:flutter/material.dart';

class AppTheme {
  static const _teal = Color(0xFF0D9488);
  static const _darkBg = Color(0xFF0F172A);
  static const _darkSurface = Color(0xFF1E293B);
  static const _darkBorder = Color(0xFF334155);

  // Legacy alias so existing code referencing AppTheme.theme still compiles
  static ThemeData get theme => light;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _teal,
      brightness: Brightness.light,
      primary: _teal,
      secondary: const Color(0xFFF97316),
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: _textTheme(const Color(0xFF0F172A)),
      cardTheme: _cardTheme(Colors.white, const Color(0xFFE2E8F0)),
      inputDecorationTheme: _inputTheme(
        fill: const Color(0xFFF1F5F9),
        border: const Color(0xFFCBD5E1),
        focus: _teal,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _teal,
      brightness: Brightness.dark,
      primary: _teal,
      secondary: const Color(0xFFFB923C),
      surface: _darkSurface,
      onSurface: const Color(0xFFE2E8F0),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBg,
      textTheme: _textTheme(const Color(0xFFE2E8F0)),
      cardTheme: _cardTheme(_darkSurface, _darkBorder),
      inputDecorationTheme: _inputTheme(
        fill: const Color(0xFF0F172A),
        border: _darkBorder,
        focus: _teal,
      ),
    );
  }

  static TextTheme _textTheme(Color ink) => TextTheme(
        headlineMedium: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: ink, fontSize: 14),
        bodySmall: TextStyle(color: ink.withValues(alpha: 0.7), fontSize: 12),
        labelSmall: TextStyle(color: ink.withValues(alpha: 0.55), fontSize: 10),
      );

  static CardThemeData _cardTheme(Color bg, Color border) => CardThemeData(
        color: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      );

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color focus,
  }) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: focus, width: 1.5),
        ),
      );
}
