import 'package:flutter/material.dart';
import '../widgets/game_view.dart';
import '../widgets/control_panel.dart';
import '../models/game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  final GameState gameState = GameState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: GameView(gameState: gameState),
          ),
          Expanded(
            flex: 1,
            child: ControlPanel(
              onLeftPressed: gameState.moveLeft,
              onRightPressed: gameState.moveRight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    gameState.dispose();
    super.dispose();
  }
}