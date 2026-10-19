import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'models/dice_theme.dart';
import 'models/food_challenge.dart';
import 'models/glb_dice_loader.dart';
import 'services/dice_settings_service.dart';
import 'widgets/dice_settings_sheet.dart';
import 'widgets/dice_widget.dart';
import 'widgets/food_challenge_sheet.dart';
import 'widgets/theme_picker_sheet.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────────────────────

class ShuffleDiceScreen extends StatefulWidget {
  const ShuffleDiceScreen({super.key});

  @override
  State<ShuffleDiceScreen> createState() => _ShuffleDiceScreenState();
}

class _ShuffleDiceScreenState extends State<ShuffleDiceScreen>
    with TickerProviderStateMixin {
  // ── Dice State ──────────────────────────────────────────────────────────────
  int _currentValue = 1;
  int _targetValue = 1;
  bool _isRolling = false;

  // ── Settings (Sound, Vibration, Voice, Clean Screen Mode) ───────────────────
  bool _soundEnabled = true;
  bool _vibrateOnStop = true;
  bool _voiceCommandEnabled = false;
  bool _cleanMode = false;

  // ── Voice Command Recognition ───────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  Timer? _voiceRestartTimer;

  // ── Theme & Customization ───────────────────────────────────────────────────
  DiceThemeData _theme = DiceThemeData.presets[0];

  // ── Food Challenge ──────────────────────────────────────────────────────────
  bool _foodChallengeEnabled = true;
  Map<int, String> _foodRules = Map.from(FoodChallengePreset.presets[0].rules);
  String? _lastChallengeResult;

  // ── Shuffle Speed ───────────────────────────────────────────────────────────
  ShuffleSpeed _shuffleSpeed = ShuffleSpeed.normal;
  bool _showSpeedSelector = false;

  // ── 3D rotation angles ──────────────────────────────────────────────────────
  double _rotX = 0.0;
  double _rotY = 0.0;
  double _rotZ = 0.0;
  double _scale = 1.0;

  // ── Slot-machine ticker ─────────────────────────────────────────────────────
  // Instead of one AnimationController with a fixed duration we drive
  // an explicit timer-based "tick" loop that decelerates:
  //   • start with a short interval (fast flipping)
  //   • each tick the interval grows  → visually slows down
  //   • final tick snaps to the target value

  Timer? _tickTimer;
  int _ticksRemaining = 0;
  int _totalTicks = 0;
  double _currentTickMs = 40.0; // ms between face changes
  double _targetTickMs = 280.0; // final (slow) tick ms
  double _landingRotX = 0.0;
  double _landingRotY = 0.0;
  double _landingRotZ = 0.0;

  // ── Shake sensor ────────────────────────────────────────────────────────────
  StreamSubscription<UserAccelerometerEvent>? _sensorSubscription;
  DateTime _lastShakeTime = DateTime.now();
  static const double _shakeThreshold = 18.0;

  final math.Random _random = math.Random();

  // ── For spring-back scale ───────────────────────────────────────────────────
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;
  late final AnimationController _stopRotController;

  @override
  void initState() {
    super.initState();
    _currentValue = _random.nextInt(6) + 1;
    _targetValue = _currentValue;
    _updateChallengeResult(_currentValue);

    // Spring-back scale controller (just for visual bounce on land)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    // Controller for smooth rotation reset when dice lands
    _stopRotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _scaleAnim.addListener(() {
      if (!mounted) return;
      setState(() {
        // 0→1 anim: scale starts at 1.0, peaks mid-landing, returns to 1.0
        _scale = 1.0 + (_scaleAnim.value * (1 - _scaleAnim.value) * 4) * 0.22;
      });
    });

    _initShakeDetector();
    _loadSavedSettings();
    GlbDiceLoader.load();
    FlameAudio.audioCache.load('dice_rolling.wav').ignore();
  }

  Future<void> _loadSavedSettings() async {
    final settings = await DiceSettingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _theme = settings.theme;
      _shuffleSpeed = settings.shuffleSpeed;
      _foodChallengeEnabled = settings.foodChallengeEnabled;
      _foodRules = settings.foodRules;
      _soundEnabled = settings.soundEnabled;
      _vibrateOnStop = settings.vibrateOnStop;
      _voiceCommandEnabled = settings.voiceCommandEnabled;
      _updateChallengeResult(_currentValue);
    });

    if (_voiceCommandEnabled) {
      _initAndStartVoice();
    }
  }

  // ── Voice Commands ──────────────────────────────────────────────────────────

  Future<void> _initAndStartVoice() async {
    try {
      if (!_speechAvailable) {
        _speechAvailable = await _speech.initialize(
          onStatus: _onSpeechStatus,
          onError: (_) {
            if (mounted) setState(() => _isListening = false);
          },
        );
      }
      if (_speechAvailable && mounted && _voiceCommandEnabled && !_isRolling) {
        _startListening();
      }
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _startListening() {
    if (!_speechAvailable || !_voiceCommandEnabled || _isRolling || !mounted) return;
    try {
      _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase().trim();
          if (words.contains('roll') ||
              words.contains('dice') ||
              words.contains('shake') ||
              words.contains('spin') ||
              words.contains('toss') ||
              words.contains('throw') ||
              words.contains('go') ||
              words.contains('start') ||
              words.contains('shuffle')) {
            _rollDice(intensityBoost: 1.25, gestureType: 'Voice ("$words")');
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
      if (mounted) setState(() => _isListening = true);
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      setState(() => _isListening = true);
    } else if (status == 'notListening' || status == 'done') {
      setState(() => _isListening = false);
      if (_voiceCommandEnabled && !_isRolling) {
        _voiceRestartTimer?.cancel();
        _voiceRestartTimer = Timer(const Duration(milliseconds: 600), () {
          if (_voiceCommandEnabled && !_isRolling && mounted) {
            _startListening();
          }
        });
      }
    }
  }

  void _stopVoiceListening() {
    _voiceRestartTimer?.cancel();
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted) setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _voiceRestartTimer?.cancel();
    try {
      _speech.stop();
    } catch (_) {}
    _tickTimer?.cancel();
    _sensorSubscription?.cancel();
    _scaleController.dispose();
    _stopRotController.dispose();
    super.dispose();
  }

  // ── Shake ───────────────────────────────────────────────────────────────────

  void _initShakeDetector() {
    try {
      _sensorSubscription = userAccelerometerEventStream().listen((event) {
        if (!mounted || _isRolling) return;
        final acc = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        if (acc > _shakeThreshold) {
          final now = DateTime.now();
          if (now.difference(_lastShakeTime) > const Duration(milliseconds: 800)) {
            _lastShakeTime = now;
            _rollDice(intensityBoost: 1.3, gestureType: 'Shake');
          }
        }
      });
    } catch (_) {}
  }

  // ── Challenge ───────────────────────────────────────────────────────────────

  void _updateChallengeResult(int value) {
    if (_foodChallengeEnabled) {
      _lastChallengeResult = _foodRules[value] ?? 'Challenge #$value';
    } else {
      _lastChallengeResult = null;
    }
  }

  // ── Speed Calculation ────────────────────────────────────────────────────────
  // Returns (totalTicks, startIntervalMs, endIntervalMs)
  ({int ticks, double startMs, double endMs}) _calcSpeedParams({
    required double intensityBoost,
  }) {
    // Wild = pick a random speed profile every roll
    final effectiveSpeed = _shuffleSpeed == ShuffleSpeed.wild
        ? ShuffleSpeed.values[_random.nextInt(ShuffleSpeed.values.length - 1)]
        : _shuffleSpeed;

    // Base parameters per mode
    late int baseTicks;
    late double startMs;
    late double endMs;

    switch (effectiveSpeed) {
      case ShuffleSpeed.slow:
        baseTicks = 6;
        startMs = 180;
        endMs = 420;
      case ShuffleSpeed.normal:
        baseTicks = 10;
        startMs = 60;
        endMs = 320;
      case ShuffleSpeed.fast:
        baseTicks = 16;
        startMs = 35;
        endMs = 240;
      case ShuffleSpeed.turbo:
        baseTicks = 24;
        startMs = 18;
        endMs = 140;
      case ShuffleSpeed.wild:
        // fallback shouldn't reach here but just in case
        baseTicks = 14;
        startMs = 40;
        endMs = 280;
    }

    // Wild mode: randomize tick count a bit for extra unpredictability
    final extraTicks = _shuffleSpeed == ShuffleSpeed.wild
        ? _random.nextInt(10) - 3 // -3..+7
        : 0;

    return (
      ticks: (baseTicks + extraTicks).clamp(4, 40),
      startMs: startMs / intensityBoost,
      endMs: endMs,
    );
  }

  // ── Main Roll ────────────────────────────────────────────────────────────────
  void _rollDice({
    double intensityBoost = 1.0,
    double dx = 0.0,
    double dy = 0.0,
    String gestureType = 'Tap',
  }) {
    if (_isRolling) return;

    if (_isListening) {
      try {
        _speech.stop();
      } catch (_) {}
      setState(() => _isListening = false);
    }

    if (_soundEnabled) {
      try {
        FlameAudio.play('dice_rolling.wav');
      } catch (_) {}
    }

    _targetValue = _random.nextInt(6) + 1;
    _isRolling = true;

    // Random landing rotation
    _landingRotX = (_random.nextBool() ? 2.0 : -2.0) * intensityBoost;
    _landingRotY = (_random.nextBool() ? 2.0 : -2.0) * intensityBoost;
    _landingRotZ = (_random.nextBool() ? 1.5 : -1.5) * intensityBoost;

    if (dx.abs() > 10 || dy.abs() > 10) {
      _landingRotX = (dy > 0 ? 1.5 : -1.5) * intensityBoost;
      _landingRotY = (dx > 0 ? 1.5 : -1.5) * intensityBoost;
    }

    final params = _calcSpeedParams(intensityBoost: intensityBoost);
    _totalTicks = params.ticks;
    _ticksRemaining = params.ticks;
    _currentTickMs = params.startMs;
    _targetTickMs = params.endMs;

    HapticFeedback.mediumImpact();
    _scheduleTick();
  }

  // ── Slot-machine Tick Loop ───────────────────────────────────────────────────
  void _scheduleTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer(Duration(milliseconds: _currentTickMs.round()), _onTick);
  }

  void _onTick() {
    if (!mounted) return;

    _ticksRemaining--;

    final progress = 1.0 - (_ticksRemaining / _totalTicks); // 0→1

    // ── Face flip (randomize until last tick) ──────────────────────────────
    final isLastTick = _ticksRemaining <= 0;
    setState(() {
      _currentValue = isLastTick ? _targetValue : (_random.nextInt(6) + 1);

      // ── 3D Rotation: spin full rotations at start, dampen toward end ──────
      final spinFactor = (1.0 - progress) * 2 * math.pi;
      _rotX = _landingRotX * spinFactor * (1 - progress);
      _rotY = _landingRotY * spinFactor * (1 - progress);
      _rotZ = _landingRotZ * spinFactor * (1 - progress);

      // Scale: lift on first half, settle on second half
      if (!isLastTick) {
        _scale = 1.0 + math.sin(progress * math.pi) * 0.20;
      }
    });

    // ── Haptics ────────────────────────────────────────────────────────────
    if (isLastTick) {
      if (_vibrateOnStop) {
        HapticFeedback.heavyImpact();
      }
    } else if (progress < 0.4) {
      // rapid phase: fast haptic clicks
      HapticFeedback.selectionClick();
    }

    if (isLastTick) {
      // Land: spring-back bounce
      setState(() {
        _rotX = 0;
        _rotY = 0;
        _rotZ = 0;
        _scale = 1.0;
        _isRolling = false;
      });
      _scaleController.forward(from: 0);
      _updateChallengeResult(_targetValue);

      if (_voiceCommandEnabled) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _voiceCommandEnabled && !_isRolling) {
            _startListening();
          }
        });
      }
    } else {
      // ── Decelerate: interval grows with smooth easing ───────
      // Use Flutter's easeOutCubic curve for smoother timing
      final eased = Curves.easeOutCubic.transform(progress);
      _currentTickMs =
          _currentTickMs + (_targetTickMs - _currentTickMs) * eased * 0.35;

      _scheduleTick();
    }
  }

  // ── Modals ──────────────────────────────────────────────────────────────────

  void _openDiceSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DiceSettingsSheet(
            soundEnabled: _soundEnabled,
            onSoundChanged: (val) {
              setSheetState(() => _soundEnabled = val);
              setState(() => _soundEnabled = val);
              DiceSettingsService.saveSoundEnabled(val);
            },
            vibrateOnStop: _vibrateOnStop,
            onVibrateChanged: (val) {
              setSheetState(() => _vibrateOnStop = val);
              setState(() => _vibrateOnStop = val);
              DiceSettingsService.saveVibrateOnStop(val);
            },
            voiceCommandEnabled: _voiceCommandEnabled,
            isVoiceListening: _isListening,
            onVoiceCommandChanged: (val) {
              setSheetState(() => _voiceCommandEnabled = val);
              setState(() => _voiceCommandEnabled = val);
              DiceSettingsService.saveVoiceCommandEnabled(val);
              if (val) {
                _initAndStartVoice();
              } else {
                _stopVoiceListening();
              }
            },
            cleanMode: _cleanMode,
            onCleanModeChanged: (val) {
              setSheetState(() => _cleanMode = val);
              setState(() => _cleanMode = val);
            },
            accentColor: _theme.accentColor,
          );
        },
      ),
    );
  }

  void _openThemeCustomizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemePickerSheet(
        currentTheme: _theme,
        onThemeChanged: (newTheme) {
          setState(() => _theme = newTheme);
          DiceSettingsService.saveTheme(newTheme);
        },
      ),
    );
  }

  void _openFoodChallengeCustomizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodChallengeSheet(
        isEnabled: _foodChallengeEnabled,
        onToggleEnabled: (val) {
          setState(() {
            _foodChallengeEnabled = val;
            _updateChallengeResult(_currentValue);
          });
          DiceSettingsService.saveFoodChallengeEnabled(val);
        },
        currentRules: _foodRules,
        onRulesUpdated: (updatedRules) {
          setState(() {
            _foodRules = updatedRules;
            _updateChallengeResult(_currentValue);
          });
          DiceSettingsService.saveFoodRules(updatedRules);
        },
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final diceDimension =
        (math.min(screenSize.width, screenSize.height) * 0.85).clamp(240.0, 340.0);

    return Scaffold(
      backgroundColor: _theme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Ambient Glow ────────────────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      _theme.accentColor.withValues(alpha: _isRolling ? 0.16 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Full-screen Gesture Surface ──────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _rollDice(intensityBoost: 1.0, gestureType: 'Single Tap'),
                onDoubleTap: () =>
                    _rollDice(intensityBoost: 1.45, gestureType: 'Double Tap'),
                onPanEnd: (details) {
                  final velocity = details.velocity.pixelsPerSecond;
                  if (velocity.dx.abs() > 150 || velocity.dy.abs() > 150) {
                    _rollDice(
                      intensityBoost: 1.3,
                      dx: velocity.dx,
                      dy: velocity.dy,
                      gestureType: 'Swipe',
                    );
                  }
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Food Challenge Banner
                      if (!_cleanMode && _foodChallengeEnabled && _lastChallengeResult != null)
                        _FoodChallengeBanner(
                          value: _currentValue,
                          result: _lastChallengeResult!,
                          isRolling: _isRolling,
                        ),

                      // Dice
                      Transform.scale(
                        scale: _scale,
                        child: DiceWidget(
                          value: _currentValue,
                          theme: _theme,
                          size: diceDimension,
                          rotationX: _rotX,
                          rotationY: _rotY,
                          rotationZ: _rotZ,
                          elevation: _isRolling ? 32.0 : 16.0,
                          isRolling: _isRolling,
                        ),
                      ),

                      if (!_cleanMode) ...[
                        const SizedBox(height: 36),

                        // Status badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isRolling
                                ? _theme.accentColor.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: _isRolling
                                    ? _theme.accentColor.withValues(alpha: 0.5)
                                    : Colors.white12),
                          ),
                          child: Text(
                            _isRolling ? 'SHUFFLING...' : 'ROLLED  •  $_currentValue',
                            style: TextStyle(
                              color: _isRolling ? _theme.accentColor : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Top Header Bar ───────────────────────────────────────────────
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    tooltip: 'Back to Games',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                  ),
                  if (_voiceCommandEnabled) ...[
                    const SizedBox(width: 4),
                    _VoiceStatusPill(
                      isListening: _isListening,
                      onTap: () {
                        if (_isListening) {
                          _stopVoiceListening();
                        } else {
                          _startListening();
                        }
                      },
                    ),
                  ],
                  const SizedBox(width: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Eye Toggle (Clean Screen Mode: Hide text/banners/tips)
                          IconButton(
                            onPressed: () {
                              setState(() => _cleanMode = !_cleanMode);
                            },
                            icon: Icon(
                              _cleanMode
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: _cleanMode ? const Color(0xFFFFB74D) : Colors.white,
                              size: 22,
                            ),
                            tooltip: _cleanMode
                                ? 'Exit Clean Screen Mode'
                                : 'Clean Screen Mode (Hide All Text)',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(6),
                          ),
                          // Gear Icon (Dice Controls & Settings)
                          IconButton(
                            onPressed: _openDiceSettings,
                            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 22),
                            tooltip: 'Dice Settings',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(6),
                          ),
                          if (!_cleanMode) ...[
                            const SizedBox(width: 2),
                            // Food Challenge Toggle
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: _openFoodChallengeCustomizer,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _foodChallengeEnabled
                                        ? const Color(0xFFFF5722).withValues(alpha: 0.22)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _foodChallengeEnabled
                                          ? const Color(0xFFFF5722)
                                          : Colors.white24,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🍕', style: TextStyle(fontSize: 13)),
                                      const SizedBox(width: 4),
                                      Text(
                                        _foodChallengeEnabled ? 'CHALLENGE' : 'NORMAL',
                                        style: TextStyle(
                                          color: _foodChallengeEnabled
                                              ? const Color(0xFFFF7043)
                                              : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.5,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.keyboard_arrow_down,
                                          size: 14, color: Colors.white70),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Speed selector toggle button
                            _SpeedButton(
                              current: _shuffleSpeed,
                              isOpen: _showSpeedSelector,
                              onTap: () =>
                                  setState(() => _showSpeedSelector = !_showSpeedSelector),
                            ),
                            const SizedBox(width: 2),
                            // Theme Customizer
                            IconButton(
                              onPressed: _openThemeCustomizer,
                              icon: const Icon(Icons.palette_rounded, color: Colors.white, size: 22),
                              tooltip: 'Customize Theme & Colors',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(6),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Speed Selector Panel ─────────────────────────────────────────
            if (!_cleanMode && _showSpeedSelector)
              Positioned(
                top: 70,
                right: 12,
                child: _SpeedSelectorPanel(
                  selected: _shuffleSpeed,
                  onSelected: (speed) {
                    setState(() {
                      _shuffleSpeed = speed;
                      _showSpeedSelector = false;
                    });
                    DiceSettingsService.saveShuffleSpeed(speed);
                  },
                ),
              ),

            // ── Bottom Gesture Tips ───────────────────────────────────────────
            if (!_cleanMode)
              Positioned(
                bottom: 16,
                left: 20,
                right: 20,
                child: IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const _GestureTip(
                            icon: Icons.touch_app_outlined, label: 'Tap'),
                        const _GestureTip(icon: Icons.gesture, label: 'Swipe'),
                        const _GestureTip(
                            icon: Icons.double_arrow, label: '2x Tap'),
                        const _GestureTip(
                            icon: Icons.vibration, label: 'Shake'),
                        _GestureTip(
                          icon: _shuffleSpeed.icon,
                          label: _shuffleSpeed.label,
                          color: _speedColor(_shuffleSpeed),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _speedColor(ShuffleSpeed speed) {
    switch (speed) {
      case ShuffleSpeed.slow:
        return Colors.lightBlue;
      case ShuffleSpeed.normal:
        return Colors.white70;
      case ShuffleSpeed.fast:
        return Colors.orangeAccent;
      case ShuffleSpeed.turbo:
        return Colors.redAccent;
      case ShuffleSpeed.wild:
        return Colors.purpleAccent;
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Speed Button (top bar pill)
// ──────────────────────────────────────────────────────────────────────────────

class _SpeedButton extends StatelessWidget {
  final ShuffleSpeed current;
  final bool isOpen;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.current,
    required this.isOpen,
    required this.onTap,
  });

  Color get _color {
    switch (current) {
      case ShuffleSpeed.slow:
        return Colors.lightBlue;
      case ShuffleSpeed.normal:
        return Colors.white70;
      case ShuffleSpeed.fast:
        return Colors.orangeAccent;
      case ShuffleSpeed.turbo:
        return Colors.redAccent;
      case ShuffleSpeed.wild:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: isOpen ? 0.3 : 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _color.withValues(alpha: isOpen ? 0.9 : 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(current.icon, size: 14, color: _color),
            const SizedBox(width: 4),
            Text(
              current.label,
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 14,
              color: _color,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Speed Selector Dropdown Panel
// ──────────────────────────────────────────────────────────────────────────────

class _SpeedSelectorPanel extends StatelessWidget {
  final ShuffleSpeed selected;
  final ValueChanged<ShuffleSpeed> onSelected;

  const _SpeedSelectorPanel({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF181F2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'SHUFFLE SPEED',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            ...ShuffleSpeed.values.map((speed) {
              final isSelected = speed == selected;
              final color = _colorFor(speed);
              return InkWell(
                onTap: () => onSelected(speed),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(speed.icon,
                          size: 18,
                          color: isSelected ? color : Colors.white38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              speed.label,
                              style: TextStyle(
                                color: isSelected ? color : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _descFor(speed),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            size: 16, color: color),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _colorFor(ShuffleSpeed speed) {
    switch (speed) {
      case ShuffleSpeed.slow:
        return Colors.lightBlue;
      case ShuffleSpeed.normal:
        return Colors.white70;
      case ShuffleSpeed.fast:
        return Colors.orangeAccent;
      case ShuffleSpeed.turbo:
        return Colors.redAccent;
      case ShuffleSpeed.wild:
        return Colors.purpleAccent;
    }
  }

  String _descFor(ShuffleSpeed speed) {
    switch (speed) {
      case ShuffleSpeed.slow:
        return 'Gentle, suspenseful reveal';
      case ShuffleSpeed.normal:
        return 'Balanced classic roll';
      case ShuffleSpeed.fast:
        return 'Snappy, exciting shuffle';
      case ShuffleSpeed.turbo:
        return 'Blazing speed, thrilling';
      case ShuffleSpeed.wild:
        return 'Randomized every roll!';
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Food Challenge Banner
// ──────────────────────────────────────────────────────────────────────────────

class _FoodChallengeBanner extends StatelessWidget {
  final int value;
  final String result;
  final bool isRolling;

  const _FoodChallengeBanner({
    required this.value,
    required this.result,
    required this.isRolling,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isRolling ? 0.3 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 28, left: 24, right: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2638).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFF5722).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5722).withValues(alpha: 0.2),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'FOOD CHALLENGE DARE:',
                    style: TextStyle(
                      color: Color(0xFFFF8A65),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Gesture Tip chip
// ──────────────────────────────────────────────────────────────────────────────

class _GestureTip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GestureTip({
    required this.icon,
    required this.label,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Voice Status Pill
// ──────────────────────────────────────────────────────────────────────────────

class _VoiceStatusPill extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _VoiceStatusPill({
    required this.isListening,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isListening
              ? const Color(0xFFFF5252).withValues(alpha: 0.22)
              : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isListening ? const Color(0xFFFF5252) : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
              size: 14,
              color: isListening ? const Color(0xFFFF5252) : Colors.white60,
            ),
            const SizedBox(width: 5),
            Text(
              isListening ? 'SAY "ROLL"' : 'MIC PAUSED',
              style: TextStyle(
                color: isListening ? const Color(0xFFFF8A80) : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

