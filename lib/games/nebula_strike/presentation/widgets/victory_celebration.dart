import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-screen confetti burst for mission victory.
class VictoryConfetti extends StatefulWidget {
  const VictoryConfetti({super.key});

  @override
  State<VictoryConfetti> createState() => _VictoryConfettiState();
}

class _VictoryConfettiState extends State<VictoryConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;
  final _random = math.Random(7);

  static const _palette = [
    Color(0xFF4ADE80),
    Color(0xFFFFD43B),
    Color(0xFF38BDF8),
    Color(0xFFC084FC),
    Color(0xFFF97316),
    Color(0xFFFDE047),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _pieces = List.generate(56, (i) {
      return _ConfettiPiece(
        x: _random.nextDouble(),
        y: -0.05 - _random.nextDouble() * 0.4,
        speed: 0.12 + _random.nextDouble() * 0.22,
        sway: 0.4 + _random.nextDouble() * 1.2,
        swayPhase: _random.nextDouble() * math.pi * 2,
        spin: (_random.nextDouble() - 0.5) * 6,
        size: 5 + _random.nextDouble() * 7,
        color: _palette[i % _palette.length],
        delay: _random.nextDouble() * 0.35,
        isCircle: _random.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              pieces: _pieces,
              t: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.y,
    required this.speed,
    required this.sway,
    required this.swayPhase,
    required this.spin,
    required this.size,
    required this.color,
    required this.delay,
    required this.isCircle,
  });

  final double x;
  final double y;
  final double speed;
  final double sway;
  final double swayPhase;
  final double spin;
  final double size;
  final Color color;
  final double delay;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.t});

  final List<_ConfettiPiece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final localT = ((t - p.delay) % 1.0);
      if (localT < 0) continue;

      final fallY = (p.y + localT * p.speed * 2.8) % 1.15;
      final dx = math.sin(localT * math.pi * 2 * p.sway + p.swayPhase) * 24;
      final px = p.x * size.width + dx;
      final py = fallY * size.height;

      final fade = fallY > 1.0
          ? 0.0
          : (1 - (fallY - 0.85).clamp(0.0, 0.15) / 0.15).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(localT * p.spin);
      final paint = Paint()..color = p.color.withValues(alpha: 0.85 * fade);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Stars that pop in one-by-one on victory.
class AnimatedVictoryStars extends StatefulWidget {
  const AnimatedVictoryStars({super.key, required this.stars});

  final int stars;

  @override
  State<AnimatedVictoryStars> createState() => _AnimatedVictoryStarsState();
}

class _AnimatedVictoryStarsState extends State<AnimatedVictoryStars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    });
    _playSequence();
  }

  Future<void> _playSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      _controllers[i].forward();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < widget.stars;
        final scale = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25), weight: 60),
          TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 40),
        ]).animate(CurvedAnimation(parent: _controllers[i], curve: Curves.easeOut));

        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            return Transform.scale(
              scale: filled ? scale.value : 1.0,
              child: Opacity(
                opacity: filled ? _controllers[i].value.clamp(0.0, 1.0) : 0.55,
                child: child,
              ),
            );
          },
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            color: const Color(0xFFFFD43B),
            size: 30,
          ),
        );
      }),
    );
  }
}

/// Pulsing trophy icon for the win screen header.
class AnimatedVictoryTrophy extends StatefulWidget {
  const AnimatedVictoryTrophy({super.key});

  @override
  State<AnimatedVictoryTrophy> createState() => _AnimatedVictoryTrophyState();
}

class _AnimatedVictoryTrophyState extends State<AnimatedVictoryTrophy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: -4, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: child,
        );
      },
      child: Icon(
        Icons.emoji_events_rounded,
        color: const Color(0xFFFFD43B).withValues(alpha: 0.9),
        size: 28,
      ),
    );
  }
}
