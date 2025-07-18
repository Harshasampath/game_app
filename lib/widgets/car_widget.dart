import 'package:flutter/material.dart';

class CarWidget extends StatelessWidget {
  final double position;

  const CarWidget({
    super.key,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: position,
      child: SizedBox(
        width: 60,
        height: 100,
        child: CustomPaint(
          painter: CarPainter(),
        ),
      ),
    );
  }
}

class CarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    // Car body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 20, 50, 70),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, paint);

    // Windows
    paint.color = Colors.lightBlueAccent;
    canvas.drawRect(
      Rect.fromLTWH(10, 30, 40, 20),
      paint,
    );

    // Wheels
    paint.color = Colors.black;
    canvas.drawCircle(Offset(15, 85), 8, paint);
    canvas.drawCircle(Offset(45, 85), 8, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}