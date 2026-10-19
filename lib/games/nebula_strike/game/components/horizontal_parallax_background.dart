import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../domain/entities/mission_background_theme.dart';
import '../rendering/vfx_utils.dart';

/// Deep-space nebula backdrop with multi-layer parallax, asteroids, and warp streaks.
class HorizontalParallaxBackground extends Component {
  HorizontalParallaxBackground({
    required this.viewportSize,
    MissionBackgroundTheme? theme,
  }) : _theme = theme ?? MissionBackgroundThemes.training;

  final Vector2 viewportSize;
  MissionBackgroundTheme _theme;
  double scrollX = 0;
  double elapsed = 0;

  MissionBackgroundTheme get theme => _theme;

  void applyTheme(MissionBackgroundTheme theme) {
    _theme = theme;
    scrollX = 0;
    _regenerateNebulae();
    _starsFar = List.generate(120, (_) => _spawnStar(0.4, 1.2));
    _starsMid = List.generate(80, (_) => _spawnStar(0.8, 2.0));
    _starsNear = List.generate(35, (_) => _spawnStar(1.4, 3.2));
    for (var i = 0; i < _asteroidsFar.length; i++) {
      _asteroidsFar[i] = _spawnAsteroid(i, far: true);
    }
    for (var i = 0; i < _asteroidsNear.length; i++) {
      _asteroidsNear[i] = _spawnAsteroid(i, far: false);
    }
  }

  final _random = Random(42);
  late List<_Star> _starsFar;
  late List<_Star> _starsMid;
  late List<_Star> _starsNear;
  late List<_NebulaBlob> _nebulaBlobs;
  late List<_Asteroid> _asteroidsFar;
  late List<_Asteroid> _asteroidsNear;
  late List<_Debris> _debris;
  late List<_WarpStreak> _warpStreaks;

  @override
  Future<void> onLoad() async {
    _starsFar = List.generate(120, (_) => _spawnStar(0.4, 1.2));
    _starsMid = List.generate(80, (_) => _spawnStar(0.8, 2.0));
    _starsNear = List.generate(35, (_) => _spawnStar(1.4, 3.2));
    _regenerateNebulae();

    _asteroidsFar = List.generate(18, (i) => _spawnAsteroid(i, far: true));
    _asteroidsNear = List.generate(12, (i) => _spawnAsteroid(i, far: false));
    _debris = List.generate(6, (i) => _spawnDebris(i));
    _warpStreaks = List.generate(24, (_) => _spawnWarpStreak());
  }

  void addScroll(double dx) => scrollX += dx * _theme.scrollMultiplier;

  void _regenerateNebulae() {
    final colors = _theme.nebulaColors;
    _nebulaBlobs = List.generate(14, (i) {
      return _NebulaBlob(
        x: _random.nextDouble() * viewportSize.x * 2.5,
        y: _random.nextDouble() * viewportSize.y,
        radius: 80 + _random.nextDouble() * 160,
        color: colors[i % colors.length],
        drift: 0.3 + _random.nextDouble() * 0.5,
      );
    });
  }

  _Star _spawnStar(double minSize, double maxSize) {
    final roll = _random.nextDouble();
    final colors = _theme.nebulaColors;
    final Color tint;
    if (roll < 0.22) {
      tint = colors[0];
    } else if (roll < 0.38) {
      tint = colors[1 % colors.length];
    } else if (roll < 0.48) {
      tint = _theme.laneColor;
    } else {
      tint = const Color(0xFFE2E8F0);
    }
    return _Star(
        x: _random.nextDouble() * viewportSize.x * 3,
        y: _random.nextDouble() * viewportSize.y,
        size: minSize + _random.nextDouble() * (maxSize - minSize),
        twinkleSpeed: 1.5 + _random.nextDouble() * 4,
        twinkleOffset: _random.nextDouble() * pi * 2,
        tint: tint,
      );
  }

  _Asteroid _spawnAsteroid(int index, {required bool far}) {
    return _Asteroid(
      x: index * (far ? 220.0 : 140.0) + _random.nextDouble() * 60,
      y: viewportSize.y * (far ? 0.25 : 0.55) + _random.nextDouble() * viewportSize.y * 0.35,
      radius: (far ? 14 : 22) + _random.nextDouble() * (far ? 20 : 28),
      seed: index * 17 + (far ? 0 : 100),
      shade: far ? _theme.asteroidFar : _theme.asteroidNear,
    );
  }

  _Debris _spawnDebris(int index) => _Debris(
        x: index * 320.0,
        y: viewportSize.y * 0.35 + _random.nextDouble() * viewportSize.y * 0.25,
        width: 120 + _random.nextDouble() * 180,
        height: 40 + _random.nextDouble() * 50,
      );

