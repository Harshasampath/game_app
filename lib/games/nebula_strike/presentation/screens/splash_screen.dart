import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

import '../../domain/entities/ship_type.dart';
import '../widgets/app_safe_area.dart';
import '../../game/rendering/ship_painter.dart';

/// Branded launch screen shown once when the app opens.
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    required this.fade,
    required this.logoScale,
  });

  final double fade;
  final double logoScale;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF060A14),
                Color(0xFF0B1026),
                Color(0xFF121A35),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _StarField(),
              AppSafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Transform.scale(
                      scale: logoScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 72,
                            child: CustomPaint(
                              painter: _SplashShipPainter(),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'NEBULA STRIKE',
                            textAlign: TextAlign.center,
                            style: AppTypography.orbitron(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: const Color(0xFF74C0FC),
                              shadows: const [
                                Shadow(
                                  color: Color(0x6638BDF8),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'HORIZONTAL SIDE-SCROLL SHOOTER',
                            textAlign: TextAlign.center,
                            style: AppTypography.orbitron(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 4),
                    SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: const Color(0xFF1E293B),
                          color: const Color(0xFF38BDF8).withValues(alpha: fade),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [SplashScreen] on launch, then reveals [child] with a fade.
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    this.holdDuration = const Duration(milliseconds: 2400),
    this.fadeDuration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final Duration holdDuration;
  final Duration fadeDuration;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );

    Future<void>.delayed(widget.holdDuration, () async {
      if (!mounted) return;
      await _controller.forward();
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = 1.0 - Curves.easeIn.transform(_controller.value);
    final logoScale = 0.88 + 0.12 * (1.0 - fade);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_showSplash)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => SplashScreen(
                fade: fade,
                logoScale: logoScale,
              ),
            ),
        ],
      ),
    );
  }
}

class _SplashShipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    ShipPainter.paintPlayer(canvas, size, ShipType.interceptor, thrust: 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarField extends StatelessWidget {
  const _StarField();

  static final _stars = List.generate(48, (i) {
    final r = math.Random(i + 7);
    return (
      x: r.nextDouble(),
      y: r.nextDouble(),
      radius: r.nextDouble() * 1.4 + 0.4,
      alpha: r.nextDouble() * 0.45 + 0.15,
    );
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarFieldPainter(_stars),
      size: Size.infinite,
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter(this.stars);

  final List<({double x, double y, double radius, double alpha})> stars;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      paint.color = Color.fromRGBO(180, 210, 255, star.alpha);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => false;
}
