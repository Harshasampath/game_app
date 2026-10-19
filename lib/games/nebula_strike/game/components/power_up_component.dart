import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../core/constants/game_constants.dart';
import '../../domain/entities/game_session.dart';
import '../rendering/vfx_utils.dart';

typedef PowerUpCallback = void Function(PowerUpType type);

class PowerUpComponent extends PositionComponent with CollisionCallbacks {
  PowerUpComponent({
    required Vector2 position,
    required this.type,
    required this.worldScroll,
    this.onCollected,
  }) : super(
          position: position,
          size: Vector2.all(GameConstants.powerUpSize + 8),
          anchor: Anchor.center,
        );

  final PowerUpType type;
  final double worldScroll;
  final PowerUpCallback? onCollected;
  double _pulse = 0;
  double _orbit = 0;

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: GameConstants.powerUpSize * 0.45));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= worldScroll * dt;
    _pulse += dt * 4;
    _orbit += dt * 2.5;
  }

  Color get _coreColor => switch (type) {
        PowerUpType.rapidFire => const Color(0xFFFF922B),
        PowerUpType.spreadShot => const Color(0xFFC084FC),
        PowerUpType.shield => const Color(0xFF4ADE80),
      };

  @override
  void render(Canvas canvas) {
    final scale = 1 + sin(_pulse) * 0.08;
    final r = size.x * 0.38 * scale;

    VfxUtils.drawGlowCircle(canvas, Offset.zero, r * 1.8, _coreColor, blur: 14, opacity: 0.45);

    _drawHexRing(canvas, r * 1.35, _coreColor.withValues(alpha: 0.7), 2);
    _drawHexRing(canvas, r * 1.1, _coreColor, 2.5);

    canvas.drawCircle(
      Offset.zero,
      r * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [_coreColor, _coreColor.withValues(alpha: 0.4), const Color(0xFF0F172A)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 0.55)),
    );

    final icon = switch (type) {
      PowerUpType.rapidFire => '⚡',
      PowerUpType.spreadShot => '✦',
      PowerUpType.shield => '◆',
    };

    final tp = TextPainter(
      text: TextSpan(
        text: icon,
        style: TextStyle(color: const Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    for (var i = 0; i < 3; i++) {
      final angle = _orbit + i * (pi * 2 / 3);
      final dot = Offset(cos(angle) * r * 1.5, sin(angle) * r * 1.5);
      canvas.drawCircle(dot, 2, Paint()..color = _coreColor.withValues(alpha: 0.8));
    }
  }

  void _drawHexRing(Canvas canvas, double radius, Color color, double stroke) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = pi / 6 + i * pi / 3 + _orbit * 0.3;
      final point = Offset(cos(angle) * radius, sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }
}