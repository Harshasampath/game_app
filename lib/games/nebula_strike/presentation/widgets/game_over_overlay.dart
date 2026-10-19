import 'package:flutter/material.dart';

import 'animated_result_banner.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.score,
    required this.highScore,
    required this.wave,
    required this.onReplay,
    required this.onHome,
  });

  final int score;
  final int highScore;
  final int wave;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final isNewRecord = score >= highScore && score > 0;

    return AnimatedResultBackdrop(
      isVictory: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Card(
            color: const Color(0xFF1E2740),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AnimatedResultBanner(
                    message: 'YOU LOSE!',
                    isVictory: false,
                    accentColor: Color(0xFFFF6B6B),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MISSION FAILED',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  if (isNewRecord) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'NEW HIGH SCORE!',
                      style: TextStyle(color: Color(0xFFFFD43B), fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Score: $score', style: const TextStyle(fontSize: 18)),
                  Text('Endless wave: $wave', style: const TextStyle(color: Colors.white54)),
                  Text('Best: $highScore', style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay),
                    label: const Text('RETRY'),
                  ),
                  TextButton(onPressed: onHome, child: const Text('HANGAR')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
