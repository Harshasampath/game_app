import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/dice_theme.dart';
import '../models/glb_dice_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 3D GLB Dice Widget
// ─────────────────────────────────────────────────────────────────────────────
class DiceWidget extends StatefulWidget {
  final int value;
  final DiceThemeData theme;
  final double size;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double elevation;
  final bool isRolling;

  const DiceWidget({
    super.key,
    required this.value,
    required this.theme,
    this.size = 280.0,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.rotationZ = 0.0,
    this.elevation = 16.0,
    this.isRolling = false,
  });

  /// Base rotation angles that bring face `value` to the front (+Z camera view)
  static (double, double, double) baseRotationForValue(int val) {
    switch (val) {
      case 1:
        return (0.0, 0.0, 0.0);
      case 6:
        return (0.0, math.pi, 0.0);
      case 2:
        return (0.0, -math.pi / 2, 0.0);
      case 5:
        return (0.0, math.pi / 2, 0.0);
      case 3:
        return (-math.pi / 2, 0.0, 0.0);
      case 4:
        return (math.pi / 2, 0.0, 0.0);
      default:
        return (0.0, 0.0, 0.0);
    }
  }

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> {
  GlbDiceMesh? _mesh;
  ui.Image? _activeTexture;
  Color? _lastDieColor;
  Color? _lastDotColor;

  @override
  void initState() {
    super.initState();
    _loadMeshAndTexture();
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme.dieColor != widget.theme.dieColor ||
        oldWidget.theme.dotColor != widget.theme.dotColor) {
      _updateTexture();
    }
  }

  void _loadMeshAndTexture() {
    _mesh = GlbDiceLoader.cached;
    if (_mesh != null) {
      _updateTexture();
    } else {
      GlbDiceLoader.load().then((mesh) {
        if (!mounted) return;
        setState(() => _mesh = mesh);
        _updateTexture();
      });
    }
  }

