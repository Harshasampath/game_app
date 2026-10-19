import 'dart:ui';

import 'package:flame/components.dart';

import '../rendering/vfx_utils.dart';

/// Full-screen vignette and subtle scanlines for a cinematic sci-fi look.
class ScreenPostFxComponent extends Component {
  ScreenPostFxComponent({required this.viewportSize});

  final Vector2 viewportSize;

  @override
  void render(Canvas canvas) {
    VfxUtils.drawVignette(canvas, viewportSize.toSize(), strength: 0.5);
    VfxUtils.drawScanlines(canvas, viewportSize.toSize(), opacity: 0.035);
  }
}