  _WarpStreak _spawnWarpStreak() => _WarpStreak(
        x: _random.nextDouble() * viewportSize.x * 2,
        y: _random.nextDouble() * viewportSize.y,
        length: 40 + _random.nextDouble() * 100,
        speed: 0.6 + _random.nextDouble() * 1.4,
      );

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = viewportSize.x;
    final h = viewportSize.y;

    _drawDeepSpace(canvas, w, h);
    _drawNebula(canvas, w, h, parallax: 0.05);
    _drawPlanet(canvas, w, h);
    _drawStars(canvas, _starsFar, w, parallax: 0.08, layer: 0);
    _drawDebris(canvas, w, parallax: 0.12);
    _drawStars(canvas, _starsMid, w, parallax: 0.18, layer: 1);
    _drawAsteroids(canvas, _asteroidsFar, w, parallax: 0.28);
    _drawNebula(canvas, w, h, parallax: 0.32, foreground: true);
    _drawWarpStreaks(canvas, w, parallax: 0.55);
    _drawAsteroids(canvas, _asteroidsNear, w, parallax: 0.68);
    _drawStars(canvas, _starsNear, w, parallax: 0.85, layer: 2);
    _drawEnergyLane(canvas, w, h, parallax: 1.0);
  }

  void _drawDeepSpace(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final colors = _theme.skyGradient;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.8, 1),
          colors: colors,
          stops: List.generate(colors.length, (i) => i / (colors.length - 1)),
        ).createShader(rect),
    );
  }

  void _drawNebula(
    Canvas canvas,
    double w,
    double h, {
    required double parallax,
    bool foreground = false,
  }) {
    final offset = scrollX * parallax;
    final alpha = foreground ? 0.12 : 0.22;

    for (final blob in _nebulaBlobs) {
      final x = (blob.x - offset * blob.drift) % (w * 2.5);
      for (var pass = 0; pass < 2; pass++) {
        final drawX = x + pass * w * 2.5 - w * 0.3;
        if (drawX < -blob.radius * 2 || drawX > w + blob.radius * 2) continue;

        VfxUtils.drawGlowCircle(
          canvas,
          Offset(drawX, blob.y + sin(elapsed * 0.2 + blob.drift) * 8),
          blob.radius,
          blob.color,
          blur: blob.radius * 0.55,
          opacity: alpha,
        );
      }
    }
  }

  void _drawPlanet(Canvas canvas, double w, double h) {
    final planetX = w * 0.78 - (scrollX * 0.04) % (w * 0.3);
    final planetY = h * 0.22;
    const planetR = 72.0;

    VfxUtils.drawGlowCircle(
      canvas,
      Offset(planetX, planetY),
      planetR * 1.4,
      _theme.planetGlow,
      blur: 40,
      opacity: 0.15,
    );

    canvas.drawCircle(
      Offset(planetX, planetY),
      planetR,
      Paint()
        ..shader = RadialGradient(
          colors: _theme.planetGradient,
          stops: List.generate(
            _theme.planetGradient.length,
            (i) => i / (_theme.planetGradient.length - 1),
          ),
        ).createShader(Rect.fromCircle(center: Offset(planetX, planetY), radius: planetR)),
    );

    canvas.save();
    canvas.translate(planetX, planetY);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: planetR * 2.8, height: planetR * 0.35),
      Paint()
        ..color = const Color(0x55C4B5FD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();

    canvas.drawCircle(
      Offset(planetX - planetR * 0.25, planetY - planetR * 0.2),
      planetR * 0.12,
      Paint()..color = const Color(0x33FFFFFF),
    );
  }

  void _drawStars(Canvas canvas, List<_Star> stars, double w, {required double parallax, required int layer}) {
    final offset = (scrollX * parallax) % (w * 3);
    for (final star in stars) {
      for (var pass = 0; pass < 2; pass++) {
        final x = star.x - offset + pass * w * 3;
        if (x < -4 || x > w + 4) continue;

        final twinkle = 0.45 + 0.55 * sin(elapsed * star.twinkleSpeed + star.twinkleOffset);
        final paint = Paint()..color = star.tint.withValues(alpha: twinkle * (layer == 2 ? 1.0 : 0.7));

        if (layer == 2) {
          VfxUtils.drawGlowCircle(canvas, Offset(x, star.y), star.size * 2.5, star.tint, blur: 6, opacity: twinkle * 0.35);
          canvas.drawCircle(Offset(x, star.y), star.size, paint);
        } else {
          canvas.drawCircle(Offset(x, star.y), star.size * 0.5, paint);
        }
      }
    }
  }

  void _drawDebris(Canvas canvas, double w, {required double parallax}) {
    final offset = (scrollX * parallax) % 400;
    for (final piece in _debris) {
      for (var pass = 0; pass < 2; pass++) {
        final x = piece.x - offset + pass * 400;
        if (x < -piece.width || x > w + piece.width) continue;

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, piece.y, piece.width, piece.height),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              colors: const [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF0F172A)],
            ).createShader(Rect.fromLTWH(x, piece.y, piece.width, piece.height)),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = _theme.laneColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        for (var i = 0; i < 4; i++) {
          canvas.drawRect(
            Rect.fromLTWH(x + 12 + i * 28, piece.y + 8, 8, 4),
            Paint()..color = _theme.laneColor.withValues(alpha: 0.5 + sin(elapsed * 3 + i) * 0.3),
          );
        }
      }
    }
  }

  void _drawAsteroids(Canvas canvas, List<_Asteroid> asteroids, double w, {required double parallax}) {
    final offset = (scrollX * parallax) % (w + 300);
    for (final rock in asteroids) {
      for (var pass = 0; pass < 2; pass++) {
        final x = rock.x - offset + pass * (w + 300);
        if (x < -rock.radius * 2 || x > w + rock.radius * 2) continue;

        final path = VfxUtils.irregularRock(x, rock.y, rock.radius, rock.seed);
        canvas.drawPath(
          path,
          Paint()
            ..shader = RadialGradient(
              colors: [
                rock.shade.withValues(alpha: 0.95),
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
              ],
            ).createShader(Rect.fromCircle(center: Offset(x, rock.y), radius: rock.radius)),
        );
        VfxUtils.strokePath(canvas, path, const Color(0xFF94A3B8), width: 0.8, opacity: 0.35);

        canvas.drawCircle(
          Offset(x - rock.radius * 0.2, rock.y - rock.radius * 0.15),
          rock.radius * 0.08,
          Paint()..color = const Color(0x22FFFFFF),
        );
      }
    }
  }

  void _drawWarpStreaks(Canvas canvas, double w, {required double parallax}) {
    final offset = (scrollX * parallax) % (w * 2);
    for (final streak in _warpStreaks) {
      for (var pass = 0; pass < 2; pass++) {
        final x = streak.x - offset * streak.speed + pass * w * 2;
        if (x < -streak.length || x > w + streak.length) continue;

        final alpha = 0.08 + 0.06 * sin(elapsed * 2 + streak.x);
        canvas.drawRect(
          Rect.fromLTWH(x, streak.y, streak.length, 1.2),
          Paint()..color = Color.fromRGBO(147, 197, 253, alpha),
        );
      }
    }
  }

  void _drawEnergyLane(Canvas canvas, double w, double h, {required double parallax}) {
    final laneY = h * 0.88;
    final offset = (scrollX * parallax) % 80;

    canvas.drawRect(
      Rect.fromLTWH(0, laneY - 6, w, h - laneY + 10),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00000000),
            const Color(0xFF0E7490).withValues(alpha: 0.15),
            const Color(0xFF164E63).withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTWH(0, laneY - 6, w, h - laneY + 10)),
    );

    for (var x = -offset; x < w + 80; x += 80) {
      final pulse = 0.5 + 0.5 * sin(elapsed * 4 + x * 0.05);
      final lane = _theme.laneColor;
      canvas.drawRect(
        Rect.fromLTWH(x, laneY, 36, 3),
        Paint()..color = lane.withValues(alpha: 0.35 + pulse * 0.4),
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 44, laneY + 10, 24, 2),
        Paint()..color = lane.withValues(alpha: 0.2 + pulse * 0.25),
      );
    }

    final lane = _theme.laneColor;
    canvas.drawLine(
      Offset(0, laneY),
      Offset(w, laneY),
      Paint()
        ..shader = LinearGradient(
          colors: [
            lane.withValues(alpha: 0),
            lane,
            lane,
            lane.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, laneY, w, 2))
        ..strokeWidth = 2,
    );
  }
}

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.tint,
  });
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double twinkleOffset;
  final Color tint;
}

class _NebulaBlob {
  _NebulaBlob({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.drift,
  });
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double drift;
}

class _Asteroid {
  _Asteroid({
    required this.x,
    required this.y,
    required this.radius,
    required this.seed,
    required this.shade,
  });
  final double x;
  final double y;
  final double radius;
  final int seed;
  final Color shade;
}

class _Debris {
  _Debris({required this.x, required this.y, required this.width, required this.height});
  final double x;
  final double y;
  final double width;
  final double height;
}

class _WarpStreak {
  _WarpStreak({required this.x, required this.y, required this.length, required this.speed});
  final double x;
  final double y;
  final double length;
  final double speed;
}
