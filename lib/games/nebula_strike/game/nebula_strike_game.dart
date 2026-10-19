import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/system/app_system_ui.dart';
import '../domain/entities/game_mission.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/mission_background_theme.dart';
import '../presentation/overlays/overlay_ids.dart';
import '../presentation/providers/game_session_provider.dart';
import '../presentation/providers/provider_scheduling.dart';
import 'audio/game_audio.dart';
import 'combat_session.dart';
import 'components/menu_backdrop_component.dart';
import 'components/wave_banner_component.dart';

enum AppScene { hangar, missionSelect, combat }

/// Root Flame game — owns the canvas, scenes, and overlay routing.
class NebulaStrikeGame extends FlameGame with HasCollisionDetection, TapCallbacks, DragCallbacks {
  NebulaStrikeGame({required this.ref});

  final WidgetRef ref;

  AppScene scene = AppScene.hangar;
  MenuBackdropComponent? _menuBackdrop;
  late final WaveBannerComponent _waveBanner;
  CombatSession? _combat;
  Color _canvasBackground = const Color(0xFF0B1026);
  String _transitionMessage = 'LAUNCHING...';

  @override
  Color backgroundColor() => _canvasBackground;

  WaveBannerComponent get waveBanner => _waveBanner;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await GameAudio.unlock();
    _waveBanner = WaveBannerComponent();
    add(_waveBanner);
    _ensureMenuBackdrop();
    _showMenuOverlay(OverlayIds.hangar);
    await _setPortrait();
  }

  String get transitionMessage => _transitionMessage;

  void _showTransition(String message) {
    _transitionMessage = message;
    _clearOverlays();
    overlays.add(OverlayIds.transition);
  }

  Future<void> _waitForOrientationSettle() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  void _clearOverlays() {
    overlays.clear();
  }

  void _showMenuOverlay(String overlayId) {
    _clearOverlays();
    _ensureMenuBackdrop();
    overlays.add(overlayId);
  }

  void _showCombatHud() {
    _clearOverlays();
    overlays.add(OverlayIds.hud);
  }

  void _ensureMenuBackdrop() {
    _menuBackdrop ??= MenuBackdropComponent(viewportSize: size);
    if (_menuBackdrop!.parent == null) {
      add(_menuBackdrop!);
    }
  }

  void _hideMenuBackdrop() {
    _menuBackdrop?.removeFromParent();
  }

  Future<void> showHangar() async {
    scene = AppScene.hangar;
    _canvasBackground = const Color(0xFF0B1026);
    _endCombat();
    _showTransition('RETURNING...');
    await _setPortrait();
    await _waitForOrientationSettle();
    _showMenuOverlay(OverlayIds.hangar);
  }

  Future<void> showMissionSelect() async {
    scene = AppScene.missionSelect;
    _canvasBackground = const Color(0xFF0B1026);
    _endCombat();
    _showTransition('RETURNING...');
    await _setPortrait();
    await _waitForOrientationSettle();
    _showMenuOverlay(OverlayIds.missionSelect);
  }

  Future<void> startMission(GameMission mission) async {
    scene = AppScene.combat;
    _canvasBackground = MissionBackgroundThemes.forMissionId(mission.id).canvasBackground;
    ref.read(activeMissionProvider.notifier).state = mission;

    final highScore = await ref.read(highScoreProvider.future);
    ref.read(gameSessionProvider.notifier).startMission(mission, highScore: highScore);

    _showTransition('LAUNCHING...');
    _hideMenuBackdrop();
    await _setLandscape();
    await _waitForOrientationSettle();

    _combat?.removeFromParent();
    _combat = CombatSession(ref: ref, mission: mission);
    await add(_combat!);

    _showCombatHud();
  }

  void _endCombat() {
    _waveBanner.dismiss();
    _combat?.removeFromParent();
    _combat = null;
    ref.read(activeMissionProvider.notifier).state = null;
    ref.read(gameSessionProvider.notifier).reset();
  }

  void syncSessionOverlays(GameSession session) {
    if (scene != AppScene.combat) return;

    if (session.isGameOver) {
      _clearOverlays();
      overlays.add(OverlayIds.gameOver);
      return;
    }

    if (session.isMissionComplete) {
      _clearOverlays();
      overlays.add(OverlayIds.missionComplete);
      return;
    }

    if (session.status == GameStatus.paused) {
      if (!overlays.isActive(OverlayIds.pause)) {
        overlays.add(OverlayIds.pause);
      }
      return;
    }

    // Playing — HUD only, no stacked modals
    if (!overlays.isActive(OverlayIds.hud) ||
        overlays.isActive(OverlayIds.pause) ||
        overlays.isActive(OverlayIds.gameOver) ||
        overlays.isActive(OverlayIds.missionComplete)) {
      _showCombatHud();
    }
  }

  void replayMission() {
    deferProviderWrite(() {
      final mission = ref.read(activeMissionProvider);
      final session = ref.read(gameSessionProvider);
      if (mission != null) {
        ref.read(gameSessionProvider.notifier).startMission(
              mission,
              highScore: session.highScore,
            );
      }
    });
    _showCombatHud();
    _combat?.resetRound();
  }

  Future<void> _setPortrait() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await AppSystemUi.configurePortrait();
    } catch (_) {}
  }

  Future<void> _setLandscape() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {}
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _menuBackdrop?.viewportSize.setFrom(size);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _combat?.handleDragStart(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _combat?.handleDragUpdate(event.localEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _combat?.handleDragEnd();
  }

  @override
  void onTapDown(TapDownEvent event) {
    GameAudio.unlock();
    _combat?.handleTapDown(event.localPosition);
  }
}
