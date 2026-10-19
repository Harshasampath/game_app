import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../domain/entities/game_session.dart';
import '../game/audio/game_audio.dart';
import '../game/nebula_strike_game.dart';
import 'providers/game_session_provider.dart';
import 'providers/mission_progress_provider.dart';
import 'widgets/game_hud.dart';
import 'widgets/game_over_overlay.dart';
import 'widgets/mission_complete_overlay.dart';
import 'widgets/pause_overlay.dart';
import 'overlays/combat_transition_overlay.dart';
import 'overlays/hangar_overlay.dart';
import 'overlays/mission_select_overlay.dart';
import 'overlays/overlay_ids.dart';
import 'widgets/app_safe_area.dart';

/// Root widget — [GameWidget] drives the entire app; menus are Flame overlays.
class FlameAppShell extends ConsumerStatefulWidget {
  const FlameAppShell({super.key});

  @override
  ConsumerState<FlameAppShell> createState() => _FlameAppShellState();
}

class _FlameAppShellState extends ConsumerState<FlameAppShell> {
  late final NebulaStrikeGame _game;

  @override
  void initState() {
    super.initState();
    _game = NebulaStrikeGame(ref: ref);

    ref.listenManual<GameSession>(gameSessionProvider, (prev, next) {
      _game.syncSessionOverlays(next);

      if (next.isMissionComplete && prev?.isMissionComplete != true) {
        ref.read(missionProgressProvider.notifier).refresh();
        ref.invalidate(highScoreProvider);
      }
      if (next.isGameOver && prev?.isGameOver != true) {
        GameAudio.gameOver();
        ref.invalidate(highScoreProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);

    return Theme(
      data: AppTheme.dark,
      child: ColoredBox(
        color: const Color(0xFF0B1026),
        child: GameWidget(
          game: _game,
          overlayBuilderMap: {
                  OverlayIds.hangar: (context, g) =>
                      HangarOverlay(game: g as NebulaStrikeGame),
                  OverlayIds.missionSelect: (context, g) =>
                      MissionSelectOverlay(game: g as NebulaStrikeGame),
                  OverlayIds.transition: (context, g) => CombatTransitionOverlay(
                        message: (g as NebulaStrikeGame).transitionMessage,
                      ),
                  OverlayIds.hud: (context, g) => AppSafeArea(
                        bottom: false,
                        child: GameHud(
                          session: session,
                          onPause: () =>
                              ref.read(gameSessionProvider.notifier).pause(),
                        ),
                      ),
                  OverlayIds.pause: (context, g) => PauseOverlay(
                        onResume: () =>
                            ref.read(gameSessionProvider.notifier).resume(),
                        onQuit: () => (g as NebulaStrikeGame).showMissionSelect(),
                      ),
                  OverlayIds.gameOver: (context, g) => GameOverOverlay(
                        score: session.score,
                        highScore: session.highScore,
                        wave: session.endlessWave,
                        onReplay: () => (g as NebulaStrikeGame).replayMission(),
                        onHome: () => (g as NebulaStrikeGame).showHangar(),
                      ),
                  OverlayIds.missionComplete: (context, g) => MissionCompleteOverlay(
                        missionTitle: session.missionTitle,
                        score: session.score,
                        stars: session.missionStars,
                        elapsedSeconds: session.missionElapsedSeconds,
                        parSeconds: session.parTimeSeconds,
                        timeBonus: session.timeBonus,
                        rank: session.missionRank,
                        isPersonalBest: session.isPersonalBestTime,
                        onNextMission: () =>
                            (g as NebulaStrikeGame).showMissionSelect(),
                        onReplay: () => (g as NebulaStrikeGame).replayMission(),
                        onHome: () => (g as NebulaStrikeGame).showHangar(),
                      ),
                },
        ),
      ),
    );
  }
}
