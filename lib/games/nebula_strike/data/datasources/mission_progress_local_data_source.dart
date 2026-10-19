import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../domain/entities/mission_progress.dart';

abstract class MissionProgressLocalDataSource {
  Future<MissionProgress> load();
  Future<void> save(MissionProgress progress);
}

class MissionProgressLocalDataSourceImpl implements MissionProgressLocalDataSource {
  MissionProgressLocalDataSourceImpl(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<MissionProgress> load() async {
    final raw = _prefs.getString(StorageKeys.missionProgress);
    if (raw == null) return const MissionProgress();

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return MissionProgress(
        unlockedMissionIds: (map['unlocked'] as List<dynamic>? ?? ['m1'])
            .map((e) => e.toString())
            .toSet(),
        completedMissionIds: (map['completed'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toSet(),
        starsByMission: (map['stars'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        bestScoreByMission: (map['scores'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        bestTimeByMission: (map['times'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        bestRankByMission: (map['ranks'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
        endlessHighScore: (map['endless'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const MissionProgress();
    }
  }

  @override
  Future<void> save(MissionProgress progress) async {
    final map = {
      'unlocked': progress.unlockedMissionIds.toList(),
      'completed': progress.completedMissionIds.toList(),
      'stars': progress.starsByMission,
      'scores': progress.bestScoreByMission,
      'times': progress.bestTimeByMission,
      'ranks': progress.bestRankByMission,
      'endless': progress.endlessHighScore,
    };
    await _prefs.setString(StorageKeys.missionProgress, jsonEncode(map));
  }
}
