import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../core/constants/game_constants.dart';
import '../../domain/entities/ship_type.dart';
import '../rendering/ship_painter.dart';
import '../rendering/vfx_utils.dart';

class PlayerShipComponent extends PositionComponent with CollisionCallbacks {
  PlayerShipComponent({
    required Vector2 position,
    required this.shipType,
  }) : super(
          position: position,
          size: Vector2(GameConstants.playerSize * 1.4, GameConstants.playerSize),
          anchor: Anchor.center,
        );

  final ShipType shipType;
  Vector2 _velocity = Vector2.zero();
  double _thrustAnim = 0;
  double _bankAngle = 0;
  double _invincibleTimer = 0;

  Vector2 get velocity => _velocity;

  bool get isMoving => _velocity.length > 20;
  bool get isInvincible => _invincibleTimer > 0;

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: GameConstants.playerSize * 0.22));
  }

  void tickInvincibility(double dt) {
    if (_invincibleTimer > 0) _invincibleTimer -= dt;
  }

  void grantInvincibility([double duration = GameConstants.hitInvincibility]) {
    _invincibleTimer = duration;
  }

  void moveToward(Vector2? target, double dt, Vector2 gameSize) {
    final maxSpeed = GameConstants.playerBaseSpeed * shipType.speedMultiplier;
    final accel = GameConstants.playerAcceleration * shipType.speedMultiplier;
    final drag = GameConstants.playerDrag;

    if (target != null) {
      final toTarget = target - position;
      final dist = toTarget.length;
      if (dist > 12) {
        final desired = toTarget.normalized() * maxSpeed;
        final steer = (desired - _velocity);
        final steerMag = steer.length;
        if (steerMag > 0) {
          final step = min(accel * dt, steerMag);
          _velocity += steer.normalized() * step;
        }
        if (_velocity.length > maxSpeed) {
          _velocity = _velocity.normalized() * maxSpeed;
        }
      } else {
        _velocity *= max(0.0, 1.0 - drag * dt * 1.5);
      }
      _thrustAnim = (_velocity.length / maxSpeed).clamp(0.15, 1.0);
      _bankAngle = (_velocity.y / maxSpeed * 0.42).clamp(-0.42, 0.42);
    } else {
      final damp = max(0.0, 1.0 - drag * dt);
      _velocity *= damp;
      if (_velocity.length < 8) _velocity = Vector2.zero();
      _thrustAnim *= 0.92;
      _bankAngle *= 0.88;
    }

    position += _velocity * dt;
    _clampPosition(gameSize);
  }

  void applyMovement(Vector2 delta, double dt, Vector2 gameSize) {
    final maxSpeed = GameConstants.playerBaseSpeed * shipType.speedMultiplier;
    if (delta.length > 0) {
      _velocity = delta.normalized() * maxSpeed;
      position += _velocity * dt;
      _thrustAnim = 1.0;
      _bankAngle = (_velocity.y / maxSpeed * 0.42).clamp(-0.42, 0.42);
    } else {
      _velocity *= max(0.0, 1.0 - GameConstants.playerDrag * dt);
      _thrustAnim *= 0.9;
      _bankAngle *= 0.9;
    }
    _clampPosition(gameSize);
  }

  void _clampPosition(Vector2 gameSize) {
    final halfH = size.y / 2;
    final minX = gameSize.x * GameConstants.playerMinXRatio;
    final maxX = gameSize.x * GameConstants.playerMaxXRatio;
    final minY = halfH + 12;
    final maxY = gameSize.y - halfH - 12;

    if (position.x < minX) {
      position.x = minX;
      _velocity.x = max(0, _velocity.x);
    } else if (position.x > maxX) {
      position.x = maxX;
      _velocity.x = min(0, _velocity.x);
    }

    if (position.y < minY) {
      position.y = minY;
      _velocity.y = max(0, _velocity.y);
    } else if (position.y > maxY) {
      position.y = maxY;
      _velocity.y = min(0, _velocity.y);
    }
  }

  void resetVelocity() {
    _velocity = Vector2.zero();
    _bankAngle = 0;
    _thrustAnim = 0;
  }

  Vector2 get exhaustOffset => Vector2(-size.x * 0.42, 0);

  @override
  void render(Canvas canvas) {
    final blink = isInvincible && (sin(_invincibleTimer * 28) > 0);
    if (blink) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0x88FFFFFF),
      );
    }

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_bankAngle);
    canvas.translate(-size.x / 2, -size.y / 2);

    ShipPainter.paintPlayer(canvas, size.toSize(), shipType, thrust: _thrustAnim);

    VfxUtils.drawGlowCircle(
      canvas,
      Offset(size.x * 0.55, size.y * 0.5),
      size.x * 0.35,
      const Color(0xFF38BDF8),
      blur: 12,
      opacity: 0.12 + _thrustAnim * 0.08,
    );
    canvas.restore();

    if (blink) canvas.restore();
  }
}
