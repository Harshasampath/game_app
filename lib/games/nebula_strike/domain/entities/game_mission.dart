import 'package:equatable/equatable.dart';

import 'mission_phase.dart';

/// A playable mission with multiple phases — the modern "level" structure.
class GameMission extends Equatable {
  const GameMission({
    required this.id,
    required this.order,
    required this.title,
    required this.sector,
    required this.briefing,
    required this.phases,
    required this.parTimeSeconds,
    this.unlockAfterOrder = 0,
    this.estimatedMinutes = 8,
    this.isEndless = false,
  });

  final String id;
  final int order;
  final String title;
  final String sector;
  final String briefing;
  final List<MissionPhase> phases;
  final int parTimeSeconds;
  final int unlockAfterOrder;
  final int estimatedMinutes;
  final bool isEndless;

  int get totalPhases => phases.length;

  int get totalKills => phases.fold(0, (sum, p) => sum + p.killTarget);

  MissionPhase phaseAt(int index) => phases[index.clamp(0, phases.length - 1)];

  @override
  List<Object?> get props => [
        id,
        order,
        title,
        sector,
        briefing,
        phases,
        parTimeSeconds,
        unlockAfterOrder,
        isEndless,
      ];
}
