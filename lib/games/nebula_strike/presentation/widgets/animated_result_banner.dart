import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

import 'app_safe_area.dart';
import 'victory_celebration.dart';

/// Animated headline for win / lose result screens.
class AnimatedResultBanner extends StatefulWidget {
  const AnimatedResultBanner({
    super.key,
    required this.message,
    required this.isVictory,
    required this.accentColor,
  });

  final String message;
  final bool isVictory;
  final Color accentColor;

  @override
  State<AnimatedResultBanner> createState() => _AnimatedResultBannerState();
}

class _AnimatedResultBannerState extends State<AnimatedResultBanner>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _shake;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: widget.isVictory
          ? const Duration(milliseconds: 900)
          : const Duration(milliseconds: 700),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isVictory) {
      _scale = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12), weight: 55),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 45),
      ]).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOut));
      _shake = const AlwaysStoppedAnimation(0);
    } else {
      _scale = Tween<double>(begin: 1.35, end: 1.0).animate(
        CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
      );
      _shake = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: -14), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -14, end: 14), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 14, end: -10), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 1),
      ]).animate(CurvedAnimation(parent: _enter, curve: Curves.easeInOut));
    }

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );

    _glow = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _enter.forward();
    _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _pulse]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(_shake.value, 0),
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.isVictory) ..._victoryRays(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.45 * _glow.value),
                  blurRadius: 28 * _glow.value,
                  spreadRadius: 4 * _glow.value,
                ),
              ],
            ),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppTypography.orbitron(
                color: widget.accentColor,
                fontSize: widget.isVictory ? 26 : 30,
                fontWeight: FontWeight.w900,
                letterSpacing: widget.isVictory ? 3 : 4,
                height: 1.1,
                shadows: [
                  Shadow(
                    color: widget.accentColor.withValues(alpha: 0.6 * _glow.value),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _victoryRays() {
    return List.generate(8, (i) {
      final angle = i * math.pi / 4 + _pulse.value * 0.4;
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: 4,
          height: 72,
          margin: const EdgeInsets.only(bottom: 48),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.accentColor.withValues(alpha: 0.0),
                widget.accentColor.withValues(alpha: 0.35 * _glow.value),
                widget.accentColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Full-screen tinted backdrop that fades in behind result overlays.
class AnimatedResultBackdrop extends StatefulWidget {
  const AnimatedResultBackdrop({
    super.key,
    required this.isVictory,
    required this.child,
  });

  final bool isVictory;
  final Widget child;

  @override
  State<AnimatedResultBackdrop> createState() => _AnimatedResultBackdropState();
}

class _AnimatedResultBackdropState extends State<AnimatedResultBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _flash;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _flash = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.22), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.22, end: 0.08), weight: 70),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.isVictory
        ? const Color(0xFF4ADE80)
        : const Color(0xFFFF6B6B);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.72 + _fade.value * 0.15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.isVictory) const VictoryConfetti(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 1.1,
                    colors: [
                      tint.withValues(alpha: _flash.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              AppSafeArea(
                bottom: false,
                child: Opacity(opacity: _fade.value, child: child),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
