import 'package:equatable/equatable.dart';

/// One act inside a mission — each phase has its own objective and enemy mix.
class MissionPhase extends Equatable {
  const MissionPhase({
    required this.name,
    required this.objective,
    required this.killTarget,
    this.maxOnScreen = 3,
    this.spawnInterval = 0.82,
    this.enemyBulletSpeed = 220,
    this.scoutWeight = 0.6,
    this.weaverWeight = 0.3,
    this.hunterWeight = 0.1,
    this.shootIntervalScale = 1.0,
    this.hpBonus = 0,
    this.bossOnly = false,
  });

  final String name;
  final String objective;
  final int killTarget;
  final int maxOnScreen;
  final double spawnInterval;
  final double enemyBulletSpeed;
  final double scoutWeight;
  final double weaverWeight;
  final double hunterWeight;
  final double shootIntervalScale;
  final int hpBonus;
  final bool bossOnly;

  @override
  List<Object?> get props => [
        name,
        objective,
        killTarget,
        maxOnScreen,
        spawnInterval,
        enemyBulletSpeed,
        scoutWeight,
        weaverWeight,
        hunterWeight,
        shootIntervalScale,
        hpBonus,
        bossOnly,
      ];
}
