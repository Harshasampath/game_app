import 'dart:ui';

import 'package:flutter/painting.dart';

import '../../domain/entities/ship_type.dart';
import 'vfx_utils.dart';

/// Detailed side-view sci-fi fighters — player faces right, enemies face left.
class ShipPainter {
  static void paintPlayer(Canvas canvas, Size size, ShipType type, {double thrust = 0}) {
    canvas.save();
    switch (type) {
      case ShipType.interceptor:
        _paintInterceptor(canvas, size, thrust);
      case ShipType.guardian:
        _paintGuardian(canvas, size, thrust);
      case ShipType.striker:
        _paintStriker(canvas, size, thrust);
    }
    canvas.restore();
  }

  static void paintEnemy(Canvas canvas, Size size, EnemyShipStyle style) {
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    switch (style) {
      case EnemyShipStyle.scout:
        _paintScout(canvas, size);
      case EnemyShipStyle.weaver:
        _paintWeaver(canvas, size);
      case EnemyShipStyle.hunter:
        _paintHunter(canvas, size);
      case EnemyShipStyle.boss:
        _paintBoss(canvas, size);
    }
    canvas.restore();
  }

  static void _paintInterceptor(Canvas canvas, Size size, double thrust) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    final hull = Path()
      ..moveTo(w * 0.08, cy)
      ..lineTo(w * 0.28, cy - h * 0.22)
      ..lineTo(w * 0.62, cy - h * 0.12)
      ..lineTo(w * 0.88, cy)
      ..lineTo(w * 0.62, cy + h * 0.12)
      ..lineTo(w * 0.28, cy + h * 0.22)
      ..close();

    VfxUtils.drawGlowPath(canvas, hull, const Color(0xFF38BDF8), blur: 10, opacity: 0.35);
    VfxUtils.fillPathGradient(
      canvas,
      hull,
      const [Color(0xFF0C4A6E), Color(0xFF0284C7), Color(0xFF7DD3FC), Color(0xFF0369A1)],
    );
    VfxUtils.strokePath(canvas, hull, const Color(0xFFE0F2FE), width: 1.2, opacity: 0.7);

    final wingTop = Path()
      ..moveTo(w * 0.32, cy - h * 0.18)
      ..lineTo(w * 0.55, cy - h * 0.38)
      ..lineTo(w * 0.58, cy - h * 0.14)
      ..close();
    final wingBot = Path()
      ..moveTo(w * 0.32, cy + h * 0.18)
      ..lineTo(w * 0.55, cy + h * 0.38)
      ..lineTo(w * 0.58, cy + h * 0.14)
      ..close();
    VfxUtils.fillPathGradient(canvas, wingTop, const [Color(0xFF075985), Color(0xFF38BDF8)]);
    VfxUtils.fillPathGradient(canvas, wingBot, const [Color(0xFF075985), Color(0xFF38BDF8)]);

