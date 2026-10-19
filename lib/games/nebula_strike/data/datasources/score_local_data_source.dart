import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/ship_type.dart';

abstract class ScoreLocalDataSource {
  Future<int> getHighScore();
  Future<void> saveHighScore(int score);
  Future<String> getSelectedShip();
  Future<void> saveSelectedShip(String ship);
}

class ScoreLocalDataSourceImpl implements ScoreLocalDataSource {
  ScoreLocalDataSourceImpl(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<int> getHighScore() async {
    try {
      return _prefs.getInt(StorageKeys.highScore) ?? 0;
    } catch (_) {
      throw const CacheFailure();
    }
  }

  @override
  Future<void> saveHighScore(int score) async {
    try {
      await _prefs.setInt(StorageKeys.highScore, score);
    } catch (_) {
      throw const CacheFailure();
    }
  }

  @override
  Future<String> getSelectedShip() async {
    return _prefs.getString(StorageKeys.selectedShip) ?? ShipType.interceptor.name;
  }

  @override
  Future<void> saveSelectedShip(String ship) async {
    await _prefs.setString(StorageKeys.selectedShip, ship);
  }
}
