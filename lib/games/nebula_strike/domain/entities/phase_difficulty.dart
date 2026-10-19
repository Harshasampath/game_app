import 'dart:math';

import '../../game/rendering/ship_painter.dart';
import 'mission_phase.dart';

/// Runtime difficulty for the active mission phase — scales with mission order.
class PhaseDifficulty {
  PhaseDifficulty(this.phase, {this.endlessWave = 1, this.missionOrder = 1});

  final MissionPhase phase;
  final int endlessWave;
  final int missionOrder;

  bool get isBossPhase => phase.bossOnly;

  int get killQuota => phase.killTarget;

  double get _missionPace => max(0.48, 1.0 - (missionOrder - 1) * 0.1);

  int get maxOnScreen {
    if (isBossPhase) return 1;
    final orderBonus = (missionOrder - 1) ~/ 2;
    final endlessBonus = endlessWave > 5 ? 1 : 0;
    return phase.maxOnScreen + orderBonus + endlessBonus;
  }

  double get spawnInterval {
    if (isBossPhase) return 999;
    final endlessScale = max(1.0 - (endlessWave - 1) * 0.04, 0.55);
    return phase.spawnInterval * _missionPace * endlessScale;
  }

  double get enemyBulletSpeed {
    final orderBoost = 1.0 + (missionOrder - 1) * 0.07;
    final endlessScale = 1.0 + (endlessWave - 1) * 0.04;
    return phase.enemyBulletSpeed * orderBoost * endlessScale;
  }

  double get powerUpChance => isBossPhase ? 0.35 : max(0.12, 0.22 - missionOrder * 0.015);

  double get intermissionSeconds => isBossPhase ? 2.0 : 2.2;

  double enemyApproachSpeed(EnemyShipStyle style) {
    final base = switch (style) {
      EnemyShipStyle.scout => 72.0,
      EnemyShipStyle.weaver => 64.0,
      EnemyShipStyle.hunter => 78.0,
      EnemyShipStyle.boss => 48.0,
    };
    return base + missionOrder * 8 + phase.hpBonus * 4;
  }

  double shootIntervalFor(EnemyShipStyle style) {
    final base = switch (style) {
      EnemyShipStyle.scout => 2.4,
      EnemyShipStyle.weaver => 1.9,
      EnemyShipStyle.hunter => 1.45,
      EnemyShipStyle.boss => 1.05,
    };
    final orderScale = max(0.55, 1.0 - (missionOrder - 1) * 0.08);
    return base * phase.shootIntervalScale * orderScale;
  }

  int hpFor(EnemyShipStyle style) {
    final base = switch (style) {
      EnemyShipStyle.scout => 1,
      EnemyShipStyle.weaver => 1,
      EnemyShipStyle.hunter => 2,
      EnemyShipStyle.boss => 42,
    };
    final orderBonus = max(0, (missionOrder - 2) ~/ 2);
    final endlessBonus = max(0, (endlessWave - 2) ~/ 3);
    return base + phase.hpBonus + orderBonus + endlessBonus;
  }

  EnemyShipStyle rollStyle(Random random) {
    if (phase.bossOnly) return EnemyShipStyle.boss;

    final total = phase.scoutWeight + phase.weaverWeight + phase.hunterWeight;
    if (total <= 0) return EnemyShipStyle.scout;

    final roll = random.nextDouble() * total;
    if (roll < phase.scoutWeight) return EnemyShipStyle.scout;
    if (roll < phase.scoutWeight + phase.weaverWeight) return EnemyShipStyle.weaver;
    return EnemyShipStyle.hunter;
  }

  String get bannerSubtitle => phase.objective;
}
