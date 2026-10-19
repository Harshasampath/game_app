import 'package:flutter/material.dart';
import '../models/dice_theme.dart';

class ThemePickerSheet extends StatefulWidget {
  final DiceThemeData currentTheme;
  final ValueChanged<DiceThemeData> onThemeChanged;

  const ThemePickerSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<ThemePickerSheet> createState() => _ThemePickerSheetState();
}

class _ThemePickerSheetState extends State<ThemePickerSheet> {
  late DiceThemeData _theme;

  final List<Color> _palette = const [
    Color(0xFFD90429), // Crimson Red
    Color(0xFFFF5722), // Fire Orange
    Color(0xFFFFB703), // Gold Yellow
    Color(0xFF104F36), // Emerald Green
    Color(0xFF00F0FF), // Neon Cyan
    Color(0xFF3B82F6), // Sapphire Blue
    Color(0xFF7C3AED), // Royal Purple
    Color(0xFFF72585), // Hot Pink
    Color(0xFF1E222D), // Charcoal Navy
    Color(0xFF121212), // Deep Black
    Color(0xFFF8F9FA), // Crisp White
    Color(0xFFE2E8F0), // Cool Grey
  ];

  @override
  void initState() {
    super.initState();
    _theme = widget.currentTheme;
  }

  void _updateTheme(DiceThemeData newTheme) {
    setState(() {
      _theme = newTheme;
    });
    widget.onThemeChanged(newTheme);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dice Themes & Colors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'PRESETS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DiceThemeData.presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final preset = DiceThemeData.presets[index];
                  final isSelected = _theme.name == preset.name;

                  return GestureDetector(
                    onTap: () => _updateTheme(preset),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: preset.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white24,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: preset.dieColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: preset.dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CUSTOMIZE DICE BODY COLOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 10),
            _buildColorRow(
              selectedColor: _theme.dieColor,
              onSelect: (c) => _updateTheme(_theme.copyWith(dieColor: c, name: 'Custom')),
            ),
            const SizedBox(height: 20),
            const Text(
              'CUSTOMIZE DOT / PIP COLOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 10),
            _buildColorRow(
              selectedColor: _theme.dotColor,
              onSelect: (c) => _updateTheme(_theme.copyWith(dotColor: c, name: 'Custom')),
            ),
            const SizedBox(height: 20),
            const Text(
              'CUSTOMIZE BACKGROUND COLOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 10),
            _buildColorRow(
              selectedColor: _theme.backgroundColor,
              onSelect: (c) => _updateTheme(_theme.copyWith(backgroundColor: c, name: 'Custom')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow({
    required Color selectedColor,
    required ValueChanged<Color> onSelect,
  }) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _palette.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final color = _palette[index];
          final isSelected = selectedColor.toARGB32() == color.toARGB32();

          return GestureDetector(
            onTap: () => onSelect(color),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 20,
                      color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
