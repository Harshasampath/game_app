/// Competitive grading — time vs par + combat performance.
enum MissionRank { s, a, b, c }

class MissionCompetition {
  MissionCompetition._();

  static String formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static int timeBonus({required int elapsedSeconds, required int parSeconds}) {
    if (parSeconds <= 0) return 0;
    if (elapsedSeconds <= parSeconds) {
      return ((parSeconds - elapsedSeconds) * 12).clamp(0, 8000);
    }
    return 0;
  }

  static MissionRank calculateRank({
    required int elapsedSeconds,
    required int parSeconds,
    required int stars,
  }) {
    if (parSeconds <= 0) return MissionRank.b;
    final ratio = elapsedSeconds / parSeconds;
    if (stars >= 3 && ratio <= 0.85) return MissionRank.s;
    if (stars >= 2 && ratio <= 1.0) return MissionRank.a;
    if (ratio <= 1.25 || stars >= 2) return MissionRank.b;
    return MissionRank.c;
  }

  static String rankLabel(MissionRank rank) => switch (rank) {
        MissionRank.s => 'S',
        MissionRank.a => 'A',
        MissionRank.b => 'B',
        MissionRank.c => 'C',
      };

  static int rankValue(MissionRank rank) => switch (rank) {
        MissionRank.s => 4,
        MissionRank.a => 3,
        MissionRank.b => 2,
        MissionRank.c => 1,
      };

  static MissionRank? rankFromLabel(String? label) => switch (label) {
        'S' => MissionRank.s,
        'A' => MissionRank.a,
        'B' => MissionRank.b,
        'C' => MissionRank.c,
        _ => null,
      };
}
