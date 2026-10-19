import 'dart:math';

import '../../core/constants/game_constants.dart';
import '../../game/rendering/ship_painter.dart';

/// Scales challenge by wave so early sectors teach dodge + aim, later ones intensify.
class WaveDifficulty {
  WaveDifficulty(this.wave);

  final int wave;

  bool get isBossWave => wave % GameConstants.bossEveryNWaves == 0;

  String get sectorName {
    if (wave <= 2) return 'TRAINING SECTOR';
    if (wave <= 5) return 'OUTER RIM';
    if (wave <= 9) return 'CONTESTED ZONE';
    if (wave <= 14) return 'DEEP VOID';
    return 'NEBULA CORE';
  }

  String get intensityLabel {
    if (wave <= 2) return 'LIGHT';
    if (wave <= 5) return 'MODERATE';
    if (wave <= 9) return 'INTENSE';
    return 'ELITE';
  }

  int get killQuota {
    if (isBossWave) return 1;
    return (3 + wave).clamp(4, 14);
  }

  int get maxOnScreen {
    if (wave <= 1) return 2;
    if (wave <= 3) return 3;
    if (wave <= 6) return 4;
    return 5;
  }

  double get spawnInterval {
    if (wave <= 2) return 1.35;
    if (wave <= 5) return 1.05;
    return 0.85;
  }

  double get enemyBulletSpeed {
    if (wave <= 2) return 210;
    if (wave <= 5) return 250;
    if (wave <= 9) return 290;
    return 330;
  }

  double shootIntervalFor(EnemyShipStyle style) {
    final base = switch (style) {
      EnemyShipStyle.scout => 3.0,
      EnemyShipStyle.weaver => 2.4,
      EnemyShipStyle.hunter => 1.9,
      EnemyShipStyle.boss => 1.35,
    };
    final scale = max(1.0 - (wave - 1) * 0.04, 0.7);
    return base * scale;
  }

  int hpFor(EnemyShipStyle style) {
    final base = switch (style) {
      EnemyShipStyle.scout => 1,
      EnemyShipStyle.weaver => 2,
      EnemyShipStyle.hunter => 3,
      EnemyShipStyle.boss => 45,
    };
    if (style == EnemyShipStyle.boss) return base + wave * 14;
    return base + (wave ~/ 3);
  }

  EnemyShipStyle rollStyle(Random random) {
    if (wave == 1) return EnemyShipStyle.scout;
    if (wave == 2) {
      return random.nextDouble() < 0.7 ? EnemyShipStyle.scout : EnemyShipStyle.weaver;
    }
    if (wave < 5) {
      return random.nextDouble() < 0.55 ? EnemyShipStyle.scout : EnemyShipStyle.weaver;
    }
    final roll = random.nextDouble();
    if (roll < 0.35) return EnemyShipStyle.scout;
    if (roll < 0.7) return EnemyShipStyle.weaver;
    return EnemyShipStyle.hunter;
  }

  double get powerUpChance => (0.16 + wave * 0.012).clamp(0.16, 0.28);

  double get intermissionSeconds => wave <= 2 ? 3.0 : 2.0;
}
