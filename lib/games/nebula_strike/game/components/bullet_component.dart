import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/constants/game_constants.dart';
import '../rendering/vfx_utils.dart';
import 'enemy_ship_component.dart';

class BulletComponent extends PositionComponent with CollisionCallbacks {
  BulletComponent({
    required Vector2 position,
    required this.velocity,
    required this.damage,
    required this.isPlayerBullet,
  }) : super(
          position: position,
          size: Vector2(
            isPlayerBullet ? GameConstants.bulletWidth : GameConstants.bulletWidth * 1.1,
            isPlayerBullet ? GameConstants.bulletHeight : GameConstants.bulletHeight * 1.35,
          ),
          anchor: Anchor.center,
        );

  final Vector2 velocity;
  final int damage;
  final bool isPlayerBullet;
  int _trailFrames = 0;
  double _pulse = 0;

  double get hitRadius => max(size.x, size.y) * 0.42;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(
      size: Vector2(size.x * 0.85, size.y * 0.75),
      anchor: Anchor.center,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt * 18;
    _trailFrames = (_trailFrames + 1).clamp(0, 8);

    final delta = velocity * dt;
    if (isPlayerBullet && delta.length > 4) {
      final from = position.clone();
      final to = from + delta;
      final hitEnemy = _sweepPlayerHits(from, to);
      if (hitEnemy) return;
      position.setFrom(to);
    } else {
      position += delta;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (!isPlayerBullet) return;
    if (other is BulletComponent && !other.isPlayerBullet) {
      _cancelEnemyBullet(other);
    }
  }

  /// Player shots can shoot down incoming fire; also sweep-check each frame.
  bool _sweepPlayerHits(Vector2 from, Vector2 to) {
    final host = parent;
    if (host == null) return false;

    for (final hostile in host.children.whereType<BulletComponent>()) {
      if (hostile.isPlayerBullet || !hostile.isMounted) continue;
      if (_segmentHitsCircle(from, to, hostile.position, hostile.hitRadius)) {
        _cancelEnemyBullet(hostile);
      }
    }

    for (final enemy in host.children.whereType<EnemyShipComponent>()) {
      if (!enemy.isVulnerableToPlayer) continue;
      if (_segmentHitsCircle(from, to, enemy.position, enemy.hitRadius)) {
        enemy.registerPlayerBulletHit(this);
        return true;
      }
    }
    return false;
  }

  void _cancelEnemyBullet(BulletComponent hostile) {
    if (!hostile.isMounted) return;
    final sparkPos = hostile.position.clone();
    hostile.removeFromParent();
    parent?.add(_BulletCancelSpark(position: sparkPos));
  }

  bool _segmentHitsCircle(Vector2 a, Vector2 b, Vector2 center, double radius) {
    final ab = b - a;
    final len2 = ab.length2;
    if (len2 < 1e-6) return (center - a).length <= radius;
    final t = ((center - a).dot(ab)) / len2;
    final clamped = t.clamp(0.0, 1.0);
    final closest = a + ab * clamped;
    return (center - closest).length <= radius;
  }

  @override
  void render(Canvas canvas) {
    final angle = atan2(velocity.y, velocity.x);
    canvas.save();
    canvas.rotate(angle);

    if (isPlayerBullet) {
      for (var i = _trailFrames; i > 0; i--) {
        final t = i / _trailFrames;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(-size.x * 0.5 * t * 1.2, 0),
              width: size.x * (0.25 + t * 0.45),
              height: size.y * 0.35,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = Color.fromRGBO(56, 189, 248, t * 0.4),
        );
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: size.x * 1.5, height: size.y * 2),
          const Radius.circular(4),
        ),
        Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
          const Radius.circular(3),
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF7DD3FC), Color(0xFFE0F2FE)],
          ).createShader(Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y)),
      );

      canvas.drawCircle(
        Offset(size.x * 0.3, 0),
        2 + sin(_pulse) * 0.5,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    } else {
      VfxUtils.drawGlowCircle(canvas, Offset.zero, size.x * 0.7, const Color(0xFFEF4444), blur: 8, opacity: 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
          const Radius.circular(3),
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFF87171)],
          ).createShader(Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y)),
      );
    }

    canvas.restore();
  }
}

/// Brief cyan flash when the player cancels an enemy shot.
class _BulletCancelSpark extends PositionComponent {
  _BulletCancelSpark({required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed > 0.2) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _elapsed / 0.2).clamp(0.0, 1.0);
    VfxUtils.drawGlowCircle(
      canvas,
      Offset.zero,
      6 + _elapsed * 28,
      const Color(0xFF7DD3FC),
      blur: 10,
      opacity: alpha * 0.75,
    );
    canvas.drawCircle(
      Offset.zero,
      3 + _elapsed * 6,
      Paint()..color = Color(0xFFE0F2FE).withValues(alpha: alpha),
    );
  }
}
