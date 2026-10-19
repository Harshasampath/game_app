import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/score_local_data_source.dart';
import '../../data/repositories/score_repository_impl.dart';
import '../../domain/entities/ship_type.dart';
import '../../domain/repositories/score_repository.dart';
import '../../domain/usecases/get_high_score.dart';
import '../../domain/usecases/save_high_score.dart';
import 'provider_scheduling.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final scoreLocalDataSourceProvider = Provider<ScoreLocalDataSource>((ref) {
  return ScoreLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepositoryImpl(ref.watch(scoreLocalDataSourceProvider));
});

final getHighScoreProvider = Provider<GetHighScore>((ref) {
  return GetHighScore(ref.watch(scoreRepositoryProvider));
});

final saveHighScoreProvider = Provider<SaveHighScore>((ref) {
  return SaveHighScore(ref.watch(scoreRepositoryProvider));
});

final selectedShipProvider =
    StateNotifierProvider<SelectedShipNotifier, ShipType>((ref) {
  return SelectedShipNotifier(ref.watch(scoreRepositoryProvider));
});

class SelectedShipNotifier extends StateNotifier<ShipType> {
  SelectedShipNotifier(this._repo) : super(ShipType.interceptor) {
    _load();
  }

  final ScoreRepository _repo;

  Future<void> _load() async {
    final name = await _repo.getSelectedShip();
    deferProviderWrite(() => state = ShipType.values.byName(name));
  }

  Future<void> select(ShipType ship) async {
    state = ship;
    await _repo.saveSelectedShip(ship.name);
  }
}
