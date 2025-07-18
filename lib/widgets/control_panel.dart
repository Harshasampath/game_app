import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onLeftPressed;
  final VoidCallback onRightPressed;

  const ControlPanel({
    super.key,
    required this.onLeftPressed,
    required this.onRightPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: onLeftPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.arrow_left, size: 32),
          ),
          ElevatedButton(
            onPressed: onRightPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.arrow_right, size: 32),
          ),
        ],
      ),
    );
  }
}