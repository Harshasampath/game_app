import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'models/dice_theme.dart';
import 'models/food_challenge.dart';
import 'widgets/dice_widget.dart';
import 'widgets/food_challenge_sheet.dart';
import 'widgets/theme_picker_sheet.dart';

class ShuffleDiceScreen extends StatefulWidget {
  const ShuffleDiceScreen({super.key});

  @override
  State<ShuffleDiceScreen> createState() => _ShuffleDiceScreenState();
}

class _ShuffleDiceScreenState extends State<ShuffleDiceScreen>
    with SingleTickerProviderStateMixin {
  // Dice State
  int _currentValue = 1;
  int _targetValue = 1;
  bool _isRolling = false;

  // Theme & Customization
  DiceThemeData _theme = DiceThemeData.presets[0]; // Midnight Gold

  // Food Challenge State
  bool _foodChallengeEnabled = true;
  Map<int, String> _foodRules = Map.from(FoodChallengePreset.presets[0].rules);
  String? _lastChallengeResult;

  // Animation Controller for 3D tumbling & shuffle
  late final AnimationController _animController;
  late final Animation<double> _animCurve;

  // 3D rotation angles
  double _rotX = 0.0;
  double _rotY = 0.0;
  double _rotZ = 0.0;
  double _targetRotX = 0.0;
  double _targetRotY = 0.0;
  double _targetRotZ = 0.0;
  double _scale = 1.0;

  // Shake sensor
  StreamSubscription<UserAccelerometerEvent>? _sensorSubscription;
  DateTime _lastShakeTime = DateTime.now();
  static const double _shakeThreshold = 18.0;

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _currentValue = _random.nextInt(6) + 1;
    _targetValue = _currentValue;
    _updateChallengeResult(_currentValue);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animCurve = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.addListener(_onAnimationTick);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRolling = false;
          _currentValue = _targetValue;
          _updateChallengeResult(_targetValue);
        });
        HapticFeedback.heavyImpact();
      }
    });

    _initShakeDetector();
  }

  void _initShakeDetector() {
    try {
      _sensorSubscription = userAccelerometerEventStream().listen((event) {
        if (!mounted || _isRolling) return;
        final acceleration = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        if (acceleration > _shakeThreshold) {
          final now = DateTime.now();
          if (now.difference(_lastShakeTime) > const Duration(milliseconds: 800)) {
            _lastShakeTime = now;
            _rollDice(intensity: 1.2, gestureType: 'Shake');
          }
        }
      });
    } catch (_) {}
  }

  void _updateChallengeResult(int value) {
    if (_foodChallengeEnabled) {
      _lastChallengeResult = _foodRules[value] ?? 'Challenge #$value';
    } else {
      _lastChallengeResult = null;
    }
  }

  void _onAnimationTick() {
    final t = _animController.value;

    // Rapidly randomize face value during roll
    if (t < 0.85) {
      final randomFace = _random.nextInt(6) + 1;
      if (randomFace != _currentValue) {
        setState(() {
          _currentValue = randomFace;
        });
        HapticFeedback.selectionClick();
      }
    } else {
      if (_currentValue != _targetValue) {
        setState(() {
          _currentValue = _targetValue;
        });
      }
    }

    // Interpolate 3D rotations & bounce scale using curved progression
    final curved = _animCurve.value;
    setState(() {
      _rotX = (_targetRotX * (1 - curved) * 2 * math.pi);
      _rotY = (_targetRotY * (1 - curved) * 2 * math.pi);
      _rotZ = (_targetRotZ * (1 - curved) * 2 * math.pi);
      // Lift off table and land with a spring bounce
      _scale = 1.0 + math.sin(t.clamp(0.0, 1.0) * math.pi) * 0.18;
    });
  }

  /// Single Shuffle, Double Tap Shuffle, or Swipe Shuffle
  void _rollDice({
    double intensity = 1.0,
    double dx = 0.0,
    double dy = 0.0,
    String gestureType = 'Tap',
  }) {
    if (_isRolling) return;

    _targetValue = _random.nextInt(6) + 1;
    _isRolling = true;

    // Impart directional rotation based on swipe or random tumble
    if (dx.abs() > 10 || dy.abs() > 10) {
      _targetRotX = (dy > 0 ? 1.5 : -1.5) * intensity;
      _targetRotY = (dx > 0 ? 1.5 : -1.5) * intensity;
      _targetRotZ = (_random.nextBool() ? 1.0 : -1.0) * intensity;
    } else {
      _targetRotX = (_random.nextBool() ? 2.0 : -2.0) * intensity;
      _targetRotY = (_random.nextBool() ? 2.0 : -2.0) * intensity;
      _targetRotZ = (_random.nextBool() ? 1.5 : -1.5) * intensity;
    }

    _animController.duration = Duration(
      milliseconds: (600 * intensity).round().clamp(450, 1100),
    );

    HapticFeedback.mediumImpact();
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _openThemeCustomizer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemePickerSheet(
        currentTheme: _theme,
        onThemeChanged: (newTheme) => setState(() => _theme = newTheme),
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
        },
        currentRules: _foodRules,
        onRulesUpdated: (updatedRules) {
          setState(() {
            _foodRules = updatedRules;
            _updateChallengeResult(_currentValue);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Calculate prominent fullscreen dice dimension (up to ~320px)
    final diceDimension = (math.min(screenSize.width, screenSize.height) * 0.68)
        .clamp(240.0, 340.0);

    return Scaffold(
      backgroundColor: _theme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Radial Background Glow
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      _theme.accentColor.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main Interactive Dice Area (Fullscreen Gesture Surface)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Single Tap Shuffle
                onTap: () => _rollDice(intensity: 1.0, gestureType: 'Single Tap'),
                // Double Tap Shuffle
                onDoubleTap: () => _rollDice(intensity: 1.45, gestureType: 'Double Tap'),
                // Swipe / Fling Shuffle
                onPanEnd: (details) {
                  final velocity = details.velocity.pixelsPerSecond;
                  if (velocity.dx.abs() > 150 || velocity.dy.abs() > 150) {
                    _rollDice(
                      intensity: 1.3,
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
                      // Food Challenge Result Banner (if active)
                      if (_foodChallengeEnabled && _lastChallengeResult != null)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _isRolling ? 0.3 : 1.0,
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
                                    '$_currentValue',
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
                                        _lastChallengeResult!,
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
                        ),

                      // The Fullscreen Interactive Dice
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
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Value Badge & Total
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white12),
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
                  ),
                ),
              ),
            ),

            // Top Header Bar (Positioned above interactive area so clicks register)
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
                  ),
                  const Spacer(),
                  // Food Challenge Toggle Pill
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _openFoodChallengeCustomizer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _foodChallengeEnabled
                              ? const Color(0xFFFF5722).withValues(alpha: 0.22)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _foodChallengeEnabled
                                ? const Color(0xFFFF5722)
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🍕', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              _foodChallengeEnabled ? 'FOOD CHALLENGE' : 'NORMAL MODE',
                              style: TextStyle(
                                color: _foodChallengeEnabled
                                    ? const Color(0xFFFF7043)
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Theme Customizer Button
                  IconButton(
                    onPressed: _openThemeCustomizer,
                    icon: const Icon(Icons.palette_outlined, color: Colors.white),
                    tooltip: 'Customize Theme & Colors',
                  ),
                ],
              ),
            ),

            // Bottom Gestures Guide Bar
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _GestureTip(icon: Icons.touch_app_outlined, label: 'Single Tap'),
                      _GestureTip(icon: Icons.gesture, label: 'Swipe Roll'),
                      _GestureTip(icon: Icons.double_arrow, label: 'Double Tap'),
                      _GestureTip(icon: Icons.vibration, label: 'Shake Phone'),
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
}

class _GestureTip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GestureTip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white60),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
