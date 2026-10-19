import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/game_constants.dart';
import '../domain/entities/game_mission.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/mission_background_theme.dart';
import '../domain/entities/phase_difficulty.dart';
import '../domain/entities/ship_type.dart';
import '../presentation/providers/dependency_providers.dart';
import '../presentation/providers/game_session_provider.dart';
import '../presentation/providers/provider_scheduling.dart';
import 'audio/game_audio.dart';
import 'components/bullet_component.dart';
import 'components/engine_trail_component.dart';
import 'components/enemy_ship_component.dart';
import 'components/explosion_component.dart';
import 'components/horizontal_parallax_background.dart';
import 'components/player_ship_component.dart';
import 'components/power_up_component.dart';
import 'components/screen_post_fx_component.dart';
import 'components/shield_aura_component.dart';
import 'nebula_strike_game.dart';
import 'rendering/ship_painter.dart';

/// Active combat
class CombatSession extends Component with HasGameReference<FlameGame> {
  CombatSession({required this.ref, required this.mission});

  final WidgetRef ref;
  final GameMission mission;

  final _random = Random();

  late HorizontalParallaxBackground _background;
  late PlayerShipComponent _player;
  late EngineTrailComponent _engineTrail;
  late ShieldAuraComponent _shieldAura;
  late ScreenPostFxComponent _postFx;

  int _phaseIndex = 0;
  Vector2? _dragTarget;
  double _gameTime = 0;
  double _shotCooldown = 0;
  double _spawnCooldown = 0;
  bool _bossSpawned = false;
  bool _inIntermission = false;
  double _intermissionTimer = 0;
  bool _missionCompleting = false;

  Vector2 get _size => game.size;

  NebulaStrikeGame get _game => game as NebulaStrikeGame;

  int get _aliveEnemies => children.whereType<EnemyShipComponent>().length;

  PhaseDifficulty get _phaseDiff {
    final session = ref.read(gameSessionProvider);
    final phase = mission.phaseAt(_phaseIndex);
    return PhaseDifficulty(
      phase,
      endlessWave: session.endlessWave,
      missionOrder: mission.order,
    );
  }

  double get _scrollSpeed {
    final session = ref.read(gameSessionProvider);
    return GameConstants.worldScrollSpeed + session.endlessWave * 4 + _phaseIndex * 3;
  }

  void _mutateSession(void Function(GameSessionNotifier notifier) mutate) {
    deferProviderWrite(() => mutate(ref.read(gameSessionProvider.notifier)));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final ship = ref.read(selectedShipProvider);
    final backdrop = MissionBackgroundThemes.forMissionId(mission.id);
    _background = HorizontalParallaxBackground(
      viewportSize: _size,
      theme: backdrop,
    );
    add(_background);

    _player = PlayerShipComponent(
      position: Vector2(_size.x * 0.18, _size.y * 0.5),
      shipType: ship,
    );
    add(_player);

    _engineTrail = EngineTrailComponent(target: _player);
    add(_engineTrail);

    _shieldAura = ShieldAuraComponent(target: _player, isActive: false);
    add(_shieldAura);

    _postFx = ScreenPostFxComponent(viewportSize: _size);
    add(_postFx);

    _beginPhase(showBanner: true);
  }

  void handleDragStart(Vector2 position) {
    if (ref.read(gameSessionProvider).status != GameStatus.playing) return;
    _dragTarget = position;
  }

  void handleDragUpdate(Vector2 position) {
    if (ref.read(gameSessionProvider).status != GameStatus.playing) return;
    _dragTarget = position;
  }

  void handleDragEnd() => _dragTarget = null;

  void handleTapDown(Vector2 position) {
    if (ref.read(gameSessionProvider).status != GameStatus.playing) return;
    GameAudio.unlock();
    _dragTarget = position;
    _tryFire();
  }

  void _tryFire() {
    final session = ref.read(gameSessionProvider);
    if (session.status != GameStatus.playing || _inIntermission) return;
    if (_shotCooldown > 0) return;

    final ship = ref.read(selectedShipProvider);
    final baseCd = session.rapidFireActive
        ? GameConstants.rapidFireCooldown
        : GameConstants.tapFireCooldown;
    _shotCooldown = baseCd / ship.fireRateMultiplier;
    GameAudio.playerShoot();
    _fire();
  }

