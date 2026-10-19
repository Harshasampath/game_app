import 'package:flutter/material.dart';
import '../models/dice_theme.dart';

class DiceWidget extends StatelessWidget {
  final int value;
  final DiceThemeData theme;
  final double size;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double elevation;

  const DiceWidget({
    super.key,
    required this.value,
    required this.theme,
    this.size = 280.0,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.rotationZ = 0.0,
    this.elevation = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = value.clamp(1, 6);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012) // 3D perspective
        ..rotateX(rotationX)
        ..rotateY(rotationY)
        ..rotateZ(rotationZ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.dieColor,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(
            color: theme.borderColor ?? Colors.white.withValues(alpha: 0.15),
            width: 2.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.dieColor.withValues(alpha: 1.0),
              Color.alphaBlend(Colors.black.withValues(alpha: 0.25), theme.dieColor),
            ],
          ),
          boxShadow: [
            // Ambient soft shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: elevation * 1.5,
              offset: Offset(0, elevation * 0.8),
              spreadRadius: 2,
            ),
            // Bevel highlight
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(-2, -2),
            ),
            if (theme.hasGlow)
              BoxShadow(
                color: theme.dotColor.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 4,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.borderRadius),
          child: Stack(
            children: [
              // Subtle corner light sheen
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size * 0.45,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Dots Canvas
              CustomPaint(
                size: Size(size, size),
                painter: _DiceDotsPainter(
                  value: validValue,
                  dotColor: theme.dotColor,
                  hasGlow: theme.hasGlow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiceDotsPainter extends CustomPainter {
  final int value;
  final Color dotColor;
  final bool hasGlow;

  const _DiceDotsPainter({
    required this.value,
    required this.dotColor,
    required this.hasGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotRadius = size.width * 0.088; // Scaled dot size
    final w = size.width;
    final h = size.height;

    final left = w * 0.26;
    final right = w * 0.74;
    final centerW = w * 0.5;

    final top = h * 0.26;
    final bottom = h * 0.74;
    final centerH = h * 0.5;

    final List<Offset> points = [];

    switch (value) {
      case 1:
        points.add(Offset(centerW, centerH));
        break;
      case 2:
        points.add(Offset(left, top));
        points.add(Offset(right, bottom));
        break;
      case 3:
        points.add(Offset(left, top));
        points.add(Offset(centerW, centerH));
        points.add(Offset(right, bottom));
        break;
      case 4:
        points.add(Offset(left, top));
        points.add(Offset(right, top));
        points.add(Offset(left, bottom));
        points.add(Offset(right, bottom));
        break;
      case 5:
        points.add(Offset(left, top));
        points.add(Offset(right, top));
        points.add(Offset(centerW, centerH));
        points.add(Offset(left, bottom));
        points.add(Offset(right, bottom));
        break;
      case 6:
        points.add(Offset(left, top));
        points.add(Offset(right, top));
        points.add(Offset(left, centerH));
        points.add(Offset(right, centerH));
        points.add(Offset(left, bottom));
        points.add(Offset(right, bottom));
        break;
    }

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final insetShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotRadius * 0.22;

    final innerHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      if (hasGlow) {
        final glowPaint = Paint()
          ..color = dotColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawCircle(pt, dotRadius * 1.3, glowPaint);
      }

      // Base dot
      canvas.drawCircle(pt, dotRadius, dotPaint);

      // Inset bevel shadow
      canvas.drawCircle(pt, dotRadius * 0.88, insetShadowPaint);

      // Small top-left glint reflection
      canvas.drawCircle(
        Offset(pt.dx - dotRadius * 0.28, pt.dy - dotRadius * 0.28),
        dotRadius * 0.28,
        innerHighlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiceDotsPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.hasGlow != hasGlow;
  }
}
