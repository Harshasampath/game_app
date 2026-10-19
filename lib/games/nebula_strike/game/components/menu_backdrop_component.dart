import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../rendering/vfx_utils.dart';

/// Slow nebula starfield for hangar / mission-select scenes.
class MenuBackdropComponent extends Component {
  MenuBackdropComponent({required Vector2 viewportSize}) : viewportSize = viewportSize.clone();

  Vector2 viewportSize;
  double _elapsed = 0;
  final _random = Random(7);
  late final List<_MenuStar> _stars;
  late final List<_MenuNebula> _nebulae;

  @override
  Future<void> onLoad() async {
    _stars = List.generate(90, (_) => _spawnStar());
    _nebulae = List.generate(6, (i) => _MenuNebula(
          x: _random.nextDouble() * viewportSize.x,
          y: _random.nextDouble() * viewportSize.y,
          radius: 120 + _random.nextDouble() * 180,
          hue: [0xFF5C2D91, 0xFF1E3A8A, 0xFF0E7490][i % 3],
          drift: 8 + _random.nextDouble() * 14,
        ));
  }

  _MenuStar _spawnStar() => _MenuStar(
        x: _random.nextDouble() * viewportSize.x,
        y: _random.nextDouble() * viewportSize.y,
        size: 0.6 + _random.nextDouble() * 2.2,
        speed: 4 + _random.nextDouble() * 18,
        twinkle: _random.nextDouble() * pi * 2,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    for (final star in _stars) {
      star.x -= star.speed * dt;
      if (star.x < -4) {
        star.x = viewportSize.x + 4;
        star.y = _random.nextDouble() * viewportSize.y;
      }
    }
    for (final nebula in _nebulae) {
      nebula.x -= nebula.drift * dt;
      if (nebula.x < -nebula.radius) {
        nebula.x = viewportSize.x + nebula.radius;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, viewportSize.x, viewportSize.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060A14), Color(0xFF12182B), Color(0xFF1A2238)],
        ).createShader(rect),
    );

    for (final nebula in _nebulae) {
      VfxUtils.drawGlowCircle(
        canvas,
        Offset(nebula.x, nebula.y),
        nebula.radius,
        Color(nebula.hue),
        blur: 48,
        opacity: 0.08,
      );
    }

    for (final star in _stars) {
      final twinkle = (sin(_elapsed * 2.2 + star.twinkle) + 1) / 2;
      canvas.drawCircle(
        Offset(star.x, star.y),
        star.size,
        Paint()..color = Color.fromRGBO(200, 220, 255, 0.25 + twinkle * 0.55),
      );
    }
  }
}

class _MenuStar {
  _MenuStar({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.twinkle,
  });

  double x;
  double y;
  final double size;
  final double speed;
  final double twinkle;
}

class _MenuNebula {
  _MenuNebula({
    required this.x,
    required this.y,
    required this.radius,
    required this.hue,
    required this.drift,
  });

  double x;
  final double y;
  final double radius;
  final int hue;
  final double drift;
}
