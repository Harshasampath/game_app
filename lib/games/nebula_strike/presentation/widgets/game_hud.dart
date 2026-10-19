import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

import '../../domain/entities/game_session.dart';
import '../../domain/entities/mission_rank.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.session,
    required this.onPause,
  });

  final GameSession session;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.orbitron(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: const Color(0xFF94A3B8),
    );
    final valueStyle = AppTypography.orbitron(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: Colors.white,
    );

    final phaseLabel = session.isEndless
        ? 'WAVE ${session.endlessWave}'
        : 'PHASE ${session.phaseIndex}/${session.totalPhases}';

    final elapsed = MissionCompetition.formatTime(session.missionElapsedSeconds);
    final par = session.parTimeSeconds > 0
        ? MissionCompetition.formatTime(session.parTimeSeconds)
        : null;
    final timerColor = session.isUnderPar
        ? const Color(0xFF4ADE80)
        : session.parTimeSeconds > 0 &&
                session.missionElapsedSeconds > session.parTimeSeconds
            ? const Color(0xFFF87171)
            : const Color(0xFFFBBF24);

    return LayoutBuilder(
      builder: (context, constraints) {
        final portrait = constraints.maxWidth < constraints.maxHeight;
        final hud = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: portrait ? 8 : 16,
            vertical: portrait ? 6 : 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHudRow(
                labelStyle: labelStyle,
                valueStyle: valueStyle,
                phaseLabel: phaseLabel,
                elapsed: elapsed,
                par: par,
                timerColor: timerColor,
                compact: portrait,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: session.phaseProgress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF1E293B),
                  color: const Color(0xFF38BDF8),
                ),
              ),
              if (session.combo > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _HudPanel(
                    accent: const Color(0xFFF97316),
                    child: Text(
                      'COMBO ×${session.comboMultiplier}',
                      style: AppTypography.orbitron(
                        color: const Color(0xFFFBBF24),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              if (session.shieldActive || session.rapidFireActive || session.spreadShotActive)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (session.shieldActive) _powerBadge('SHIELD', const Color(0xFF4ADE80)),
                      if (session.rapidFireActive) _powerBadge('RAPID', const Color(0xFFF97316)),
                      if (session.spreadShotActive) _powerBadge('SPREAD', const Color(0xFFC084FC)),
                    ],
                  ),
                ),
            ],
          ),
        );

        if (portrait) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: hud,
            ),
          );
        }
        return hud;
      },
    );
  }

  Widget _buildHudRow({
    required TextStyle labelStyle,
    required TextStyle valueStyle,
    required String phaseLabel,
    required String elapsed,
    required String? par,
    required Color timerColor,
    required bool compact,
  }) {
    return Row(
      children: [
        _HudPanel(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: const Color(0xFF38BDF8), size: compact ? 16 : 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SCORE', style: labelStyle),
                  Text(
                    session.score.toString().padLeft(6, '0'),
                    style: valueStyle.copyWith(
                      color: const Color(0xFF38BDF8),
                      fontSize: compact ? 13 : 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!session.isEndless && session.parTimeSeconds > 0) ...[
          const SizedBox(width: 8),
          _HudPanel(
            accent: timerColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TIME', style: labelStyle),
                Text(
                  elapsed,
                  style: valueStyle.copyWith(color: timerColor, fontSize: compact ? 12 : 14),
                ),
                if (par != null)
                  Text('PAR $par', style: labelStyle.copyWith(fontSize: 8)),
              ],
            ),
          ),
        ],
        if (compact)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 140),
            child: _HudPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.missionTitle.toUpperCase(), style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(phaseLabel, style: valueStyle.copyWith(color: const Color(0xFFC084FC), fontSize: 13)),
                  Text(
                    session.phaseObjective,
                    style: labelStyle.copyWith(fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: _HudPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.missionTitle.toUpperCase(), style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(phaseLabel, style: valueStyle.copyWith(color: const Color(0xFFC084FC), fontSize: 15)),
                  Text(
                    session.phaseObjective,
                    style: labelStyle.copyWith(fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        _HudPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TARGET', style: labelStyle),
              Text(
                '${session.killsInPhase}/${session.phaseKillTarget}',
                style: valueStyle.copyWith(color: const Color(0xFF4ADE80), fontSize: compact ? 13 : 15),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HudPanel(
          accent: _livesAccent(session.lives, session.livesAtStart),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('LIVES', style: labelStyle),
              Text(
                '${session.lives}/${session.livesAtStart}',
                style: valueStyle.copyWith(
                  color: _livesAccent(session.lives, session.livesAtStart),
                  fontSize: compact ? 14 : 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  session.livesAtStart,
                  (i) {
                    final alive = i < session.lives;
                    return Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                      child: Icon(
                        alive ? Icons.favorite : Icons.favorite_border,
                        color: alive ? const Color(0xFF4ADE80) : const Color(0xFF64748B),
                        size: compact ? 14 : 16,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HudIconButton(onPressed: onPause, icon: Icons.pause_rounded),
      ],
    );
  }

  Color _livesAccent(int lives, int total) {
    if (lives >= total) return const Color(0xFF4ADE80);
    if (lives <= 1) return const Color(0xFFFF6B6B);
    return const Color(0xFFFBBF24);
  }

  Widget _powerBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: AppTypography.orbitron(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _HudPanel extends StatelessWidget {
  const _HudPanel({required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final borderColor = accent ?? const Color(0xFF38BDF8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.88),
            const Color(0xFF1E293B).withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
        ),
      ),
    );
  }
}