  void _updateTexture() {
    final mesh = _mesh;
    if (mesh == null) return;
    final dieC = widget.theme.dieColor;
    final dotC = widget.theme.dotColor;
    if (_lastDieColor == dieC && _lastDotColor == dotC && _activeTexture != null) {
      return;
    }
    _lastDieColor = dieC;
    _lastDotColor = dotC;
    mesh.getTextureFor(dieColor: dieC, dotColor: dotC).then((tex) {
      if (!mounted) return;
      setState(() => _activeTexture = tex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mesh = _mesh;
    final texture = _activeTexture ?? mesh?.baseTextureImage;

    if (mesh == null || texture == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(widget.theme.accentColor),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _GlbDicePainter(
          mesh: mesh,
          texture: texture,
          value: widget.value.clamp(1, 6),
          theme: widget.theme,
          rotationX: widget.rotationX,
          rotationY: widget.rotationY,
          rotationZ: widget.rotationZ,
          elevation: widget.elevation,
          isRolling: widget.isRolling,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter that renders the GLB 3D dice mesh with smooth edge corners
// ─────────────────────────────────────────────────────────────────────────────
class _GlbDicePainter extends CustomPainter {
  final GlbDiceMesh mesh;
  final ui.Image texture;
  final int value;
  final DiceThemeData theme;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double elevation;
  final bool isRolling;

  _GlbDicePainter({
    required this.mesh,
    required this.texture,
    required this.value,
    required this.theme,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.elevation,
    required this.isRolling,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Dice scale factor & focal length
    final modelScale = (size.width * 0.38) / 10.0;
    final fl = size.width * 2.0;

    // Base rotation to show the current face value
    final (baseX, baseY, baseZ) = DiceWidget.baseRotationForValue(value);

    // Dynamic rotation during rolling
    final totalRotX = baseX + rotationX;
    final totalRotY = baseY + rotationY;
    final totalRotZ = baseZ + rotationZ;

    // Precalculate sin/cos
    final cxRot = math.cos(totalRotX);
    final sxRot = math.sin(totalRotX);
    final cyRot = math.cos(totalRotY);
    final syRot = math.sin(totalRotY);
    final czRot = math.cos(totalRotZ);
    final szRot = math.sin(totalRotZ);

    // 3D vector rotation: Rz * Ry * Rx
    List<double> rotateV(double x, double y, double z) {
      // Rx
      final y1 = y * cxRot - z * sxRot;
      final z1 = y * sxRot + z * cxRot;
      // Ry
      final x2 = x * cyRot + z1 * syRot;
      final z2 = -x * syRot + z1 * cyRot;
      // Rz
      final x3 = x2 * czRot - y1 * szRot;
      final y3 = x2 * szRot + y1 * czRot;
      return [x3, y3, z2];
    }

    // Directional light vector (upper-right-front)
    const lx = 0.55;
    const ly = -0.85;
    const lz = 1.30;
    final lLen = math.sqrt(lx * lx + ly * ly + lz * lz);
    final normLight = [lx / lLen, ly / lLen, lz / lLen];

    // 1. Transform all vertices
    final transformedVerts = <List<double>>[];
    final projectedVerts = <Offset>[];
    final vertexColors = <Color>[];

    for (int i = 0; i < mesh.positions.length; i++) {
      final p = mesh.positions[i];
      final n = mesh.normals[i];

      final rotP = rotateV(p[0] * modelScale, p[1] * modelScale, p[2] * modelScale);
      transformedVerts.add(rotP);

      // Perspective projection
      final scale = fl / (fl - rotP[2]);
      projectedVerts.add(Offset(cx + rotP[0] * scale, cy + rotP[1] * scale));

      // Shading: ambient (0.42) + diffuse (0.58)
      final rotN = rotateV(n[0], n[1], n[2]);
      final dot = (rotN[0] * normLight[0] + rotN[1] * normLight[1] + rotN[2] * normLight[2]).clamp(0.0, 1.0);
      final brightness = (0.42 + 0.58 * dot).clamp(0.0, 1.0);

      vertexColors.add(Color.from(
        alpha: 1.0,
        red: brightness,
        green: brightness,
        blue: brightness,
      ));
    }

    // 2. Drop shadow oval below dice
    final half = size.width * 0.40;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + half + elevation * 0.4),
        width: half * 1.9,
        height: half * 0.38,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation * 0.7),
    );

    // 3. Glow ring (if theme has glow)
    if (theme.hasGlow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: half * 2.8,
          height: half * 2.8,
        ),
        Paint()
          ..color = theme.dotColor.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
      );
    }

    // 4. Depth sort visible triangles (Painter's algorithm)
    final visibleTriangles = <(double, int, int, int)>[];
    for (int i = 0; i < mesh.indices.length; i += 3) {
      final i0 = mesh.indices[i];
      final i1 = mesh.indices[i + 1];
      final i2 = mesh.indices[i + 2];

      final p0 = transformedVerts[i0];
      final p1 = transformedVerts[i1];
      final p2 = transformedVerts[i2];

      // Cross product for outward normal
      final e1x = p1[0] - p0[0];
      final e1y = p1[1] - p0[1];

      final e2x = p2[0] - p0[0];
      final e2y = p2[1] - p0[1];

      final normZ = e1x * e2y - e1y * e2x;

      // Back-face culling: camera looks toward +Z
      if (normZ > -0.01) {
        final avgZ = (p0[2] + p1[2] + p2[2]) / 3;
        visibleTriangles.add((avgZ, i0, i1, i2));
      }
    }

    // Sort furthest Z first
    visibleTriangles.sort((a, b) => a.$1.compareTo(b.$1));

    if (visibleTriangles.isEmpty) return;

    // 5. Build sorted indices list
    final sortedIndices = <int>[];
    for (final tri in visibleTriangles) {
      sortedIndices.add(tri.$2);
      sortedIndices.add(tri.$3);
      sortedIndices.add(tri.$4);
    }

    // 6. Scale UVs to texture image pixel dimensions
    final imgW = texture.width.toDouble();
    final imgH = texture.height.toDouble();
    final pixelUvs = mesh.uvs.map((uv) => Offset(uv.dx * imgW, uv.dy * imgH)).toList();

    // 7. Render 3D mesh via Canvas.drawVertices with the recolored texture shader
    final identityMatrix = Matrix4.identity().storage;
    final imageShader = ImageShader(
      texture,
      TileMode.clamp,
      TileMode.clamp,
      identityMatrix,
    );

    final vertices = ui.Vertices(
      VertexMode.triangles,
      projectedVerts,
      textureCoordinates: pixelUvs,
      colors: vertexColors,
      indices: sortedIndices,
    );

    final meshPaint = Paint()
      ..shader = imageShader
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    // Determine if dice has stopped / resting on the stop screen
    final isStopped = !isRolling &&
        rotationX.abs() < 0.05 &&
        rotationY.abs() < 0.05 &&
        rotationZ.abs() < 0.05;

    // Projected front face dimension for smooth rounded corner mask
    final frontHalf = (size.width * 0.38) * (fl / (fl - (size.width * 0.38)));
    final diceRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: frontHalf * 1.8,
      height: frontHalf * 1.8,
    );
    final rrect = RRect.fromRectAndRadius(
      diceRect,
      Radius.circular(theme.borderRadius),
    );

    if (isStopped) {
      // Apply smooth rounded corner clip to eliminate rough polygonal chamfers
      canvas.save();
      canvas.clipRRect(rrect);
    }

    // Draw the 3D dice mesh
    canvas.drawVertices(vertices, BlendMode.modulate, meshPaint);

    if (isStopped) {
      canvas.restore();

      // 8. Smooth anti-aliased bevel border & corner light sheen on stop screen
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = theme.borderColor ?? Colors.white.withValues(alpha: 0.18);
      canvas.drawRRect(rrect, borderPaint);

      // Subtle bevel sheen on resting dice
      final sheenPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.15),
          ],
        ).createShader(diceRect);
      canvas.drawRRect(rrect, sheenPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlbDicePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.rotationZ != rotationZ ||
        oldDelegate.elevation != elevation ||
        oldDelegate.theme != theme ||
        oldDelegate.texture != texture ||
        oldDelegate.isRolling != isRolling;
  }
}