  void resetRound() {
    children.whereType<BulletComponent>().forEach((c) => c.removeFromParent());
    children.whereType<EnemyShipComponent>().forEach((c) => c.removeFromParent());
    children.whereType<PowerUpComponent>().forEach((c) => c.removeFromParent());
    children.whereType<ExplosionComponent>().forEach((c) => c.removeFromParent());
    _background.scrollX = 0;
    _player.position = Vector2(_size.x * 0.18, _size.y * 0.5);
    _player.resetVelocity();
    _dragTarget = null;
    _gameTime = 0;
    _phaseIndex = 0;
    _inIntermission = false;
    _missionCompleting = false;
    _bossSpawned = false;

    final active = ref.read(activeMissionProvider) ?? mission;
    _mutateSession((n) => n.startMission(
          active,
          highScore: ref.read(gameSessionProvider).highScore,
        ));
    _beginPhase(showBanner: true);
  }

  void _beginPhase({bool showBanner = false}) {
    final diff = _phaseDiff;
    _bossSpawned = diff.isBossPhase;
    _spawnCooldown = diff.isBossPhase ? 0.35 : 0.12;

    if (showBanner) {
      final phase = mission.phaseAt(_phaseIndex);
      if (mission.isEndless) {
        final session = ref.read(gameSessionProvider);
        _game.waveBanner.showEndlessWave(wave: session.endlessWave);
      } else {
        _game.waveBanner.showPhaseNumber(
          phaseNumber: _phaseIndex + 1,
          totalPhases: mission.totalPhases,
          phaseName: phase.name,
          objective: phase.objective,
        );
      }
    }

    if (diff.isBossPhase) {
      Future.delayed(const Duration(milliseconds: 450), _spawnBoss);
    } else if (!_inIntermission) {
      _spawnEnemy();
      _spawnCooldown = diff.spawnInterval * 0.5;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final session = ref.read(gameSessionProvider);
    if (session.status != GameStatus.playing) return;

    if (_inIntermission) {
      _intermissionTimer -= dt;
      if (_intermissionTimer <= 0) {
        _inIntermission = false;
        _goToNextPhase();
      }
      return;
    }

    if (_shotCooldown > 0) _shotCooldown -= dt;
    _gameTime += dt;
    _mutateSession((n) => n.tickMissionTime(dt));

    if (!_bossSpawned) {
      _spawnCooldown -= dt;
      if (_spawnCooldown <= 0) {
        _spawnEnemy();
        _spawnCooldown = _phaseDiff.spawnInterval;
      }
    }

    _background.addScroll(_scrollSpeed * dt);
    _player.tickInvincibility(dt);
    _player.moveToward(_dragTarget, dt, _size);
    _shieldAura.isActive = session.shieldActive;
    _cleanupOffscreen();
    _capEnemyBullets();
    _checkPlayerCollisions();
    _checkPhaseProgress(session);
  }

  void _checkPhaseProgress(GameSession session) {
    if (_missionCompleting) return;
    if (session.killsInPhase < session.phaseKillTarget) return;
    if (_hasEnemies()) return;

    if (mission.isEndless) {
      _startEndlessIntermission();
      return;
    }

    if (_phaseIndex >= mission.phases.length - 1) {
      _completeMission();
      return;
    }

    _startPhaseIntermission();
  }

  void _startPhaseIntermission() {
    _inIntermission = true;
    _intermissionTimer = _phaseDiff.intermissionSeconds;
    _clearEnemyBullets();
    GameAudio.phaseClear();
    final next = mission.phaseAt(_phaseIndex + 1);
    _mutateSession((n) => n.advancePhase(
          phaseName: next.name,
          phaseObjective: next.objective,
          phaseKillTarget: next.killTarget,
          phaseIndex: _phaseIndex + 2,
        ));
    _game.waveBanner.showNextPhaseIntermission(
      phaseNumber: _phaseIndex + 2,
      phaseName: next.name,
      objective: next.objective,
      duration: _intermissionTimer,
    );
  }

  void _startEndlessIntermission() {
    _inIntermission = true;
    _intermissionTimer = 2.0;
    _clearEnemyBullets();
    GameAudio.phaseClear();
    _mutateSession((n) => n.advanceEndlessWave());
    final nextWave = ref.read(gameSessionProvider).endlessWave;
    _game.waveBanner.showEndlessWave(
      wave: nextWave,
      duration: _intermissionTimer,
    );
  }

  void _goToNextPhase() {
    _game.waveBanner.dismiss();

    if (mission.isEndless) {
      _phaseIndex = 0;
      _bossSpawned = false;
      _beginPhase(showBanner: false);
      return;
    }

    _phaseIndex++;
    _bossSpawned = false;
    _beginPhase(showBanner: false);
  }

  void _completeMission() {
    if (_missionCompleting) return;
    _missionCompleting = true;
    GameAudio.missionComplete();
    _game.waveBanner.show(
      title: 'MISSION COMPLETE',
      subtitle: mission.title,
      duration: 3,
    );
    _mutateSession((n) => n.completeMission());
  }

  bool _hasEnemies() => children.whereType<EnemyShipComponent>().isNotEmpty;

  void _fire() {
    final session = ref.read(gameSessionProvider);
    if (session.status != GameStatus.playing || _inIntermission) return;

    final ship = ref.read(selectedShipProvider);
    final dmg = (20 * ship.damageMultiplier).round();
    final boost = session.rapidFireActive ? dmg + 4 : dmg;

    if (session.spreadShotActive) {
      for (final angle in [-0.1, 0.0, 0.1]) {
        _spawnBullet(boost, angle);
      }
    } else {
      _spawnBullet(boost, 0);
      if (session.rapidFireActive) _spawnBullet(boost, 0.015);
    }
  }

  void _spawnBullet(int damage, double angle) {
    final dir = Vector2(cos(angle), sin(angle));
    add(BulletComponent(
      position: _player.position + Vector2(_player.size.x * 0.45, 0),
      velocity: dir * GameConstants.bulletSpeed,
      damage: damage,
      isPlayerBullet: true,
    ));
  }

  void _spawnEnemy() {
    final session = ref.read(gameSessionProvider);
    if (session.status != GameStatus.playing || _bossSpawned || _inIntermission) return;
    if (session.killsInPhase >= session.phaseKillTarget) return;

    final diff = _phaseDiff;
    if (_aliveEnemies >= diff.maxOnScreen) return;

    final style = diff.rollStyle(_random);
    final movement = switch (style) {
      EnemyShipStyle.scout => EnemyMovement.approach,
      EnemyShipStyle.weaver => EnemyMovement.weave,
      EnemyShipStyle.hunter => EnemyMovement.strafe,
      EnemyShipStyle.boss => EnemyMovement.hold,
    };

    add(EnemyShipComponent(
      position: Vector2(
        _size.x + 28 + _random.nextDouble() * 24,
        56 + _random.nextDouble() * (_size.y - 112),
      ),
      style: style,
      movement: movement,
      speed: diff.enemyApproachSpeed(style),
      maxHp: diff.hpFor(style),
      points: GameConstants.pointsPerKill + session.endlessWave * 4,
      worldScroll: _scrollSpeed * 0.1,
      bulletSpeed: diff.enemyBulletSpeed,
      shootInterval: diff.shootIntervalFor(style),
      onDestroyed: _onEnemyDestroyed,
      onEscaped: (_) {},
    ));
  }

  void _spawnBoss() {
    if (!isMounted) return;
    final diff = _phaseDiff;
    add(EnemyShipComponent(
      position: Vector2(_size.x + 48, _size.y * 0.45),
      style: EnemyShipStyle.boss,
      movement: EnemyMovement.hold,
      speed: diff.enemyApproachSpeed(EnemyShipStyle.boss),
      maxHp: diff.hpFor(EnemyShipStyle.boss),
      points: GameConstants.bossBonus,
      worldScroll: _scrollSpeed * 0.06,
      bulletSpeed: diff.enemyBulletSpeed,
      shootInterval: diff.shootIntervalFor(EnemyShipStyle.boss),
      onDestroyed: _onEnemyDestroyed,
      onEscaped: (_) {},
    ));
  }

  void _onEnemyDestroyed(EnemyShipComponent enemy, int points) {
    GameAudio.enemyKilled(boss: enemy.style == EnemyShipStyle.boss);
    add(ExplosionComponent(
      position: enemy.position.clone(),
      large: enemy.style == EnemyShipStyle.boss,
    ));
    _mutateSession((notifier) => notifier.registerKill(points, _gameTime));

    if (_random.nextDouble() < _phaseDiff.powerUpChance) {
      add(PowerUpComponent(
        position: enemy.position.clone(),
        type: PowerUpType.values[_random.nextInt(PowerUpType.values.length)],
        worldScroll: _scrollSpeed * 0.15,
        onCollected: (t) => _mutateSession((notifier) => notifier.activatePowerUp(t)),
      ));
    }
  }

  void _checkPlayerCollisions() {
    final session = ref.read(gameSessionProvider);
    if (session.status != GameStatus.playing || _player.isInvincible) return;

    for (final enemy in children.whereType<EnemyShipComponent>()) {
      if (_player.toRect().overlaps(enemy.toRect())) {
        add(ExplosionComponent(position: enemy.position.clone()));
        enemy.removeFromParent();
        _onPlayerHit();
        return;
      }
    }

    for (final bullet in children.whereType<BulletComponent>()) {
      if (!bullet.isPlayerBullet && _player.toRect().overlaps(bullet.toRect())) {
        bullet.removeFromParent();
        _onPlayerHit();
        return;
      }
    }

    for (final p in children.whereType<PowerUpComponent>()) {
      if (_player.toRect().overlaps(p.toRect())) {
        GameAudio.powerUp();
        _mutateSession((notifier) => notifier.activatePowerUp(p.type));
        p.removeFromParent();
      }
    }
  }

  void _onPlayerHit() {
    if (_player.isInvincible) return;

    final session = ref.read(gameSessionProvider);
    final hadShield = session.shieldActive;
    final livesBefore = session.lives;
    final livesTotal = session.livesAtStart;
    final remainingLives = hadShield ? livesBefore : livesBefore - 1;
    final isDead = !hadShield && remainingLives <= 0;

    // Block further hits before Riverpod state catches up.
    _player.grantInvincibility();

    GameAudio.playerDamage();
    add(ExplosionComponent(position: _player.position.clone(), large: true));
    _player.resetVelocity();

    _mutateSession((notifier) {
      notifier.loseLife();
      if (!ref.read(gameSessionProvider).isGameOver) {
        notifier.clearPowerUps();
      }
    });

    if (hadShield) {
      _clearEnemyBullets();
      _game.waveBanner.show(
        title: 'SHIELD ABSORBED',
        subtitle: 'NO LIFE LOST · LIVES $livesBefore / $livesTotal',
        duration: 1.2,
        compact: true,
        titleColor: const Color(0xFF4ADE80),
        subtitleColor: const Color(0xFF86EFAC),
      );
    } else if (isDead) {
      _game.waveBanner.show(
        title: 'NO LIVES LEFT',
        subtitle: '',
        duration: 1.4,
        compact: true,
        titleColor: const Color(0xFFFF6B6B),
        subtitleColor: const Color(0xFFFDA4AF),
      );
    } else {
      _game.waveBanner.show(
        title: 'LIVES REMAINING: $remainingLives / $livesTotal',
        subtitle: '',
        duration: 1.4,
        compact: true,
        titleColor: const Color(0xFFFF8A8A),
        subtitleColor: const Color(0xFFFDA4AF),
      );
    }

    _player.position = Vector2(_size.x * 0.18, _size.y * 0.5);
    _clearEnemyBullets();
  }

  void _clearEnemyBullets() {
    children
        .whereType<BulletComponent>()
        .where((b) => !b.isPlayerBullet)
        .forEach((b) => b.removeFromParent());
  }

  void _capEnemyBullets() {
    final hostile = children
        .whereType<BulletComponent>()
        .where((b) => !b.isPlayerBullet)
        .toList();
    final max = GameConstants.maxEnemyBulletsOnScreen;
    if (hostile.length <= max) return;

    // Drop the oldest shots nearest the player so the lane can open up.
    hostile.sort((a, b) => a.position.x.compareTo(b.position.x));
    for (var i = 0; i < hostile.length - max; i++) {
      hostile[i].removeFromParent();
    }
  }

  void _cleanupOffscreen() {
    // Remove stray bullets that were parented to the root game (legacy spawns).
    game.children
        .whereType<BulletComponent>()
        .forEach((b) => b.removeFromParent());

    children.whereType<BulletComponent>().where((b) {
      return b.position.x < -40 || b.position.x > _size.x + 40 ||
          b.position.y < -40 || b.position.y > _size.y + 40;
    }).forEach((b) => b.removeFromParent());

    children.whereType<EnemyShipComponent>()
        .where((e) => e.position.x < GameConstants.enemyDespawnX - 20)
        .forEach((e) => e.removeFromParent());

    children.whereType<PowerUpComponent>()
        .where((p) => p.position.x < -40)
        .forEach((p) => p.removeFromParent());
  }
}
