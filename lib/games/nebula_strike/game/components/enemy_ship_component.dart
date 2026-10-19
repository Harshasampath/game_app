import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../../core/constants/game_constants.dart';
import '../audio/game_audio.dart';
import '../rendering/ship_painter.dart';
import '../rendering/vfx_utils.dart';
import 'bullet_component.dart';
import 'player_ship_component.dart';

enum EnemyMovement { approach, weave, strafe, hold }

typedef EnemyDestroyedCallback = void Function(EnemyShipComponent enemy, int points);
typedef EnemyEscapedCallback = void Function(EnemyShipComponent enemy);

class EnemyShipComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlameGame> {
  EnemyShipComponent({
    required Vector2 position,
    required this.style,
    required this.movement,
    required this.speed,
    required this.maxHp,
    required this.points,
    required this.worldScroll,
    required this.bulletSpeed,
    this.onDestroyed,
    this.onEscaped,
    this.shootInterval = 0,
  })  : hp = maxHp,
        super(anchor: Anchor.center, position: position) {
    size = Vector2.all(
      style == EnemyShipStyle.boss
          ? GameConstants.enemySizeBoss
          : style == EnemyShipStyle.hunter
              ? GameConstants.enemySizeMedium
              : GameConstants.enemySizeSmall,
    );
    _weavePhase = _random.nextDouble() * pi * 2;
  }

  final EnemyShipStyle style;
  final EnemyMovement movement;
  final double speed;
  final int maxHp;
  int hp;
  final int points;
  final double worldScroll;
  final double bulletSpeed;
  final double shootInterval;
  final EnemyDestroyedCallback? onDestroyed;
  final EnemyEscapedCallback? onEscaped;

  double _shootCooldown = 0;
  double _weaveTime = 0;
  double _weavePhase = 0;
  double _telegraphTimer = 0;
  Vector2? _aimTarget;
  bool _engaged = false;
  double _strafeVelocity = 0;
  double _bankAngle = 0;
  final _random = Random();

