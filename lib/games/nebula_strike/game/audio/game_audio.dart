import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Centralized SFX with rate limiting so Android does not exhaust MediaPlayers.
class GameAudio {
  GameAudio._();

  static bool _initialized = false;
  static bool _unlocked = false;

  static final _playerShoot = _SfxBus('player_shoot.wav', minGap: 0.06, maxVoices: 3);
  static final _enemyShoot = _SfxBus('enemy_shoot.wav', minGap: 0.14, maxVoices: 2);
  static final _enemyKill = _SfxBus('enemy_kill.wav', minGap: 0.05, maxVoices: 4);
  static final _bossKill = _SfxBus('explosion_large.wav', minGap: 0.2, maxVoices: 1);
  static final _playerBoom = _SfxBus('player_boom.wav', minGap: 0.35, maxVoices: 1);
  static final _powerUp = _SfxBus('powerup.wav', minGap: 0.15, maxVoices: 1);
  static final _uiConfirm = _SfxBus('ui_confirm.wav', minGap: 0.08, maxVoices: 2);
  static final _phaseClear = _SfxBus('phase_clear.wav', minGap: 0.5, maxVoices: 1);
  static final _missionComplete = _SfxBus('mission_complete.wav', minGap: 0.5, maxVoices: 1);
  static final _gameOver = _SfxBus('game_over.wav', minGap: 0.5, maxVoices: 1);

  static const _files = [
    'player_shoot.wav',
    'enemy_shoot.wav',
    'enemy_kill.wav',
    'explosion_large.wav',
    'player_boom.wav',
    'powerup.wav',
    'phase_clear.wav',
    'mission_complete.wav',
    'game_over.wav',
    'ui_confirm.wav',
  ];

  static final _buses = [
    _playerShoot,
    _enemyShoot,
    _enemyKill,
    _bossKill,
    _playerBoom,
    _powerUp,
    _uiConfirm,
    _phaseClear,
    _missionComplete,
    _gameOver,
  ];

  static Future<void> preload() async {
    if (_initialized) return;

    try {
      await FlameAudio.audioCache.loadAll(_files);
      await Future.wait(_buses.map((b) => b.init()));
      _initialized = true;
      if (kDebugMode) debugPrint('GameAudio: loaded ${_files.length} sounds');
    } catch (e, st) {
      if (kDebugMode) debugPrint('GameAudio preload failed: $e\n$st');
    }
  }

  static Future<void> unlock() async {
    if (_unlocked) return;
    _unlocked = true;
    await preload();
  }

  static void playerShoot() => _playerShoot.play(volume: 0.75);
  static void enemyShoot() => _enemyShoot.play(volume: 0.65);
  static void enemyKilled({bool boss = false}) => boss
      ? _bossKill.play(volume: 0.88)
      : _enemyKill.play(volume: 0.72);
  static void playerDamage() => _playerBoom.play(volume: 0.95);
  static void powerUp() => _powerUp.play(volume: 0.8);
  static void phaseClear() => _phaseClear.play(volume: 0.85);
  static void missionComplete() => _missionComplete.play(volume: 0.9);
  static void gameOver() => _gameOver.play(volume: 0.9);
  static void uiConfirm() => _uiConfirm.play(volume: 0.7);
}

/// One sound with gap limiting and a hard cap on simultaneous players.
class _SfxBus {
  _SfxBus(this.file, {required this.minGap, required this.maxVoices});

  final String file;
  final double minGap;
  final int maxVoices;

  AudioPool? _pool;
  double _lastPlay = 0;
  int _playing = 0;

  Future<void> init() async {
    _pool = await FlameAudio.createPool(
      file,
      maxPlayers: maxVoices,
      minPlayers: 1,
      audioContext: AudioContextConfig(
        focus: AudioContextConfigFocus.gain,
      ).build(),
    );
  }

  void play({required double volume}) {
    if (_pool == null) {
      unawaited(GameAudio.unlock());
      return;
    }

    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    if (now - _lastPlay < minGap) return;
    if (_playing >= maxVoices) return;

    _lastPlay = now;
    _playing++;

    unawaited(() async {
      try {
        final stop = await _pool!.start(volume: volume.clamp(0.0, 1.0));
        final duration = await _pool!.getDuration() ?? const Duration(milliseconds: 120);
        await Future<void>.delayed(duration);
        await stop();
      } catch (e) {
        if (kDebugMode) debugPrint('GameAudio $file failed: $e');
        await _recover();
      } finally {
        _playing = (_playing - 1).clamp(0, maxVoices);
      }
    }());
  }

  Future<void> _recover() async {
    try {
      await _pool?.dispose();
    } catch (_) {}
    _pool = null;
    _playing = 0;
    try {
      await init();
    } catch (e) {
      if (kDebugMode) debugPrint('GameAudio $file recover failed: $e');
    }
  }
}
