import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../rendering/vfx_utils.dart';

class ExplosionComponent extends PositionComponent {
  ExplosionComponent({required Vector2 position, this.large = false})
      : super(position: position, anchor: Anchor.center) {
    _spawnParticles();
  }

  final bool large;
  double _elapsed = 0;
  final _particles = <_BurstParticle>[];
  final _random = Random();

  void _spawnParticles() {
    final count = large ? 28 : 14;
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = (large ? 120 : 70) + _random.nextDouble() * (large ? 180 : 100);
      _particles.add(_BurstParticle(
        velocity: Vector2(cos(angle), sin(angle)) * speed,
        size: (large ? 3 : 2) + _random.nextDouble() * (large ? 5 : 3),
        color: [
          const Color(0xFFFFD43B),
          const Color(0xFFFF922B),
          const Color(0xFFFF6B6B),
          const Color(0xFFFDE047),
        ][_random.nextInt(4)],
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    for (final p in _particles) {
      p.position += p.velocity * dt;
      p.velocity *= 0.92;
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
    if (_elapsed >= (large ? 0.85 : 0.55) && _particles.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final duration = large ? 0.85 : 0.55;
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final shockRadius = (large ? 20.0 : 10.0) + t * (large ? 64.0 : 36.0);

    VfxUtils.drawGlowCircle(
      canvas,
      Offset.zero,
      shockRadius * 0.6,
      const Color(0xFFFF922B),
      blur: large ? 20 : 12,
      opacity: (1 - t) * 0.7,
    );

    canvas.drawCircle(
      Offset.zero,
      shockRadius,
      Paint()
        ..color = Color.fromRGBO(255, 200, 80, (1 - t) * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 - t,
    );

    canvas.drawCircle(
      Offset.zero,
      shockRadius * 0.35 * (1 - t * 0.5),
      Paint()..color = Color.fromRGBO(255, 80, 40, (1 - t) * 0.9),
    );

    for (final p in _particles) {
      final alpha = (p.life / 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.position.toOffset(),
        p.size * alpha,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }
}

class _BurstParticle {
  _BurstParticle({required this.velocity, required this.size, required this.color});

  Vector2 position = Vector2.zero();
  Vector2 velocity;
  double size;
  double life = 0.4;
  final Color color;
}
