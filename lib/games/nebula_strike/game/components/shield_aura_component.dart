import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../rendering/vfx_utils.dart';
import 'player_ship_component.dart';

class ShieldAuraComponent extends Component {
  ShieldAuraComponent({required this.target, required this.isActive});

  final PlayerShipComponent target;
  bool isActive;
  double _phase = 0;

  @override
  void update(double dt) {
    _phase += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;

    final center = target.position.toOffset();
    final radius = target.size.x * 0.55 + sin(_phase) * 3;

    VfxUtils.drawGlowCircle(
      canvas,
      center,
      radius,
      const Color(0xFF4ADE80),
      blur: 14,
      opacity: 0.35,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (var i = 0; i < 6; i++) {
      final angle = _phase + i * pi / 3;
      final arcCenter = center + Offset(cos(angle) * radius, sin(angle) * radius);
      canvas.drawCircle(arcCenter, 2.5, Paint()..color = const Color(0xFF86EFAC));
    }
  }
}