  static const double _telegraphDuration = 0.55;

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: size.x * 0.30));
    _shootCooldown = shootInterval * (0.5 + _random.nextDouble() * 0.5);
  }

  double get _holdMinX => game.size.x * GameConstants.enemyHoldMinXRatio;
  double get _engageStartX => game.size.x * GameConstants.enemyEngageStartRatio;

  bool get _canShoot {
    return position.x < game.size.x - 24 &&
        position.x > _holdMinX - 20 &&
        shootInterval > 0;
  }

  bool get isTelegraphing => _telegraphTimer > 0;

  @override
  void update(double dt) {
    super.update(dt);
    _weaveTime += dt;

    if (position.x <= _engageStartX) {
      _engaged = true;
    }

    if (!_engaged) {
      _updateApproach(dt);
    } else if (!isTelegraphing) {
      _updateEngagedMovement(dt);
    }

    _updateShooting(dt);

    if (position.x < GameConstants.enemyDespawnX) {
      onEscaped?.call(this);
      removeFromParent();
    }
  }

  void _updateApproach(double dt) {
    final approachSpeed = speed + worldScroll * 0.65;
    final distToEngage = (position.x - _engageStartX).clamp(0, 200);
    final slowdown = (distToEngage / 200).clamp(0.65, 1.0);
    position.x -= approachSpeed * slowdown * dt;

    final entrySway = sin(_weaveTime * 2.2 + _weavePhase) * 28 * dt;
    position.y += entrySway;
    _bankAngle = entrySway.sign * 0.15;

    final halfH = size.y / 2;
    position.y = position.y.clamp(halfH + 16, game.size.y - halfH - 16);
  }

  void _updateEngagedMovement(double dt) {
    final drift = worldScroll * (style == EnemyShipStyle.boss ? 0.32 : 0.48);
    position.x -= drift * dt;
    position.x = max(position.x, _holdMinX);

    final player = _findPlayer();

    switch (movement) {
      case EnemyMovement.approach:
        position.y += sin(_weaveTime * 2.2 + _weavePhase) * 32 * dt;
        position.y += cos(_weaveTime * 3.1) * 12 * dt;
        _bankAngle = sin(_weaveTime * 2.2) * 0.18;
      case EnemyMovement.weave:
        position.y += sin(_weaveTime * 2.8 + _weavePhase) * 44 * dt;
        position.y += sin(_weaveTime * 1.4 + _weavePhase * 2) * 22 * dt;
        _bankAngle = sin(_weaveTime * 2.8) * 0.22;
      case EnemyMovement.strafe:
        if (player != null) {
          final vertGap = player.position.y - position.y;
          final pursuit = vertGap.clamp(-1.0, 1.0) * 95 * dt;
          final evade = sin(_weaveTime * 3.2 + _weavePhase) * 18 * dt;
          _strafeVelocity += pursuit + evade;
          _strafeVelocity *= 0.9;
          _strafeVelocity = _strafeVelocity.clamp(-120.0, 120.0);
          position.y += _strafeVelocity * dt;

          // Hunters keep optimal firing distance — back off if too close
          final horizGap = position.x - player.position.x;
          if (horizGap < game.size.x * 0.28) {
            position.x += 35 * dt;
          } else if (horizGap > game.size.x * 0.52) {
            position.x -= 18 * dt;
          }
          _bankAngle = (_strafeVelocity / 120 * 0.25).clamp(-0.25, 0.25);
        }
      case EnemyMovement.hold:
        if (style == EnemyShipStyle.boss && player != null) {
          final orbitY = sin(_weaveTime * 1.2) * 55;
          final trackY = (player.position.y - position.y) * 0.35 * dt;
          position.y += orbitY * dt + trackY;
          position.x += sin(_weaveTime * 0.9) * 12 * dt;
          _bankAngle = sin(_weaveTime * 0.9) * 0.15;
        } else {
          position.y += sin(_weaveTime * 1.6 + _weavePhase) * 20 * dt;
          _bankAngle = sin(_weaveTime * 1.6) * 0.1;
        }
    }

    final halfH = size.y / 2;
    position.y = position.y.clamp(halfH + 16, game.size.y - halfH - 16);
  }

  void _updateShooting(double dt) {
    if (shootInterval <= 0) return;

    if (isTelegraphing) {
      _telegraphTimer -= dt;
      final player = _findPlayer();
      if (player != null) {
        _aimTarget = _leadTarget(player);
      }
      if (_telegraphTimer <= 0) {
        _fireAtPlayer();
        _shootCooldown = shootInterval + _random.nextDouble() * 0.35;
        _aimTarget = null;
      }
      return;
    }

    _shootCooldown -= dt;
    if (_shootCooldown <= 0 && _canShoot) {
      final player = _findPlayer();
      if (player != null && _hasLineOfSight(player)) {
        _aimTarget = _leadTarget(player);
        _telegraphTimer = _telegraphDuration * (style == EnemyShipStyle.boss ? 1.15 : 1.0);
      }
    }
  }

  bool _hasLineOfSight(PlayerShipComponent player) {
    final vertDist = (player.position.y - position.y).abs();
    final maxAim = style == EnemyShipStyle.boss ? game.size.y * 0.55 : game.size.y * 0.38;
    return vertDist < maxAim && player.position.x < position.x + 40;
  }

  Vector2 _leadTarget(PlayerShipComponent player) {
    final muzzle = position + Vector2(-size.x * 0.42, 0);
    final playerVel = player.velocity;

    var target = player.position.clone();
    for (var i = 0; i < 2; i++) {
      final toTarget = target - muzzle;
      final dist = toTarget.length;
      if (dist < 1) break;
      final timeToHit = dist / bulletSpeed;
      target = player.position + playerVel * timeToHit;
    }
    return target;
  }

  PlayerShipComponent? _findPlayer() {
    Component? node = parent;
    while (node != null) {
      for (final child in node.children) {
        if (child is PlayerShipComponent) return child;
      }
      node = node.parent;
    }
    return game.children.whereType<PlayerShipComponent>().firstOrNull;
  }

  void _fireAtPlayer() {
    final player = _findPlayer();
    if (player == null) return;

    final muzzle = position + Vector2(-size.x * 0.42, 0);
    final target = _aimTarget ?? _leadTarget(player);
    final toTarget = target - muzzle;
    if (toTarget.length < 1) return;
    final dir = toTarget.normalized();

    final spread = switch (style) {
      EnemyShipStyle.scout => 0.04,
      EnemyShipStyle.weaver => 0.06,
      EnemyShipStyle.hunter => 0.025,
      EnemyShipStyle.boss => 0.08,
    };
    final angle = atan2(dir.y, dir.x) + (_random.nextDouble() - 0.5) * spread;
    final shotDir = Vector2(cos(angle), sin(angle));

    GameAudio.enemyShoot();

    final host = parent ?? game;
    host.add(
      BulletComponent(
        position: muzzle,
        velocity: shotDir * bulletSpeed,
        damage: style == EnemyShipStyle.boss ? 2 : 1,
        isPlayerBullet: false,
      ),
    );

    // Boss fires a secondary spread shot
    if (style == EnemyShipStyle.boss) {
      for (final offset in [-0.12, 0.12]) {
        final spreadDir = Vector2(cos(angle + offset), sin(angle + offset));
        host.add(
          BulletComponent(
            position: muzzle,
            velocity: spreadDir * bulletSpeed * 0.92,
            damage: 1,
            isPlayerBullet: false,
          ),
        );
      }
    }
  }

  bool get isVulnerableToPlayer => _isVulnerableToPlayer;

  /// Collision radius — matches [CircleHitbox] in [onLoad].
  double get hitRadius => size.x * 0.30;

  bool get _isVulnerableToPlayer {
    final leftEdge = position.x - size.x * 0.48;
    return leftEdge <= game.size.x - GameConstants.enemyVulnerableScreenInset;
  }

  /// Applies damage from a player bullet (sweep or overlap).
  void registerPlayerBulletHit(BulletComponent bullet) {
    if (!bullet.isPlayerBullet || !isVulnerableToPlayer) return;
    if (!bullet.isMounted) return;
    bullet.removeFromParent();
    takeDamage(bullet.damage);
  }

  void takeDamage(int damage) {
    hp -= damage;
    if (hp <= 0) {
      onDestroyed?.call(this, points);
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BulletComponent && other.isPlayerBullet) {
      registerPlayerBulletHit(other);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_bankAngle);
    canvas.translate(-size.x / 2, -size.y / 2);

    ShipPainter.paintEnemy(canvas, size.toSize(), style);
    canvas.restore();

    if (isTelegraphing && _aimTarget != null) {
      final muzzle = Offset(size.x * 0.08, size.y * 0.5);
      final pulse = (sin(_telegraphTimer * 18) + 1) / 2;
      final aimLocal = Offset(
        (_aimTarget!.x - position.x) * 0.15,
        size.y * 0.5 + (_aimTarget!.y - position.y) * 0.08,
      );
      canvas.drawLine(
        muzzle,
        Offset(muzzle.dx - 48, aimLocal.dy),
        Paint()
          ..color = Color.fromRGBO(248, 113, 113, 0.35 + pulse * 0.45)
          ..strokeWidth = 2,
      );
      VfxUtils.drawGlowCircle(
        canvas,
        muzzle,
        6,
        const Color(0xFFEF4444),
        blur: 6,
        opacity: 0.4 + pulse * 0.4,
      );
    }

    if (hp < maxHp) {
      final ratio = hp / maxHp;
      final barY = style == EnemyShipStyle.boss ? -16.0 : -10.0;
      final barW = size.x * (style == EnemyShipStyle.boss ? 1.0 : 0.7);
      final barX = (size.x - barW) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW, 4), const Radius.circular(2)),
        Paint()..color = const Color(0xAA0F172A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW * ratio, 4), const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
            colors: ratio > 0.3
                ? const [Color(0xFFEF4444), Color(0xFFF97316)]
                : const [Color(0xFFDC2626), Color(0xFF991B1B)],
          ).createShader(Rect.fromLTWH(barX, barY, barW, 4)),
      );
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
