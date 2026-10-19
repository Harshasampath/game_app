import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../rendering/vfx_utils.dart';
import 'player_ship_component.dart';

class EngineTrailComponent extends Component {
  EngineTrailComponent({required this.target});

  final PlayerShipComponent target;
  final _particles = <_PlasmaParticle>[];
  final _random = Random();

  @override
  void update(double dt) {
    final spawnRate = target.isMoving ? 0.85 : 0.35;
    if (_random.nextDouble() < spawnRate) {
      final offset = target.exhaustOffset;
      _particles.add(_PlasmaParticle(
        position: target.position + offset +
            Vector2(-6 + _random.nextDouble() * 6, _random.nextDouble() * 8 - 4),
        velocity: Vector2(-(160 + _random.nextDouble() * 80), _random.nextDouble() * 40 - 20),
        size: 3 + _random.nextDouble() * 4,
        hue: _random.nextDouble() < 0.7 ? const Color(0xFF22D3EE) : const Color(0xFFF97316),
      ));
    }

    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life -= dt;
      p.position += p.velocity * dt;
      p.velocity *= 0.96;
      p.size *= 0.98;
      if (p.life <= 0) _particles.removeAt(i);
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final alpha = (p.life / 0.45).clamp(0.0, 1.0);
      VfxUtils.drawGlowCircle(
        canvas,
        p.position.toOffset(),
        p.size * 1.8,
        p.hue,
        blur: 6,
        opacity: alpha * 0.5,
      );
      canvas.drawCircle(
        p.position.toOffset(),
        p.size,
        Paint()..color = p.hue.withValues(alpha: alpha * 0.9),
      );
    }
  }
}

class _PlasmaParticle {
  _PlasmaParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.hue,
  });

  Vector2 position;
  Vector2 velocity;
  double size;
  double life = 0.45;
  final Color hue;
}
