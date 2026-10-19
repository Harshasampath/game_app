import 'package:flutter/material.dart';

class DiceThemeData {
  final String name;
  final Color dieColor;
  final Color dotColor;
  final Color backgroundColor;
  final Color accentColor;
  final Color? borderColor;
  final double borderRadius;
  final bool hasGlow;

  const DiceThemeData({
    required this.name,
    required this.dieColor,
    required this.dotColor,
    required this.backgroundColor,
    required this.accentColor,
    this.borderColor,
    this.borderRadius = 28.0,
    this.hasGlow = false,
  });

  DiceThemeData copyWith({
    String? name,
    Color? dieColor,
    Color? dotColor,
    Color? backgroundColor,
    Color? accentColor,
    Color? borderColor,
    double? borderRadius,
    bool? hasGlow,
  }) {
    return DiceThemeData(
      name: name ?? this.name,
      dieColor: dieColor ?? this.dieColor,
      dotColor: dotColor ?? this.dotColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      accentColor: accentColor ?? this.accentColor,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      hasGlow: hasGlow ?? this.hasGlow,
    );
  }

  static const List<DiceThemeData> presets = [
    DiceThemeData(
      name: 'Midnight Gold',
      dieColor: Color(0xFF1E222D),
      dotColor: Color(0xFFFFD166),
      backgroundColor: Color(0xFF0D0F14),
      accentColor: Color(0xFFFFD166),
      borderColor: Color(0x33FFD166),
      borderRadius: 32.0,
      hasGlow: true,
    ),
    DiceThemeData(
      name: 'Cyberpunk Neon',
      dieColor: Color(0xFF150A2A),
      dotColor: Color(0xFF00F0FF),
      backgroundColor: Color(0xFF090414),
      accentColor: Color(0xFFF72585),
      borderColor: Color(0x6600F0FF),
      borderRadius: 28.0,
      hasGlow: true,
    ),
    DiceThemeData(
      name: 'Classic Casino',
      dieColor: Color(0xFFD90429),
      dotColor: Color(0xFFFFFFFF),
      backgroundColor: Color(0xFF1B4332),
      accentColor: Color(0xFFFFB703),
      borderColor: Color(0x44FFFFFF),
      borderRadius: 30.0,
    ),
    DiceThemeData(
      name: 'Pure Obsidian',
      dieColor: Color(0xFF121212),
      dotColor: Color(0xFFFFFFFF),
      backgroundColor: Color(0xFF050505),
      accentColor: Color(0xFF90E0EF),
      borderColor: Color(0x33FFFFFF),
      borderRadius: 30.0,
    ),
    DiceThemeData(
      name: 'Crisp White',
      dieColor: Color(0xFFF8F9FA),
      dotColor: Color(0xFF212529),
      backgroundColor: Color(0xFF1B263B),
      accentColor: Color(0xFF38BDF8),
      borderColor: Color(0x22000000),
      borderRadius: 30.0,
    ),
    DiceThemeData(
      name: 'Spicy Fire',
      dieColor: Color(0xFFFF5722),
      dotColor: Color(0xFFFFEB3B),
      backgroundColor: Color(0xFF210902),
      accentColor: Color(0xFFFF9800),
      borderColor: Color(0x44FFEB3B),
      borderRadius: 30.0,
      hasGlow: true,
    ),
    DiceThemeData(
      name: 'Emerald Jade',
      dieColor: Color(0xFF104F36),
      dotColor: Color(0xFFE0AA3E),
      backgroundColor: Color(0xFF061A12),
      accentColor: Color(0xFF52B788),
      borderColor: Color(0x3352B788),
      borderRadius: 30.0,
    ),
    DiceThemeData(
      name: 'Pastel Bubblegum',
      dieColor: Color(0xFFFFB5A7),
      dotColor: Color(0xFF6B2D5C),
      backgroundColor: Color(0xFF2B2024),
      accentColor: Color(0xFFFCD5CE),
      borderColor: Color(0x33FFFFFF),
      borderRadius: 32.0,
    ),
  ];
}
