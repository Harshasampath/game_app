/// Flame [GameWidget] overlay keys — all UI flows through the game shell.
abstract final class OverlayIds {
  static const hangar = 'hangar';
  static const missionSelect = 'missionSelect';
  static const transition = 'transition';
  static const hud = 'hud';
  static const pause = 'pause';
  static const gameOver = 'gameOver';
  static const missionComplete = 'missionComplete';

  static const all = [
    hangar,
    missionSelect,
    transition,
    hud,
    pause,
    gameOver,
    missionComplete,
  ];
}
