import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD43B),
          brightness: Brightness.dark,
          surface: const Color(0xFF12182B),
        ),
        scaffoldBackgroundColor: const Color(0xFF12182B),
        cardColor: const Color(0xFF1E2740),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12182B),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4C6EF5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
