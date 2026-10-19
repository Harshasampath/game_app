import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Curves;
import 'package:flutter/painting.dart';

enum _BannerStyle { standard, largePhase }

/// Full-screen wave / phase announcement — must live on [FlameGame], not [CombatSession].
class WaveBannerComponent extends Component with HasGameReference<FlameGame> {
  WaveBannerComponent() : super(priority: 10000);

  String _eyebrow = '';
  String _title = '';
  String _subtitle = '';
  String _detail = '';
  double _timer = 0;
  double _duration = 2.2;
  _BannerStyle _style = _BannerStyle.standard;
  bool _compact = false;
  bool _lowerCenter = false;

  Color _titleColor = const Color(0xFF38BDF8);
  Color _subtitleColor = const Color(0xFF94A3B8);

  bool get isVisible => _timer > 0;

  void dismiss() {
    _timer = 0;
    _eyebrow = '';
    _style = _BannerStyle.standard;
    _compact = false;
    _lowerCenter = false;
  }

  void show({
    required String title,
    required String subtitle,
    double duration = 2.2,
    Color titleColor = const Color(0xFF38BDF8),
    Color subtitleColor = const Color(0xFF94A3B8),
    bool compact = false,
  }) {
    _style = _BannerStyle.standard;
    _compact = compact;
    _eyebrow = '';
    _title = title;
    _subtitle = subtitle;
    _detail = '';
    _duration = duration;
    _timer = duration;
    _titleColor = titleColor;
    _subtitleColor = subtitleColor;
  }

  /// Mission / phase start — e.g. "PHASE 01" when combat first begins.
  void showPhaseNumber({
    required int phaseNumber,
    required int totalPhases,
    required String phaseName,
    String? objective,
    double duration = 2.4,
  }) {
    _style = _BannerStyle.largePhase;
    _compact = false;
    _lowerCenter = false;
    _eyebrow = '';
    _title = 'PHASE ${phaseNumber.toString().padLeft(2, '0')}';
    _subtitle = phaseName.toUpperCase();
    _detail = objective ?? '';
    _duration = duration;
    _timer = duration;
    _titleColor = const Color(0xFF4ADE80);
    _subtitleColor = const Color(0xFFC084FC);
  }

  /// Between phases — phase-1 card format, positioned lower to clear the HUD.
  void showNextPhaseIntermission({
    required int phaseNumber,
    required String phaseName,
    String? objective,
    required double duration,
  }) {
    _style = _BannerStyle.largePhase;
    _compact = false;
    _lowerCenter = true;
    _eyebrow = 'NEXT PHASE';
    _title = 'PHASE ${phaseNumber.toString().padLeft(2, '0')}';
    _subtitle = phaseName.toUpperCase();
    _detail = objective ?? '';
    _duration = duration;
    _timer = duration;
    _titleColor = const Color(0xFF4ADE80);
    _subtitleColor = const Color(0xFFC084FC);
  }

  void showEndlessWave({required int wave, double duration = 2.4}) {
    _style = _BannerStyle.largePhase;
    _compact = false;
    _lowerCenter = true;
    _eyebrow = 'NEXT WAVE';
    _title = 'WAVE ${wave.toString().padLeft(2, '0')}';
    _subtitle = 'ENDLESS SORTIE';
    _detail = 'Difficulty rising — stay sharp';
    _duration = duration;
    _timer = duration;
    _titleColor = const Color(0xFFF97316);
    _subtitleColor = const Color(0xFFFBBF24);
  }

  @override
  void update(double dt) {
    if (_timer > 0) _timer -= dt;
  }

