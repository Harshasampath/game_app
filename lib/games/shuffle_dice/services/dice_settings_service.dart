import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dice_theme.dart';
import '../models/food_challenge.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Shuffle Speed enum representation
// ──────────────────────────────────────────────────────────────────────────────
enum ShuffleSpeed {
  slow('Slow', Icons.snooze_rounded, 0.45),
  normal('Normal', Icons.speed_rounded, 1.0),
  fast('Fast', Icons.bolt_rounded, 1.8),
  turbo('Turbo', Icons.rocket_launch_rounded, 3.0),
  wild('Wild 🎲', Icons.shuffle_rounded, -1.0); // -1 = fully random each roll

  const ShuffleSpeed(this.label, this.icon, this.multiplier);
  final String label;
  final IconData icon;
  final double multiplier;
}

// ──────────────────────────────────────────────────────────────────────────────
// Container for all persisted settings
// ──────────────────────────────────────────────────────────────────────────────
class DiceSettings {
  final DiceThemeData theme;
  final ShuffleSpeed shuffleSpeed;
  final bool foodChallengeEnabled;
  final Map<int, String> foodRules;
  final double shuffleDuration;
  final bool soundEnabled;
  final bool vibrateOnStop;
  final bool voiceCommandEnabled;

  const DiceSettings({
    required this.theme,
    required this.shuffleSpeed,
    this.shuffleDuration = 2.0,
    required this.foodChallengeEnabled,
    required this.foodRules,
    this.soundEnabled = true,
    this.vibrateOnStop = true,
    this.voiceCommandEnabled = false,
  });

  static DiceSettings defaults() {
    return DiceSettings(
      theme: DiceThemeData.presets[0],
      shuffleSpeed: ShuffleSpeed.normal,
      shuffleDuration: 2.0,
      foodChallengeEnabled: true,
      foodRules: Map.from(FoodChallengePreset.presets[0].rules),
      soundEnabled: true,
      vibrateOnStop: true,
      voiceCommandEnabled: false,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Persistent Settings Service using SharedPreferences
// ──────────────────────────────────────────────────────────────────────────────
class DiceSettingsService {
  static const String _kThemeKey = 'shuffle_dice_theme_data';
  static const String _kSpeedKey = 'shuffle_dice_speed_mode';
  static const String _kFoodEnabledKey = 'shuffle_dice_food_enabled';
  static const String _kFoodRulesKey = 'shuffle_dice_food_rules_map';
  static const String _kDurationKey = 'shuffle_dice_duration_seconds';
  static const String _kSoundEnabledKey = 'shuffle_dice_sound_enabled';
  static const String _kVibrateStopKey = 'shuffle_dice_vibrate_stop_enabled';
  static const String _kVoiceCommandKey = 'shuffle_dice_voice_command_enabled';

  /// Load all settings at once on startup
  static Future<DiceSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme
      DiceThemeData theme = DiceThemeData.presets[0];
      final themeStr = prefs.getString(_kThemeKey);
      if (themeStr != null && themeStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(themeStr) as Map<String, dynamic>;
          theme = DiceThemeData.fromMap(decoded);
        } catch (_) {}
      }

      // Speed
      ShuffleSpeed speed = ShuffleSpeed.normal;
      final speedName = prefs.getString(_kSpeedKey);
      if (speedName != null) {
        for (final s in ShuffleSpeed.values) {
          if (s.name == speedName) {
            speed = s;
            break;
          }
        }
      }

      // Shuffle duration
      final duration = prefs.getDouble(_kDurationKey) ?? 2.0;

      // Food Challenge Enabled
      final foodEnabled = prefs.getBool(_kFoodEnabledKey) ?? true;

      // Sound, Vibrate, Voice Command
      final soundEnabled = prefs.getBool(_kSoundEnabledKey) ?? true;
      final vibrateStop = prefs.getBool(_kVibrateStopKey) ?? true;
      final voiceCommand = prefs.getBool(_kVoiceCommandKey) ?? false;

      // Food Challenge Rules
      Map<int, String> rules = Map.from(FoodChallengePreset.presets[0].rules);
      final rulesStr = prefs.getString(_kFoodRulesKey);
      if (rulesStr != null && rulesStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(rulesStr) as Map<String, dynamic>;
          final parsed = <int, String>{};
          decoded.forEach((k, v) {
            final keyInt = int.tryParse(k);
            if (keyInt != null && v is String) {
              parsed[keyInt] = v;
            }
          });
          if (parsed.isNotEmpty) {
            rules = parsed;
          }
        } catch (_) {}
      }

      return DiceSettings(
        theme: theme,
        shuffleSpeed: speed,
        shuffleDuration: duration,
        foodChallengeEnabled: foodEnabled,
        foodRules: rules,
        soundEnabled: soundEnabled,
        vibrateOnStop: vibrateStop,
        voiceCommandEnabled: voiceCommand,
      );
    } catch (_) {
      return DiceSettings.defaults();
    }
  }

  /// Save the current theme
  static Future<void> saveTheme(DiceThemeData theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeKey, jsonEncode(theme.toMap()));
    } catch (_) {}
  }

  /// Save the chosen shuffle speed
  static Future<void> saveShuffleSpeed(ShuffleSpeed speed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSpeedKey, speed.name);
    } catch (_) {}
  }

  /// Save the shuffle roll duration (seconds)
  static Future<void> saveShuffleDuration(double duration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kDurationKey, duration);
    } catch (_) {}
  }

  /// Save whether Food Challenge is enabled
  static Future<void> saveFoodChallengeEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kFoodEnabledKey, enabled);
    } catch (_) {}
  }

  /// Save whether sound is enabled
  static Future<void> saveSoundEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSoundEnabledKey, enabled);
    } catch (_) {}
  }

  /// Save whether vibrate on stop is enabled
  static Future<void> saveVibrateOnStop(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kVibrateStopKey, enabled);
    } catch (_) {}
  }

  /// Save whether voice command rolling is enabled
  static Future<void> saveVoiceCommandEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kVoiceCommandKey, enabled);
    } catch (_) {}
  }

  /// Save custom or preset food challenge rules
  static Future<void> saveFoodRules(Map<int, String> rules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringKeyMap = rules.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_kFoodRulesKey, jsonEncode(stringKeyMap));
    } catch (_) {}
  }
}
