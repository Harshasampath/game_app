import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

import '../../domain/entities/mission_rank.dart';
import 'animated_result_banner.dart';
import 'victory_celebration.dart';

class MissionCompleteOverlay extends StatelessWidget {
  const MissionCompleteOverlay({
    super.key,
    required this.missionTitle,
    required this.score,
    required this.stars,
    required this.elapsedSeconds,
    required this.parSeconds,
    required this.timeBonus,
    required this.rank,
    required this.isPersonalBest,
    required this.onNextMission,
    required this.onReplay,
    required this.onHome,
  });

  final String missionTitle;
  final int score;
  final int stars;
  final int elapsedSeconds;
  final int parSeconds;
  final int timeBonus;
  final MissionRank? rank;
  final bool isPersonalBest;
  final VoidCallback onNextMission;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  Color _rankColor(MissionRank r) => switch (r) {
        MissionRank.s => const Color(0xFFFFD43B),
        MissionRank.a => const Color(0xFF4ADE80),
        MissionRank.b => const Color(0xFF74C0FC),
        MissionRank.c => const Color(0xFF94A3B8),
      };

  @override
  Widget build(BuildContext context) {
    final elapsed = MissionCompetition.formatTime(elapsedSeconds);
    final par = parSeconds > 0 ? MissionCompetition.formatTime(parSeconds) : null;
    final underPar = parSeconds > 0 && elapsedSeconds <= parSeconds;

    return AnimatedResultBackdrop(
      isVictory: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 380;
          final wide = constraints.maxWidth > 520;
          final cardMaxWidth = math.min(constraints.maxWidth * 0.94, 500.0);
          final padding = compact ? 14.0 : 20.0;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: cardMaxWidth,
                maxHeight: constraints.maxHeight * 0.96,
              ),
              child: Card(
                color: const Color(0xFF1E2740).withValues(alpha: 0.96),
                margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AnimatedVictoryTrophy(),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const AnimatedResultBanner(
                            message: 'YOU WIN!',
                            isVictory: true,
                            accentColor: Color(0xFF4ADE80),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'MISSION COMPLETE',
                          style: AppTypography.orbitron(
                            color: Colors.white54,
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          missionTitle,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: compact ? 12 : 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: compact ? 10 : 14),
                        if (wide && rank != null)
                          _wideRankRow(rank!, stars, compact)
                        else ...[
                          if (rank != null) _rankBadge(rank!, compact),
                          SizedBox(height: compact ? 8 : 12),
                          AnimatedVictoryStars(stars: stars),
                        ],
                        SizedBox(height: compact ? 10 : 14),
                        _statsBlock(
                          elapsed: elapsed,
                          par: par,
                          underPar: underPar,
                          timeBonus: timeBonus,
                          score: score,
                          isPersonalBest: isPersonalBest,
                          compact: compact,
                          wide: wide,
                        ),
                        SizedBox(height: compact ? 12 : 16),
                        _actions(compact: compact, wide: wide),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wideRankRow(MissionRank rank, int stars, bool compact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _rankBadge(rank, compact),
        const SizedBox(width: 20),
        AnimatedVictoryStars(stars: stars),
      ],
    );
  }

  Widget _rankBadge(MissionRank rank, bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _rankColor(rank), width: 3),
        color: _rankColor(rank).withValues(alpha: 0.15),
      ),
      child: Text(
        MissionCompetition.rankLabel(rank),
        style: AppTypography.orbitron(
          color: _rankColor(rank),
          fontSize: compact ? 28 : 32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _statsBlock({
    required String elapsed,
    required String? par,
    required bool underPar,
    required int timeBonus,
    required int score,
    required bool isPersonalBest,
    required bool compact,
    required bool wide,
  }) {
    final stats = <Widget>[
      _statRow('Time', elapsed, underPar ? const Color(0xFF4ADE80) : null, compact),
      if (par != null) _statRow('Par', par, null, compact),
      if (timeBonus > 0)
        _statRow('Time bonus', '+$timeBonus', const Color(0xFF4ADE80), compact),
    ];

    return Column(
      children: [
        if (wide && stats.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: stats
                .map((s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: s,
                    ))
                .toList(),
          )
        else
          ...stats,
        Divider(height: compact ? 16 : 20, color: Colors.white24),
        Text(
          'Final score: $score',
          style: AppTypography.orbitron(
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF38BDF8),
          ),
        ),
        if (isPersonalBest) ...[
          const SizedBox(height: 6),
          Text(
            'NEW PERSONAL BEST TIME',
            style: AppTypography.orbitron(
              color: const Color(0xFFFFD43B),
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _actions({required bool compact, required bool wide}) {
    if (wide) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          ElevatedButton.icon(
            onPressed: onNextMission,
            icon: const Icon(Icons.map, size: 18),
            label: const Text('MISSIONS'),
          ),
          OutlinedButton.icon(
            onPressed: onReplay,
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('REPLAY'),
          ),
          TextButton(onPressed: onHome, child: const Text('HANGAR')),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onNextMission,
            icon: const Icon(Icons.map),
            label: Text(compact ? 'MISSIONS' : 'MISSION SELECT'),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReplay,
            icon: const Icon(Icons.replay),
            label: Text(compact ? 'REPLAY' : 'REPLAY MISSION'),
          ),
        ),
        TextButton(onPressed: onHome, child: const Text('HANGAR')),
      ],
    );
  }

  Widget _statRow(String label, String value, Color? valueColor, bool compact) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white54,
              fontSize: compact ? 12 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
