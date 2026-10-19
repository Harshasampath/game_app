class GameConstants {
  GameConstants._();

  static const int initialLives = 5;
  static const int pointsPerKill = 15;
  static const int bossBonus = 750;
  static const double worldScrollSpeed = 140;
  static const double playerBaseSpeed = 380;
  static const double playerAcceleration = 1100;
  static const double playerDrag = 3.2;
  static const double bulletSpeed = 920;
  static const double enemyBulletSpeed = 250;
  /// Minimum seconds between player shots (tap / rapid-fire).
  static const double tapFireCooldown = 0.22;
  static const double rapidFireCooldown = 0.10;
  static const double hitInvincibility = 2.0;
  static const double playerSize = 56;
  static const double enemySizeSmall = 40;
  static const double enemySizeMedium = 48;
  static const double enemySizeBoss = 96;
  static const double bulletWidth = 18;
  static const double bulletHeight = 6;
  static const double powerUpSize = 30;
  static const double comboWindow = 2.0;
  static const int bossEveryNWaves = 3;

  /// Oldest shots are removed when the screen fills up — keeps fights readable.
  static const int maxEnemyBulletsOnScreen = 22;

  /// Spawn / wave pacing (overridden per wave by [WaveDifficulty])
  static const double enemySpawnInterval = 1.1;
  static const int maxEnemiesOnScreen = 5;
  static const int baseEnemiesPerWave = 4;

  /// Horizontal engagement zone (screen width ratios)
  static const double enemyEngageStartRatio = 0.78;
  static const double enemyHoldMinXRatio = 0.42;
  static const double enemyDespawnX = -100;

  static const double playerMinXRatio = 0.06;
  static const double playerMaxXRatio = 0.38;

  /// Left edge must be this many pixels inside the screen before player weapons hit.
  static const double enemyVulnerableScreenInset = 28;
}
