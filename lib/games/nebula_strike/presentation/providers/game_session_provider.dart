import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../domain/entities/game_mission.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/mission_catalog.dart';
import '../../domain/entities/mission_rank.dart';
import '../../domain/usecases/save_high_score.dart';
import 'dependency_providers.dart';
import 'mission_progress_provider.dart';
import 'provider_scheduling.dart';

class GameSessionNotifier extends StateNotifier<GameSession> {
  GameSessionNotifier(this._saveHighScore, this._ref, {int initialHighScore = 0})
      : super(GameSession.initial(highScore: initialHighScore));

  final SaveHighScore _saveHighScore;
  final Ref _ref;
  double _lastKillTime = 0;
  double _missionElapsed = 0;

  void startMission(GameMission mission, {required int highScore}) {
    _lastKillTime = 0;
    _missionElapsed = 0;
    final phase = mission.phaseAt(0);
    final killTarget = mission.isEndless ? 12 : phase.killTarget;
    state = GameSession(
      score: 0,
      lives: GameConstants.initialLives,
      status: GameStatus.playing,
      highScore: highScore,
      combo: 0,
      comboMultiplier: 1,
      missionId: mission.id,
      missionTitle: mission.title,
      missionSector: mission.sector,
      phaseIndex: 1,
      totalPhases: mission.totalPhases,
      phaseName: phase.name,
      phaseObjective: phase.objective,
      killsInPhase: 0,
      phaseKillTarget: killTarget,
      isEndless: mission.isEndless,
      livesAtStart: GameConstants.initialLives,
      missionElapsedSeconds: 0,
      parTimeSeconds: mission.parTimeSeconds,
      timeBonus: 0,
      missionRank: null,
      isPersonalBestTime: false,
    );
  }

  void tickMissionTime(double dt) {
    if (state.status != GameStatus.playing || state.isEndless) return;
    _missionElapsed += dt;
    final secs = _missionElapsed.floor();
    if (secs != state.missionElapsedSeconds) {
      state = state.copyWith(missionElapsedSeconds: secs);
    }
  }

  void registerKill(int points, double gameTime) {
    if (state.isGameOver || state.isMissionComplete) return;

    var combo = state.combo;
    var multiplier = state.comboMultiplier;

    if (gameTime - _lastKillTime <= GameConstants.comboWindow) {
      combo++;
      multiplier = (1 + combo ~/ 5).clamp(1, 5);
    } else {
      combo = 1;
      multiplier = 1;
    }
    _lastKillTime = gameTime;

    state = state.copyWith(
      score: state.score + points * multiplier,
      combo: combo,
      comboMultiplier: multiplier,
      killsInPhase: state.killsInPhase + 1,
    );
  }

  void advancePhase({
    required String phaseName,
    required String phaseObjective,
    required int phaseKillTarget,
    required int phaseIndex,
  }) {
    state = state.copyWith(
      phaseIndex: phaseIndex,
      phaseName: phaseName,
      phaseObjective: phaseObjective,
      phaseKillTarget: phaseKillTarget,
      killsInPhase: 0,
    );
  }

  void advanceEndlessWave() {
    state = state.copyWith(
      endlessWave: state.endlessWave + 1,
      killsInPhase: 0,
      phaseKillTarget: 12 + state.endlessWave * 2,
    );
  }

  int calculateStars() {
    final livesLost = state.livesAtStart - state.lives;
    if (livesLost <= 0) return 3;
    if (livesLost <= 2) return 2;
    return 1;
  }

  Future<void> completeMission() async {
    final stars = calculateStars();
    final mission = MissionCatalog.byId(state.missionId);
    final elapsed = state.missionElapsedSeconds;
    final par = state.parTimeSeconds;

    var finalScore = state.score;
    var timeBonus = 0;
    MissionRank? rank;
    var isNewBest = false;

    if (mission != null && !mission.isEndless) {
      timeBonus = MissionCompetition.timeBonus(
        elapsedSeconds: elapsed,
        parSeconds: par,
      );
      rank = MissionCompetition.calculateRank(
        elapsedSeconds: elapsed,
        parSeconds: par,
        stars: stars,
      );
      finalScore = state.score + timeBonus;

      final progress = _ref.read(missionProgressProvider).valueOrNull;
      final prevBest = progress?.bestTimeFor(mission.id);
      isNewBest = prevBest == null || elapsed < prevBest;

      await _ref.read(missionProgressProvider.notifier).recordComplete(
            mission: mission,
            score: finalScore,
            stars: stars,
            elapsedSeconds: elapsed,
            rank: rank,
          );
    }

    if (finalScore > state.highScore) {
      await _saveHighScore(finalScore);
    }

    deferProviderWrite(() {
      state = state.copyWith(
        status: GameStatus.missionComplete,
        missionStars: stars,
        score: finalScore,
        timeBonus: timeBonus,
        missionRank: rank,
        isPersonalBestTime: isNewBest,
        highScore: finalScore > state.highScore ? finalScore : state.highScore,
      );
    });
  }

  void loseLife() {
    if (state.isGameOver || state.isMissionComplete) return;
    if (state.shieldActive) {
      state = state.copyWith(shieldActive: false);
      return;
    }
    final newLives = state.lives - 1;
    if (newLives <= 0) {
      _endGame();
    } else {
      state = state.copyWith(lives: newLives, combo: 0, comboMultiplier: 1);
    }
  }

  void activatePowerUp(PowerUpType type) {
    if (state.isGameOver || state.isMissionComplete) return;
    state = switch (type) {
      PowerUpType.rapidFire => state.copyWith(rapidFireActive: true),
      PowerUpType.spreadShot => state.copyWith(spreadShotActive: true),
      PowerUpType.shield => state.copyWith(shieldActive: true),
    };
  }

  void clearPowerUps() {
    state = state.copyWith(
      rapidFireActive: false,
      spreadShotActive: false,
    );
  }

  void pause() {
    if (!state.isGameOver && !state.isMissionComplete) {
      state = state.copyWith(status: GameStatus.paused);
    }
  }

  void resume() {
    if (state.status == GameStatus.paused) {
      state = state.copyWith(status: GameStatus.playing);
    }
  }

  void reset({int? highScore}) {
    _lastKillTime = 0;
    _missionElapsed = 0;
    state = GameSession.initial(highScore: highScore ?? state.highScore);
  }

  Future<void> _endGame() async {
    if (state.isEndless) {
      await _ref.read(missionProgressProvider.notifier).recordEndless(state.score);
    }
    final isNew = state.score > state.highScore;
    final score = state.score;
    final highScore = state.highScore;
    if (isNew) await _saveHighScore(score);
    deferProviderWrite(() {
      state = state.copyWith(
        status: GameStatus.gameOver,
        highScore: isNew ? score : highScore,
      );
    });
  }
}

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSession>((ref) {
  return GameSessionNotifier(
    ref.watch(saveHighScoreProvider),
    ref,
  );
});

final highScoreProvider = FutureProvider<int>((ref) async {
  return ref.watch(getHighScoreProvider)();
});

final activeMissionProvider = StateProvider<GameMission?>((ref) => null);
