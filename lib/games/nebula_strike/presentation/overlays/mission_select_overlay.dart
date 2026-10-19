import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_typography.dart';

import '../../domain/entities/game_mission.dart';
import '../../domain/entities/mission_catalog.dart';
import '../../domain/entities/mission_progress.dart';
import '../../domain/entities/mission_rank.dart';
import '../../game/audio/game_audio.dart';
import '../../game/nebula_strike_game.dart';
import '../providers/mission_progress_provider.dart';
import '../widgets/app_safe_area.dart';

class MissionSelectOverlay extends ConsumerWidget {
  const MissionSelectOverlay({super.key, required this.game});

  final NebulaStrikeGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(missionProgressProvider);

    return ColoredBox(
      color: const Color(0xE6060A14),
      child: AppSafeArea(
        child: SizedBox.expand(
          child: progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Failed to load missions')),
            data: (progress) => _MissionList(game: game, progress: progress),
          ),
        ),
      ),
    );
  }
}

class _MissionList extends ConsumerWidget {
  const _MissionList({required this.game, required this.progress});

  final NebulaStrikeGame game;
  final MissionProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = MissionCatalog.all;
    final completedCount = progress.completedMissionIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  GameAudio.unlock();
                  GameAudio.uiConfirm();
                  game.showHangar();
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT MISSION',
                      style: AppTypography.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: const Color(0xFF74C0FC),
                      ),
                    ),
                    Text(
                      'All missions open · chase par times and ranks',
                      style: AppTypography.orbitron(
                        fontSize: 10,
                        color: Colors.white54,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$completedCount/${MissionCatalog.campaign.length}',
                style: AppTypography.orbitron(
                  color: const Color(0xFF4ADE80),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final mission = missions[index];
              return _MissionCard(
                mission: mission,
                completed: progress.isCompleted(mission.id),
                stars: progress.starsFor(mission.id),
                bestScore: progress.bestScoreFor(mission.id),
                bestTime: progress.bestTimeFor(mission.id),
                bestRank: progress.bestRankFor(mission.id),
                endlessBest: mission.isEndless ? progress.endlessHighScore : null,
                onPlay: () async {
                  GameAudio.unlock();
                  GameAudio.uiConfirm();
                  await game.startMission(mission);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.completed,
    required this.stars,
    required this.bestScore,
    required this.onPlay,
    this.bestTime,
    this.bestRank,
    this.endlessBest,
  });

  final GameMission mission;
  final bool completed;
  final int stars;
  final int bestScore;
  final int? bestTime;
  final String? bestRank;
  final int? endlessBest;
  final VoidCallback onPlay;

  Color _rankColor(String rank) => switch (rank) {
        'S' => const Color(0xFFFFD43B),
        'A' => const Color(0xFF4ADE80),
        'B' => const Color(0xFF74C0FC),
        _ => const Color(0xFF94A3B8),
      };

  @override
  Widget build(BuildContext context) {
    final accent = mission.isEndless ? const Color(0xFFF97316) : const Color(0xFF74C0FC);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF1E2740).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: completed
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.5)
                    : accent.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: completed
                        ? const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 24)
                        : Text(
                            mission.isEndless ? '∞' : '${mission.order}',
                            style: AppTypography.orbitron(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: mission.isEndless ? 22 : 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mission.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (completed && !mission.isEndless)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CLEARED',
                                style: AppTypography.orbitron(
                                  fontSize: 8,
                                  color: const Color(0xFF4ADE80),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        mission.sector,
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.85),
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.briefing,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (mission.isEndless)
                        Text(
                          'High score: ${endlessBest ?? 0}',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        )
                      else ...[
                        Text(
                          '${mission.totalPhases} phases · ~${mission.estimatedMinutes} min · par ${MissionCompetition.formatTime(mission.parTimeSeconds)}',
                          style: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                        if (completed && bestTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                if (bestRank != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _rankColor(bestRank!)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      bestRank!,
                                      style: AppTypography.orbitron(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: _rankColor(bestRank!),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  'Best ${MissionCompetition.formatTime(bestTime!)} · $bestScore pts',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (!mission.isEndless)
                      Row(
                        children: List.generate(
                          3,
                          (i) => Icon(
                            i < stars ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFD43B),
                            size: 16,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Icon(
                      completed ? Icons.replay_circle_filled : Icons.play_circle_fill,
                      color: accent,
                      size: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
