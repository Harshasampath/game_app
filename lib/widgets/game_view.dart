import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'car_widget.dart';
import 'obstacle_widget.dart';

class GameView extends StatelessWidget {
  final GameState gameState;

  const GameView({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gameState,
      builder: (context, child) {
        return Container(
          color: Colors.grey[300],
          child: Stack(
            children: [
              // Road markings
              ...List.generate(
                5,
                (index) => Positioned(
                  top: (index * 160.0 + gameState.roadOffset) % 800 - 80,
                  left: MediaQuery.of(context).size.width / 2 - 2,
                  child: Container(
                    width: 4,
                    height: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Car
              CarWidget(
                position: gameState.carPosition,
              ),
              
              // Obstacles
              ...gameState.obstacles.map(
                (obstacle) => ObstacleWidget(
                  position: obstacle.position,
                ),
              ),
              
              // Score
              Positioned(
                top: 20,
                right: 20,
                child: Text(
                  'Score: ${gameState.score}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              if (gameState.isGameOver)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Game Over!\nTap to restart',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}