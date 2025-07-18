import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math';
import 'position.dart';
import 'obstacle.dart';

class GameState extends ChangeNotifier {
  static const double carSpeed = 15.0;
  static const double obstacleSpeed = 5.0;
  
  double carPosition = 150.0;
  double roadOffset = 0.0;
  List<Obstacle> obstacles = [];
  int score = 0;
  bool isGameOver = false;
  
  final Random random = Random();
  late final Timer gameTimer;

  GameState() {
    startGame();
  }

  void startGame() {
    obstacles.clear();
    score = 0;
    isGameOver = false;
    carPosition = 150.0;
    
    gameTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) => _update(),
    );
  }

  void _update() {
    if (isGameOver) return;

    // Update road animation
    roadOffset = (roadOffset + 5) % 160;

    // Update obstacles
    for (var obstacle in obstacles) {
      obstacle.update(obstacleSpeed);
    }

    // Remove obstacles that are off screen
    obstacles.removeWhere((obstacle) => obstacle.position.y > 800);

    // Add new obstacles
    if (random.nextDouble() < 0.02) {
      obstacles.add(
        Obstacle(
          Position(
            random.nextDouble() * 300,
            -50,
          ),
        ),
      );
    }

    // Check collisions
    for (var obstacle in obstacles) {
      if (_checkCollision(obstacle)) {
        _gameOver();
        break;
      }
    }

    // Increase score
    score++;
    
    notifyListeners();
  }

  bool _checkCollision(Obstacle obstacle) {
    const carWidth = 60.0;
    const carHeight = 100.0;
    const obstacleSize = 50.0;

    return (obstacle.position.y + obstacleSize > 700 &&
        obstacle.position.y < 700 + carHeight &&
        obstacle.position.x + obstacleSize > carPosition &&
        obstacle.position.x < carPosition + carWidth);
  }

  void _gameOver() {
    isGameOver = true;
    gameTimer.cancel();
    notifyListeners();
  }

  void moveLeft() {
    if (isGameOver) {
      startGame();
      return;
    }
    
    if (carPosition > 0) {
      carPosition -= carSpeed;
      notifyListeners();
    }
  }

  void moveRight() {
    if (isGameOver) {
      startGame();
      return;
    }
    
    if (carPosition < 300) {
      carPosition += carSpeed;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }
}