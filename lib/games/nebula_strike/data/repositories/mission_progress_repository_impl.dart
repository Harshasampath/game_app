import '../../domain/entities/mission_catalog.dart';
import '../../domain/entities/mission_progress.dart';
import '../../domain/entities/mission_rank.dart';
import '../datasources/mission_progress_local_data_source.dart';

abstract class MissionProgressRepository {
  Future<MissionProgress> load();
  Future<void> recordMissionComplete({
    required String missionId,
    required int score,
    required int stars,
    required int missionOrder,
    required int elapsedSeconds,
    required MissionRank rank,
  });
  Future<void> recordEndlessScore(int score);
}

class MissionProgressRepositoryImpl implements MissionProgressRepository {
  MissionProgressRepositoryImpl(this._local);

  final MissionProgressLocalDataSource _local;

  @override
  Future<MissionProgress> load() => _local.load();

  @override
  Future<void> recordMissionComplete({
    required String missionId,
    required int score,
    required int stars,
    required int missionOrder,
    required int elapsedSeconds,
    required MissionRank rank,
  }) async {
    final current = await _local.load();
    final unlocked = Set<String>.from(current.unlockedMissionIds)
      ..add(missionId);
    final completed = Set<String>.from(current.completedMissionIds)
      ..add(missionId);

    for (final mission in MissionCatalog.all) {
      if (mission.unlockAfterOrder == missionOrder) {
        unlocked.add(mission.id);
      }
    }

    final starsMap = Map<String, int>.from(current.starsByMission);
    final prevStars = starsMap[missionId] ?? 0;
    if (stars > prevStars) starsMap[missionId] = stars;

    final scores = Map<String, int>.from(current.bestScoreByMission);
    if (score > (scores[missionId] ?? 0)) scores[missionId] = score;

    final times = Map<String, int>.from(current.bestTimeByMission);
    final prevTime = times[missionId];
    if (prevTime == null || elapsedSeconds < prevTime) {
      times[missionId] = elapsedSeconds;
    }

    final ranks = Map<String, String>.from(current.bestRankByMission);
    final prevRank = MissionCompetition.rankFromLabel(ranks[missionId]);
    if (prevRank == null ||
        MissionCompetition.rankValue(rank) > MissionCompetition.rankValue(prevRank)) {
      ranks[missionId] = MissionCompetition.rankLabel(rank);
    }

    await _local.save(current.copyWith(
      unlockedMissionIds: unlocked,
      completedMissionIds: completed,
      starsByMission: starsMap,
      bestScoreByMission: scores,
      bestTimeByMission: times,
      bestRankByMission: ranks,
    ));
  }

  @override
  Future<void> recordEndlessScore(int score) async {
    final current = await _local.load();
    if (score <= current.endlessHighScore) return;
    await _local.save(current.copyWith(endlessHighScore: score));
  }
}