  @override
  void render(Canvas canvas) {
    if (_timer <= 0) return;

    final size = game.size;
    final fadeOut = (_timer > 0.35 ? 1.0 : _timer / 0.35).clamp(0.0, 1.0);
    final progress = (1 - _timer / _duration).clamp(0.0, 1.0);
    final popIn = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));

    switch (_style) {
      case _BannerStyle.largePhase:
        final overlayAlpha = 0.26;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          Paint()..color = Color.fromRGBO(0, 0, 0, overlayAlpha * fadeOut),
        );
        _paintLargePhase(canvas, size, fadeOut, popIn);
      case _BannerStyle.standard:
        final overlayAlpha = _compact ? 0.12 : 0.26;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.x, size.y),
          Paint()..color = Color.fromRGBO(0, 0, 0, overlayAlpha * fadeOut),
        );
        _paintStandard(canvas, size, fadeOut);
    }
  }

  void _paintLargePhase(Canvas canvas, Vector2 size, double alpha, double popIn) {
    const gap = 8.0;
    const padV = 14.0;
    const padH = 22.0;

    final titleSize = (size.x * 0.052).clamp(26.0, 38.0);

    final lines = <TextPainter>[];

    if (_eyebrow.isNotEmpty) {
      lines.add(
        TextPainter(
          text: TextSpan(
            text: _eyebrow,
            style: TextStyle(
              color: const Color(0xFF7DD3FC).withValues(alpha: alpha * 0.9),
              fontSize: (titleSize * 0.38).clamp(10.0, 12.0),
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
    }

    lines.addAll([
      TextPainter(
        text: TextSpan(
          text: _title,
          style: TextStyle(
            color: _titleColor.withValues(alpha: alpha),
            fontSize: titleSize * (0.85 + 0.15 * popIn),
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x * 0.46),
      TextPainter(
        text: TextSpan(
          text: _subtitle,
          style: TextStyle(
            color: _subtitleColor.withValues(alpha: alpha * 0.95),
            fontSize: (titleSize * 0.42).clamp(11.0, 14.0),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x * 0.46),
    ]);

    if (_detail.isNotEmpty) {
      lines.add(
        TextPainter(
          text: TextSpan(
            text: _detail,
            style: TextStyle(
              color: const Color(0xFF94A3B8).withValues(alpha: alpha * 0.85),
              fontSize: (titleSize * 0.34).clamp(10.0, 12.0),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: size.x * 0.46),
      );
    }

    final contentH = lines.fold<double>(0, (h, p) => h + p.height) + gap * (lines.length - 1);
    final contentW = lines.fold<double>(0, (w, p) => p.width > w ? p.width : w);
    final panelW = (contentW + padH * 2).clamp(size.x * 0.34, size.x * 0.52);
    final panelH = contentH + padV * 2;
    final centerY = size.y * (_lowerCenter ? 0.62 : 0.44);

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.x / 2, centerY),
        width: panelW,
        height: panelH,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      panelRect,
      Paint()..color = Color.fromRGBO(8, 12, 28, 0.72 * alpha),
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.22 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    var y = panelRect.top + padV;
    for (var i = 0; i < lines.length; i++) {
      final painter = lines[i];
      painter.paint(canvas, Offset(panelRect.center.dx - painter.width / 2, y));
      y += painter.height + (i < lines.length - 1 ? gap : 0);
    }
  }

  void _paintStandard(Canvas canvas, Vector2 size, double alpha) {
    final centerY = size.y * 0.4;

    if (_compact) {
      const gap = 6.0;
      const padV = 10.0;
      const padH = 16.0;
      const titleSize = 20.0;
      const subSize = 12.0;

      final titlePainter = TextPainter(
        text: TextSpan(
          text: _title,
          style: TextStyle(
            color: _titleColor.withValues(alpha: alpha),
            fontSize: titleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: size.x * 0.4);

      TextPainter? subPainter;
      if (_subtitle.isNotEmpty) {
        subPainter = TextPainter(
          text: TextSpan(
            text: _subtitle,
            style: TextStyle(
              color: _subtitleColor.withValues(alpha: alpha),
              fontSize: subSize,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: size.x * 0.4);
      }

      final contentH =
          titlePainter.height + (subPainter != null ? gap + subPainter.height : 0);
      final contentW = [titlePainter.width, subPainter?.width ?? 0]
          .reduce((a, b) => a > b ? a : b);
      final panelW = (contentW + padH * 2).clamp(size.x * 0.36, size.x * 0.5);
      final panelH = contentH + padV * 2;

      final panelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.x / 2, centerY),
          width: panelW,
          height: panelH,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        panelRect,
        Paint()..color = Color.fromRGBO(8, 12, 28, 0.78 * alpha),
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = _titleColor.withValues(alpha: 0.35 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      var y = panelRect.top + (panelH - contentH) / 2;
      titlePainter.paint(
        canvas,
        Offset(panelRect.center.dx - titlePainter.width / 2, y),
      );
      if (subPainter != null) {
        y += titlePainter.height + gap;
        subPainter.paint(
          canvas,
          Offset(panelRect.center.dx - subPainter.width / 2, y),
        );
      }
      return;
    }

    final titleSize = 24.0;
    final subSize = 13.0;

    _paintCenteredText(
      canvas,
      size,
      _title,
      centerY - 10,
      TextStyle(
        color: _titleColor.withValues(alpha: alpha),
        fontSize: titleSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    );

    if (_subtitle.isNotEmpty) {
      _paintCenteredText(
        canvas,
        size,
        _subtitle,
        centerY + 14,
        TextStyle(
          color: _subtitleColor.withValues(alpha: alpha),
          fontSize: subSize,
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
        ),
      );
    }
  }

  void _paintCenteredText(
    Canvas canvas,
    Vector2 size,
    String text,
    double y,
    TextStyle style, {
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth ?? size.x);
    painter.paint(canvas, Offset((size.x - painter.width) / 2, y));
  }
}
