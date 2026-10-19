import 'package:flutter/material.dart';
import '../models/food_challenge.dart';

class FoodChallengeSheet extends StatefulWidget {
  final bool isEnabled;
  final ValueChanged<bool> onToggleEnabled;
  final Map<int, String> currentRules;
  final ValueChanged<Map<int, String>> onRulesUpdated;

  const FoodChallengeSheet({
    super.key,
    required this.isEnabled,
    required this.onToggleEnabled,
    required this.currentRules,
    required this.onRulesUpdated,
  });

  @override
  State<FoodChallengeSheet> createState() => _FoodChallengeSheetState();
}

class _FoodChallengeSheetState extends State<FoodChallengeSheet> {
  late bool _enabled;
  late Map<int, String> _rules;

  @override
  void initState() {
    super.initState();
    _enabled = widget.isEnabled;
    _rules = Map<int, String>.from(widget.currentRules);
  }

  void _applyPreset(FoodChallengePreset preset) {
    setState(() {
      _rules = Map<int, String>.from(preset.rules);
      _enabled = true;
    });
    widget.onToggleEnabled(true);
    widget.onRulesUpdated(_rules);
  }

  void _editRule(int number) async {
    final controller = TextEditingController(text: _rules[number] ?? '');
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2433),
        title: Text(
          'Custom Rule for Dice ($number)',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter food challenge / action...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty) {
      setState(() {
        _rules[number] = updated;
      });
      widget.onRulesUpdated(_rules);
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🍕', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text(
                      'Food Challenge Mode',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _enabled,
                  activeTrackColor: const Color(0xFFFF5722),
                  activeThumbColor: Colors.white,
                  onChanged: (val) {
                    setState(() => _enabled = val);
                    widget.onToggleEnabled(val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Roll the dice to decide who takes a spicy bite, mystery food, or dare!',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text(
              'CHALLENGE PRESETS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FoodChallengePreset.presets.map((preset) {
                return ActionChip(
                  avatar: Text(preset.icon),
                  label: Text(preset.title),
                  backgroundColor: const Color(0xFF222B3D),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  side: const BorderSide(color: Colors.white24),
                  onPressed: () => _applyPreset(preset),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'DICE NUMBERS TO ACTION (TAP TO EDIT)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(6, (index) {
              final number = index + 1;
              final rule = _rules[number] ?? 'No rule assigned';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2638),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    rule,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.edit, color: Colors.white38, size: 18),
                  onTap: () => _editRule(number),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
