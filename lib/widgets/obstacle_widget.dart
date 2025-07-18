import 'package:flutter/material.dart';
import '../models/position.dart';

class ObstacleWidget extends StatelessWidget {
  final Position position;

  const ObstacleWidget({
    super.key,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.x,
      top: position.y,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.brown,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}