import 'package:equatable/equatable.dart';

import '../../core/constants/game_constants.dart';
import 'mission_rank.dart';

enum GameStatus { playing, paused, gameOver, missionComplete }

enum PowerUpType { rapidFire, spreadShot, shield }

class GameSession extends Equatable {
  const GameSession({
    required this.score,
    required this.lives,
    required this.status,
    required this.highScore,
    required this.combo,
    required this.comboMultiplier,
    required this.missionId,
    required this.missionTitle,
    required this.missionSector,
    required this.phaseIndex,
    required this.totalPhases,
    required this.phaseName,
    required this.phaseObjective,
    required this.killsInPhase,
    required this.phaseKillTarget,
    required this.isEndless,
    required this.livesAtStart,
    required this.missionElapsedSeconds,
    required this.parTimeSeconds,
    this.shieldActive = false,
    this.rapidFireActive = false,
    this.spreadShotActive = false,
    this.missionStars = 0,
    this.endlessWave = 1,
    this.timeBonus = 0,
    this.missionRank,
    this.isPersonalBestTime = false,
  });

  final int score;
  final int lives;
  final GameStatus status;
  final int highScore;
  final int combo;
  final int comboMultiplier;
  final String missionId;
  final String missionTitle;
  final String missionSector;
  final int phaseIndex;
  final int totalPhases;
  final String phaseName;
  final String phaseObjective;
  final int killsInPhase;
  final int phaseKillTarget;
  final bool isEndless;
  final int livesAtStart;
  final int missionElapsedSeconds;
  final int parTimeSeconds;
  final bool shieldActive;
  final bool rapidFireActive;
  final bool spreadShotActive;
  final int missionStars;
  final int endlessWave;
  final int timeBonus;
  final MissionRank? missionRank;
  final bool isPersonalBestTime;

  bool get isGameOver => status == GameStatus.gameOver;
  bool get isMissionComplete => status == GameStatus.missionComplete;

  bool get isUnderPar =>
      parTimeSeconds > 0 && missionElapsedSeconds <= parTimeSeconds;

  double get phaseProgress =>
      phaseKillTarget <= 0 ? 0 : (killsInPhase / phaseKillTarget).clamp(0.0, 1.0);

  factory GameSession.initial({int highScore = 0}) => GameSession(
        score: 0,
        lives: GameConstants.initialLives,
        status: GameStatus.playing,
        highScore: highScore,
        combo: 0,
        comboMultiplier: 1,
        missionId: '',
        missionTitle: '',
        missionSector: '',
        phaseIndex: 1,
        totalPhases: 1,
        phaseName: '',
        phaseObjective: '',
        killsInPhase: 0,
        phaseKillTarget: 1,
        isEndless: false,
        livesAtStart: GameConstants.initialLives,
        missionElapsedSeconds: 0,
        parTimeSeconds: 0,
      );

  GameSession copyWith({
    int? score,
    int? lives,
    GameStatus? status,
    int? highScore,
    int? combo,
    int? comboMultiplier,
    String? missionId,
    String? missionTitle,
    String? missionSector,
    int? phaseIndex,
    int? totalPhases,
    String? phaseName,
    String? phaseObjective,
    int? killsInPhase,
    int? phaseKillTarget,
    bool? isEndless,
    int? livesAtStart,
    int? missionElapsedSeconds,
    int? parTimeSeconds,
    bool? shieldActive,
    bool? rapidFireActive,
    bool? spreadShotActive,
    int? missionStars,
    int? endlessWave,
    int? timeBonus,
    MissionRank? missionRank,
    bool? isPersonalBestTime,
  }) {
    return GameSession(
      score: score ?? this.score,
      lives: lives ?? this.lives,
      status: status ?? this.status,
      highScore: highScore ?? this.highScore,
      combo: combo ?? this.combo,
      comboMultiplier: comboMultiplier ?? this.comboMultiplier,
      missionId: missionId ?? this.missionId,
      missionTitle: missionTitle ?? this.missionTitle,
      missionSector: missionSector ?? this.missionSector,
      phaseIndex: phaseIndex ?? this.phaseIndex,
      totalPhases: totalPhases ?? this.totalPhases,
      phaseName: phaseName ?? this.phaseName,
      phaseObjective: phaseObjective ?? this.phaseObjective,
      killsInPhase: killsInPhase ?? this.killsInPhase,
      phaseKillTarget: phaseKillTarget ?? this.phaseKillTarget,
      isEndless: isEndless ?? this.isEndless,
      livesAtStart: livesAtStart ?? this.livesAtStart,
      missionElapsedSeconds: missionElapsedSeconds ?? this.missionElapsedSeconds,
      parTimeSeconds: parTimeSeconds ?? this.parTimeSeconds,
      shieldActive: shieldActive ?? this.shieldActive,
      rapidFireActive: rapidFireActive ?? this.rapidFireActive,
      spreadShotActive: spreadShotActive ?? this.spreadShotActive,
      missionStars: missionStars ?? this.missionStars,
      endlessWave: endlessWave ?? this.endlessWave,
      timeBonus: timeBonus ?? this.timeBonus,
      missionRank: missionRank ?? this.missionRank,
      isPersonalBestTime: isPersonalBestTime ?? this.isPersonalBestTime,
    );
  }

  @override
  List<Object?> get props => [
        score,
        lives,
        status,
        highScore,
        combo,
        comboMultiplier,
        missionId,
        missionTitle,
        missionSector,
        phaseIndex,
        totalPhases,
        phaseName,
        phaseObjective,
        killsInPhase,
        phaseKillTarget,
        isEndless,
        livesAtStart,
        missionElapsedSeconds,
        parTimeSeconds,
        shieldActive,
        rapidFireActive,
        spreadShotActive,
        missionStars,
        endlessWave,
        timeBonus,
        missionRank,
        isPersonalBestTime,
      ];
}
