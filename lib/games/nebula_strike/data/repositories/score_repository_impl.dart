import '../../domain/repositories/score_repository.dart';
import '../datasources/score_local_data_source.dart';

class ScoreRepositoryImpl implements ScoreRepository {
  ScoreRepositoryImpl(this._local);
  final ScoreLocalDataSource _local;

  @override
  Future<int> getHighScore() => _local.getHighScore();

  @override
  Future<void> saveHighScore(int score) => _local.saveHighScore(score);

  @override
  Future<String> getSelectedShip() => _local.getSelectedShip();

  @override
  Future<void> saveSelectedShip(String ship) => _local.saveSelectedShip(ship);
}
