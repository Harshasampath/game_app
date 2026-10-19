import 'package:flutter/material.dart';

/// Bundled Orbitron styles (replaces runtime google_fonts downloads).
abstract final class AppTypography {
  static const _family = 'Orbitron';

  static TextStyle orbitron({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: _family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }
}
