import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';

/// Shared drawing helpers for glow, gradients, and sci-fi VFX.
class VfxUtils {
  VfxUtils._();

  static void drawGlowCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double blur = 12,
    double opacity = 1,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  static void drawGlowPath(
    Canvas canvas,
    Path path,
    Color color, {
    double blur = 8,
    double opacity = 0.85,
    PaintingStyle style = PaintingStyle.fill,
    double strokeWidth = 1,
  }) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = style
        ..strokeWidth = strokeWidth
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  static void fillPathGradient(
    Canvas canvas,
    Path path,
    List<Color> colors, {
    Alignment begin = Alignment.centerLeft,
    Alignment end = Alignment.centerRight,
  }) {
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ).createShader(bounds),
    );
  }

  static void strokePath(
    Canvas canvas,
    Path path,
    Color color, {
    double width = 1,
    double opacity = 0.6,
  }) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  static Path irregularRock(double cx, double cy, double radius, int seed) {
    final r = Random(seed);
    final path = Path();
    final points = 7 + r.nextInt(4);
    for (var i = 0; i < points; i++) {
      final angle = (i / points) * pi * 2;
      final dist = radius * (0.65 + r.nextDouble() * 0.45);
      final x = cx + cos(angle) * dist;
      final y = cy + sin(angle) * dist;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static void drawVignette(Canvas canvas, Size size, {double strength = 0.55}) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            const Color(0x00000000),
            Color.fromRGBO(0, 0, 0, strength),
          ],
          stops: const [0.45, 1.0],
        ).createShader(rect),
    );
  }

  static void drawScanlines(Canvas canvas, Size size, {double opacity = 0.04}) {
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
}
