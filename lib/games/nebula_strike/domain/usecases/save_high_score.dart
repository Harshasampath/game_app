import '../repositories/score_repository.dart';

class SaveHighScore {
  const SaveHighScore(this._repository);
  final ScoreRepository _repository;
  Future<void> call(int score) => _repository.saveHighScore(score);
}
