abstract class ScoreRepository {
  Future<int> getHighScore();
  Future<void> saveHighScore(int score);
  Future<String> getSelectedShip();
  Future<void> saveSelectedShip(String ship);
}
