import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mission_progress_local_data_source.dart';
import '../../data/repositories/mission_progress_repository_impl.dart';
import '../../domain/entities/game_mission.dart';
import '../../domain/entities/mission_progress.dart';
import '../../domain/entities/mission_rank.dart';
import 'dependency_providers.dart';

final missionProgressLocalDataSourceProvider =
    Provider<MissionProgressLocalDataSource>((ref) {
  return MissionProgressLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

final missionProgressRepositoryProvider = Provider<MissionProgressRepository>((ref) {
  return MissionProgressRepositoryImpl(ref.watch(missionProgressLocalDataSourceProvider));
});

final missionProgressProvider =
    StateNotifierProvider<MissionProgressNotifier, AsyncValue<MissionProgress>>((ref) {
  return MissionProgressNotifier(ref.watch(missionProgressRepositoryProvider));
});

class MissionProgressNotifier extends StateNotifier<AsyncValue<MissionProgress>> {
  MissionProgressNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final MissionProgressRepository _repo;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _repo.load());
  }

  Future<void> recordComplete({
    required GameMission mission,
    required int score,
    required int stars,
    required int elapsedSeconds,
    required MissionRank rank,
  }) async {
    await _repo.recordMissionComplete(
      missionId: mission.id,
      score: score,
      stars: stars,
      missionOrder: mission.order,
      elapsedSeconds: elapsedSeconds,
      rank: rank,
    );
    state = AsyncValue.data(await _repo.load());
  }

  Future<void> recordEndless(int score) async {
    await _repo.recordEndlessScore(score);
    state = AsyncValue.data(await _repo.load());
  }

  Future<void> refresh() => _load();
}
