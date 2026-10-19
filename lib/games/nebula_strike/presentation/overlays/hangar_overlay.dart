import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ship_type.dart';
import '../../game/audio/game_audio.dart';
import '../../game/nebula_strike_game.dart';
import '../../game/rendering/ship_painter.dart';
import '../providers/dependency_providers.dart';
import '../providers/game_session_provider.dart';
import '../widgets/app_safe_area.dart';

class HangarOverlay extends ConsumerWidget {
  const HangarOverlay({super.key, required this.game});

  final NebulaStrikeGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highScoreAsync = ref.watch(highScoreProvider);
    final selectedShip = ref.watch(selectedShipProvider);

    return ColoredBox(
      color: const Color(0xE6060A14),
      child: AppSafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                      tooltip: 'Back to Mini Games',
                      onPressed: () {
                        GameAudio.unlock();
                        GameAudio.uiConfirm();
                        Navigator.of(context).maybePop();
                      },
                    ),
                    TextButton.icon(
                      onPressed: () {
                        GameAudio.unlock();
                        GameAudio.uiConfirm();
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 20),
                      label: const Text(
                        'MAIN MENU',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'NEBULA STRIKE',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: const Color(0xFF74C0FC),
                    ),
              ),
              const Text(
                'Horizontal Side-Scroll Shooter',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              highScoreAsync.when(
                data: (score) => Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2740).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x33FFD43B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, color: Color(0xFFFFD43B)),
                      const SizedBox(width: 8),
                      Text(
                        'HIGH SCORE: $score',
                        style: const TextStyle(
                          color: Color(0xFFFFD43B),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              const Text(
                'SELECT SHIP',
                style: TextStyle(
                  color: Colors.white54,
                  letterSpacing: 2,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  children: ShipType.values
                      .map(
                        (ship) => _ShipCard(
                          ship: ship,
                          selected: selectedShip == ship,
                          onTap: () {
                            GameAudio.unlock();
                            GameAudio.uiConfirm();
                            ref.read(selectedShipProvider.notifier).select(ship);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  GameAudio.unlock();
                  GameAudio.uiConfirm();
                  game.showMissionSelect();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: const Color(0xFF4C6EF5),
                ),
                icon: const Icon(Icons.map_rounded),
                label: const Text(
                  'SELECT MISSION',
                  style: TextStyle(fontSize: 16, letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '5 campaign missions · endless mode · phased objectives',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShipCard extends StatelessWidget {
  const _ShipCard({
    required this.ship,
    required this.selected,
    required this.onTap,
  });

  final ShipType ship;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? const Color(0xFF2B3F6B).withValues(alpha: 0.92)
            : const Color(0xFF1E2740).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? const Color(0xFF74C0FC) : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CustomPaint(painter: _ShipPreviewPainter(ship)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ship.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        ship.description,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: Color(0xFF51CF66)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShipPreviewPainter extends CustomPainter {
  _ShipPreviewPainter(this.ship);
  final ShipType ship;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.1, size.height * 0.1);
    ShipPainter.paintPlayer(
      canvas,
      Size(size.width * 0.8, size.height * 0.8),
      ship,
      thrust: 0.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShipPreviewPainter oldDelegate) =>
      oldDelegate.ship != ship;
}
