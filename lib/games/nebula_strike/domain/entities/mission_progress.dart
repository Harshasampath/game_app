import 'package:equatable/equatable.dart';

import 'game_mission.dart';

/// Saved campaign progress — unlocks, completion, competitive records.
class MissionProgress extends Equatable {
  const MissionProgress({
    this.unlockedMissionIds = const {'m1'},
    this.completedMissionIds = const {},
    this.starsByMission = const {},
    this.bestScoreByMission = const {},
    this.bestTimeByMission = const {},
    this.bestRankByMission = const {},
    this.endlessHighScore = 0,
  });

  final Set<String> unlockedMissionIds;
  final Set<String> completedMissionIds;
  final Map<String, int> starsByMission;
  final Map<String, int> bestScoreByMission;
  final Map<String, int> bestTimeByMission;
  final Map<String, String> bestRankByMission;
  final int endlessHighScore;

  bool isCompleted(String missionId) => completedMissionIds.contains(missionId);

  bool isMissionUnlocked(GameMission mission) => true;

  String? unlockHint(GameMission mission) => null;

  int starsFor(String missionId) => starsByMission[missionId] ?? 0;
  int bestScoreFor(String missionId) => bestScoreByMission[missionId] ?? 0;
  int? bestTimeFor(String missionId) => bestTimeByMission[missionId];
  String? bestRankFor(String missionId) => bestRankByMission[missionId];

  MissionProgress copyWith({
    Set<String>? unlockedMissionIds,
    Set<String>? completedMissionIds,
    Map<String, int>? starsByMission,
    Map<String, int>? bestScoreByMission,
    Map<String, int>? bestTimeByMission,
    Map<String, String>? bestRankByMission,
    int? endlessHighScore,
  }) {
    return MissionProgress(
      unlockedMissionIds: unlockedMissionIds ?? this.unlockedMissionIds,
      completedMissionIds: completedMissionIds ?? this.completedMissionIds,
      starsByMission: starsByMission ?? this.starsByMission,
      bestScoreByMission: bestScoreByMission ?? this.bestScoreByMission,
      bestTimeByMission: bestTimeByMission ?? this.bestTimeByMission,
      bestRankByMission: bestRankByMission ?? this.bestRankByMission,
      endlessHighScore: endlessHighScore ?? this.endlessHighScore,
    );
  }

  @override
  List<Object?> get props => [
        unlockedMissionIds,
        completedMissionIds,
        starsByMission,
        bestScoreByMission,
        bestTimeByMission,
        bestRankByMission,
        endlessHighScore,
      ];
}
