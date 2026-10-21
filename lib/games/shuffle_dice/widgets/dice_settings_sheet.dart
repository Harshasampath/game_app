import 'package:flutter/material.dart';
import '../services/dice_settings_service.dart';

class DiceSettingsSheet extends StatelessWidget {
  final double shuffleDuration;
  final ValueChanged<double> onShuffleDurationChanged;

  final ShuffleSpeed shuffleSpeed;
  final ValueChanged<ShuffleSpeed> onShuffleSpeedChanged;

  final bool soundEnabled;
  final ValueChanged<bool> onSoundChanged;

  final bool vibrateOnStop;
  final ValueChanged<bool> onVibrateChanged;

  final bool voiceCommandEnabled;
  final ValueChanged<bool> onVoiceCommandChanged;
  final bool isVoiceListening;

  final bool cleanMode;
  final ValueChanged<bool> onCleanModeChanged;

  final int diceCount;
  final ValueChanged<int> onDiceCountChanged;

  final Color accentColor;

  const DiceSettingsSheet({
    super.key,
    this.diceCount = 1,
    required this.onDiceCountChanged,
    this.shuffleDuration = 2.0,
    required this.onShuffleDurationChanged,
    this.shuffleSpeed = ShuffleSpeed.normal,
    required this.onShuffleSpeedChanged,
    required this.soundEnabled,
    required this.onSoundChanged,
    required this.vibrateOnStop,
    required this.onVibrateChanged,
    this.voiceCommandEnabled = false,
    required this.onVoiceCommandChanged,
    this.isVoiceListening = false,
    required this.cleanMode,
    required this.onCleanModeChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DICE CONTROLS & SETTINGS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Adjust shuffle duration, speed & feedback',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    tooltip: 'Close',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── 0. Number of Dice (1 to 6) ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.casino_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Number of Dice',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                diceCount == 1
                                    ? '1 die shuffling at once'
                                    : '$diceCount dice shuffling simultaneously',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            diceCount == 1 ? '1 DIE' : '$diceCount DICE',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        final count = i + 1;
                        final isSelected = count == diceCount;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 3,
                              right: i == 5 ? 0 : 3,
                            ),
                            child: InkWell(
                              onTap: () => onDiceCountChanged(count),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accentColor
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? accentColor
                                        : Colors.white.withValues(alpha: 0.15),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: accentColor.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.casino_outlined,
                                      size: 16,
                                      color: isSelected ? Colors.white : Colors.white60,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 1. Shuffle Duration Adjustment Slider ──────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            color: Color(0xFF64B5F6),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shuffle Duration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _durationDescription(shuffleDuration),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${shuffleDuration.toStringAsFixed(1)}s',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accentColor,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: accentColor,
                        overlayColor: accentColor.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: shuffleDuration.clamp(0.5, 5.0),
                        min: 0.5,
                        max: 5.0,
                        divisions: 45,
                        label: '${shuffleDuration.toStringAsFixed(1)}s',
                        onChanged: onShuffleDurationChanged,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDurationChip(context, label: '0.8s Fast', target: 0.8),
                        _buildDurationChip(context, label: '1.5s Snappy', target: 1.5),
                        _buildDurationChip(context, label: '2.0s Normal', target: 2.0),
                        _buildDurationChip(context, label: '3.5s Epic', target: 3.5),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 2. Shuffle Speed Mode Dropdown ──────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.speed_rounded,
                        color: Color(0xFFFFB74D),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shuffle Speed Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Intensity & pattern',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<ShuffleSpeed>(
                        value: shuffleSpeed,
                        dropdownColor: const Color(0xFF222736),
                        borderRadius: BorderRadius.circular(14),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                        items: ShuffleSpeed.values.map((s) {
                          return DropdownMenuItem<ShuffleSpeed>(
                            value: s,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(s.icon, size: 16, color: accentColor),
                                const SizedBox(width: 8),
                                Text(
                                  s.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onShuffleSpeedChanged(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── 3. Sound On / Off ───────────────────────────────────────────
              _buildSettingTile(
                icon: soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                iconColor: soundEnabled ? accentColor : Colors.white38,
                title: 'Dice Rolling Sound',
                subtitle: soundEnabled
                    ? 'Audio plays during shuffle & roll'
                    : 'Muted — silent rolling',
                value: soundEnabled,
                onChanged: onSoundChanged,
              ),

              const SizedBox(height: 12),

              // ── 4. Vibrate Feedback after Stop On / Off ─────────────────────
              _buildSettingTile(
                icon: vibrateOnStop
                    ? Icons.vibration_rounded
                    : Icons.mobile_off_rounded,
                iconColor: vibrateOnStop ? const Color(0xFF4CAF50) : Colors.white38,
                title: 'Vibrate on Dice Stop',
                subtitle: vibrateOnStop
                    ? 'Haptic thump when dice finishes & lands'
                    : 'No vibration feedback on landing',
                value: vibrateOnStop,
                onChanged: onVibrateChanged,
              ),

              const SizedBox(height: 12),

              // ── 5. Clean Screen Mode (Zen Mode) ─────────────────────────────
              _buildSettingTile(
                icon: cleanMode
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                iconColor: cleanMode ? const Color(0xFFFFB74D) : Colors.white38,
                title: 'Clean Screen Mode',
                subtitle: cleanMode
                    ? 'All HUD, banners & text hidden (pure 3D dice)'
                    : 'Standard view with hints, badges & banners',
                value: cleanMode,
                onChanged: onCleanModeChanged,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _durationDescription(double sec) {
    if (sec <= 1.0) return 'Ultra fast & snappy';
    if (sec <= 1.8) return 'Quick dynamic shuffle';
    if (sec <= 2.8) return 'Standard balanced roll';
    if (sec <= 4.0) return 'Suspenseful rolling drama';
    return 'Extended suspense roll';
  }

  Widget _buildDurationChip(
    BuildContext context, {
    required String label,
    required double target,
  }) {
    final isSelected = (shuffleDuration - target).abs() < 0.15;
    return InkWell(
      onTap: () => onShuffleDurationChanged(target),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? accentColor : Colors.white70,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? badge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? iconColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
