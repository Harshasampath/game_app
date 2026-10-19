import 'package:flutter/material.dart';

class DiceSettingsSheet extends StatelessWidget {
  final bool soundEnabled;
  final ValueChanged<bool> onSoundChanged;

  final bool vibrateOnStop;
  final ValueChanged<bool> onVibrateChanged;

  final bool voiceCommandEnabled;
  final ValueChanged<bool> onVoiceCommandChanged;
  final bool isVoiceListening;

  final bool cleanMode;
  final ValueChanged<bool> onCleanModeChanged;

  final Color accentColor;

  const DiceSettingsSheet({
    super.key,
    required this.soundEnabled,
    required this.onSoundChanged,
    required this.vibrateOnStop,
    required this.onVibrateChanged,
    required this.voiceCommandEnabled,
    required this.onVoiceCommandChanged,
    this.isVoiceListening = false,
    required this.cleanMode,
    required this.onCleanModeChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
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
                  margin: const EdgeInsets.only(bottom: 20),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configure sound, feedback & hands-free play',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
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

              const SizedBox(height: 20),

              // 1. Sound On / Off
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

              // 2. Vibrate Feedback after Stop On / Off
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

              // 3. Voice Command Dice Rolling On / Off
              _buildSettingTile(
                icon: voiceCommandEnabled
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
                iconColor: voiceCommandEnabled
                    ? (isVoiceListening ? const Color(0xFFFF5252) : const Color(0xFF448AFF))
                    : Colors.white38,
                title: 'Voice Command Rolling',
                subtitle: voiceCommandEnabled
                    ? (isVoiceListening
                        ? 'Listening: Say "Roll", "Dice", "Shake", "Go"'
                        : 'Voice active — ready for keywords')
                    : 'Disabled — roll via tap/shake/swipe',
                value: voiceCommandEnabled,
                badge: voiceCommandEnabled && isVoiceListening
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFF5252), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFFFF5252)),
                            SizedBox(width: 4),
                            Text(
                              'MIC ON',
                              style: TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
                onChanged: onVoiceCommandChanged,
              ),

              const SizedBox(height: 12),

              // 4. Clean Screen Mode (Zen Mode)
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