    final cockpit = Path()
      ..addOval(Rect.fromCenter(center: Offset(w * 0.52, cy - h * 0.04), width: w * 0.14, height: h * 0.18));
    canvas.drawPath(
      cockpit,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFBAE6FD), Color(0xFF0EA5E9), Color(0xFF082F49)],
        ).createShader(Rect.fromCenter(center: Offset(w * 0.52, cy), width: w * 0.2, height: h * 0.2)),
    );

    _engineFlame(canvas, Offset(w * 0.06, cy), h * 0.14, thrust, const Color(0xFF22D3EE), const Color(0xFFF97316));

    canvas.drawCircle(Offset(w * 0.78, cy), 2.5, Paint()..color = const Color(0xFFEF4444));
  }

  static void _paintGuardian(Canvas canvas, Size size, double thrust) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    final hull = Path()
      ..moveTo(w * 0.1, cy)
      ..lineTo(w * 0.22, cy - h * 0.28)
      ..lineTo(w * 0.7, cy - h * 0.22)
      ..lineTo(w * 0.86, cy)
      ..lineTo(w * 0.7, cy + h * 0.22)
      ..lineTo(w * 0.22, cy + h * 0.28)
      ..close();

    VfxUtils.drawGlowPath(canvas, hull, const Color(0xFF94A3B8), blur: 8, opacity: 0.3);
    VfxUtils.fillPathGradient(
      canvas,
      hull,
      const [Color(0xFF1E293B), Color(0xFF475569), Color(0xFF94A3B8), Color(0xFF334155)],
    );
    VfxUtils.strokePath(canvas, hull, const Color(0xFFCBD5E1), width: 1.5, opacity: 0.5);

    for (final dy in [-0.14, 0.14]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.42, cy + h * dy), width: w * 0.22, height: h * 0.1),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF64748B),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.55, cy), width: w * 0.12, height: h * 0.2),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: const [Color(0xFF38BDF8), Color(0xFF0F172A)],
        ).createShader(Rect.fromCenter(center: Offset(w * 0.55, cy), width: w * 0.12, height: h * 0.2)),
    );

    _engineFlame(canvas, Offset(w * 0.04, cy), h * 0.18, thrust, const Color(0xFF4ADE80), const Color(0xFF22C55E));
    _engineFlame(canvas, Offset(w * 0.04, cy - h * 0.12), h * 0.08, thrust * 0.7, const Color(0xFF4ADE80), const Color(0xFF16A34A));
    _engineFlame(canvas, Offset(w * 0.04, cy + h * 0.12), h * 0.08, thrust * 0.7, const Color(0xFF4ADE80), const Color(0xFF16A34A));
  }

  static void _paintStriker(Canvas canvas, Size size, double thrust) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    final hull = Path()
      ..moveTo(w * 0.12, cy)
      ..lineTo(w * 0.35, cy - h * 0.2)
      ..lineTo(w * 0.75, cy - h * 0.08)
      ..lineTo(w * 0.9, cy)
      ..lineTo(w * 0.75, cy + h * 0.08)
      ..lineTo(w * 0.35, cy + h * 0.2)
      ..close();

    VfxUtils.drawGlowPath(canvas, hull, const Color(0xFFEF4444), blur: 12, opacity: 0.4);
    VfxUtils.fillPathGradient(
      canvas,
      hull,
      const [Color(0xFF450A0A), Color(0xFFDC2626), Color(0xFFF87171), Color(0xFF991B1B)],
    );
    VfxUtils.strokePath(canvas, hull, const Color(0xFFFECACA), width: 1, opacity: 0.6);

    final gunPod = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.68, cy - h * 0.16), width: w * 0.2, height: h * 0.08),
        const Radius.circular(2),
      ));
    canvas.drawPath(gunPod, Paint()..color = const Color(0xFF7F1D1D));
    canvas.drawCircle(Offset(w * 0.78, cy - h * 0.16), 3, Paint()..color = const Color(0xFFFBBF24));

    _engineFlame(canvas, Offset(w * 0.05, cy), h * 0.16, thrust, const Color(0xFFFBBF24), const Color(0xFFEA580C));
  }

  static void _paintScout(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    final body = Path()
      ..moveTo(w * 0.15, cy)
      ..quadraticBezierTo(w * 0.4, cy - h * 0.35, w * 0.85, cy)
      ..quadraticBezierTo(w * 0.4, cy + h * 0.35, w * 0.15, cy)
      ..close();

    VfxUtils.fillPathGradient(canvas, body, const [Color(0xFF14532D), Color(0xFF22C55E), Color(0xFF4ADE80)]);
    VfxUtils.strokePath(canvas, body, const Color(0xFFBBF7D0), opacity: 0.5);

    canvas.drawCircle(Offset(w * 0.72, cy), 4, Paint()..color = const Color(0xFFEF4444));
    VfxUtils.drawGlowCircle(canvas, Offset(w * 0.72, cy), 6, const Color(0xFFEF4444), blur: 8, opacity: 0.6);

    _engineFlame(canvas, Offset(w * 0.08, cy), h * 0.08, 0.6, const Color(0xFF4ADE80), const Color(0xFF16A34A));
  }

  static void _paintWeaver(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    final body = Path()
      ..moveTo(w * 0.1, cy)
      ..lineTo(w * 0.35, cy - h * 0.3)
      ..lineTo(w * 0.65, cy - h * 0.1)
      ..lineTo(w * 0.88, cy - h * 0.2)
      ..lineTo(w * 0.7, cy + h * 0.15)
      ..lineTo(w * 0.3, cy + h * 0.25)
      ..close();

    VfxUtils.drawGlowPath(canvas, body, const Color(0xFFC084FC), blur: 10, opacity: 0.35);
    VfxUtils.fillPathGradient(canvas, body, const [Color(0xFF581C87), Color(0xFFA855F7), Color(0xFFE879F9)]);
    VfxUtils.strokePath(canvas, body, const Color(0xFFF3E8FF), opacity: 0.45);

    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * (0.45 + i * 0.12), cy + (i - 1) * 4),
        2,
        Paint()..color = const Color(0xFFFDE047),
      );
    }
  }

  static void _paintHunter(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    final hull = Path()
      ..moveTo(w * 0.08, cy)
      ..lineTo(w * 0.3, cy - h * 0.25)
      ..lineTo(w * 0.72, cy - h * 0.18)
      ..lineTo(w * 0.92, cy)
      ..lineTo(w * 0.72, cy + h * 0.18)
      ..lineTo(w * 0.3, cy + h * 0.25)
      ..close();

    VfxUtils.fillPathGradient(canvas, hull, const [Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFFDBA74)]);
    VfxUtils.strokePath(canvas, hull, const Color(0xFFFFEDD5), opacity: 0.5);

    final cannon = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.82, cy), width: w * 0.18, height: h * 0.12),
        const Radius.circular(3),
      ));
    canvas.drawPath(cannon, Paint()..color = const Color(0xFF431407));
    canvas.drawCircle(Offset(w * 0.9, cy), 3.5, Paint()..color = const Color(0xFFFACC15));

    _engineFlame(canvas, Offset(w * 0.02, cy), h * 0.1, 0.5, const Color(0xFFF97316), const Color(0xFFDC2626));
  }

  static void _paintBoss(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    final hull = Path()
      ..moveTo(w * 0.05, cy)
      ..lineTo(w * 0.18, cy - h * 0.35)
      ..lineTo(w * 0.55, cy - h * 0.38)
      ..lineTo(w * 0.92, cy - h * 0.1)
      ..lineTo(w * 0.95, cy)
      ..lineTo(w * 0.92, cy + h * 0.1)
      ..lineTo(w * 0.55, cy + h * 0.38)
      ..lineTo(w * 0.18, cy + h * 0.35)
      ..close();

    VfxUtils.drawGlowPath(canvas, hull, const Color(0xFF7C3AED), blur: 16, opacity: 0.45);
    VfxUtils.fillPathGradient(
      canvas,
      hull,
      const [Color(0xFF312E81), Color(0xFF6D28D9), Color(0xFF8B5CF6), Color(0xFF4C1D95)],
    );
    VfxUtils.strokePath(canvas, hull, const Color(0xFFDDD6FE), width: 2, opacity: 0.55);

    final bridge = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.55, cy - h * 0.12), width: w * 0.2, height: h * 0.14),
        const Radius.circular(4),
      ));
    canvas.drawPath(
      bridge,
      Paint()
        ..shader = LinearGradient(
          colors: const [Color(0xFFEF4444), Color(0xFF7F1D1D)],
        ).createShader(Rect.fromCenter(center: Offset(w * 0.55, cy), width: w * 0.2, height: h * 0.14)),
    );

    for (final dy in [-0.22, 0.22]) {
      _engineFlame(canvas, Offset(w * 0.02, cy + h * dy), h * 0.12, 0.8, const Color(0xFFA78BFA), const Color(0xFFEF4444));
      canvas.drawCircle(Offset(w * 0.78, cy + h * dy), 5, Paint()..color = const Color(0xFFEF4444));
      VfxUtils.drawGlowCircle(canvas, Offset(w * 0.78, cy + h * dy), 8, const Color(0xFFEF4444), blur: 6, opacity: 0.5);
    }

    canvas.drawRect(
      Rect.fromCenter(center: Offset(w * 0.55, cy - h * 0.32), width: w * 0.12, height: h * 0.08),
      Paint()..color = const Color(0xFFFBBF24),
    );
  }

  static void _engineFlame(
    Canvas canvas,
    Offset nozzle,
    double height,
    double thrust,
    Color core,
    Color outer,
  ) {
    final len = height * (0.6 + thrust * 0.9);
    final flame = Path()
      ..moveTo(nozzle.dx, nozzle.dy - height * 0.35)
      ..lineTo(nozzle.dx - len, nozzle.dy)
      ..lineTo(nozzle.dx, nozzle.dy + height * 0.35)
      ..close();

    VfxUtils.drawGlowPath(canvas, flame, outer, blur: 8, opacity: 0.7);
    canvas.drawPath(flame, Paint()..color = outer.withValues(alpha: 0.85));
    canvas.drawPath(
      Path()
        ..moveTo(nozzle.dx, nozzle.dy - height * 0.2)
        ..lineTo(nozzle.dx - len * 0.55, nozzle.dy)
        ..lineTo(nozzle.dx, nozzle.dy + height * 0.2)
        ..close(),
      Paint()..color = core,
    );
  }
}

enum EnemyShipStyle { scout, weaver, hunter, boss }
