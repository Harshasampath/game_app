import 'package:flutter/material.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
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
                const Text('PAUSED', style: TextStyle(letterSpacing: 4, fontSize: 20)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('RESUME'),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: onQuit, child: const Text('QUIT')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
