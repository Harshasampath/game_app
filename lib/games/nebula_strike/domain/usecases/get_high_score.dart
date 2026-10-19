import '../repositories/score_repository.dart';

class GetHighScore {
  const GetHighScore(this._repository);
  final ScoreRepository _repository;
  Future<int> call() => _repository.getHighScore();
}
