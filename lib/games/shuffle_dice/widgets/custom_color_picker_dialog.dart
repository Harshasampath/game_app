import 'package:flutter/material.dart';

class CustomColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;

  const CustomColorPickerDialog({
    super.key,
    required this.initialColor,
    this.title = 'Select Custom Color',
  });

  static Future<Color?> show({
    required BuildContext context,
    required Color initialColor,
    String title = 'Select Custom Color',
  }) {
    return showDialog<Color>(
      context: context,
      builder: (ctx) => CustomColorPickerDialog(
        initialColor: initialColor,
        title: title,
      ),
    );
  }

  @override
  State<CustomColorPickerDialog> createState() => _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<CustomColorPickerDialog> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;

  final List<Color> _quickSwatches = const [
    Color(0xFFF43F5E), // Rose
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFFEAB308), // Yellow
    Color(0xFF84CC16), // Lime
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFF0EA5E9), // Sky
    Color(0xFF3B82F6), // Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFA855F7), // Purple
    Color(0xFFD946EF), // Fuchsia
    Color(0xFFEC4899), // Pink
    Color(0xFFFFFFFF), // White
    Color(0xFF94A3B8), // Slate
    Color(0xFF1E293B), // Dark Slate
    Color(0xFF0F172A), // Midnight
    Color(0xFF000000), // Black
  ];

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _colorToHex(_hsvColor.toColor()));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _onHexSubmitted(String hex) {
    String cleanHex = hex.trim().replaceAll('#', '');
    if (cleanHex.length == 6) {
      final intValue = int.tryParse(cleanHex, radix: 16);
      if (intValue != null) {
        final newColor = Color(0xFF000000 | intValue);
        setState(() {
          _hsvColor = HSVColor.fromColor(newColor);
        });
      }
    }
  }

  void _setColor(Color color) {
    setState(() {
      _hsvColor = HSVColor.fromColor(color);
      _hexController.text = _colorToHex(color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();

    return Dialog(
      backgroundColor: const Color(0xFF181F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview card + Hex input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    // Color Preview swatch
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: currentColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white30, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Hex text field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HEX COLOR',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _hexController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                            ),
                            onSubmitted: _onHexSubmitted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Hue Slider (Rainbow)
              _buildSliderLabel('HUE', '${_hsvColor.hue.round()}°'),
              SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 12,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                  trackShape: _GradientSliderTrackShape(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                child: Slider(
                  value: _hsvColor.hue,
                  min: 0,
                  max: 360,
                  onChanged: (val) {
                    setState(() {
                      _hsvColor = _hsvColor.withHue(val);
                      _hexController.text = _colorToHex(_hsvColor.toColor());
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Saturation Slider
              _buildSliderLabel('SATURATION', '${(_hsvColor.saturation * 100).round()}%'),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 10,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                  trackShape: _GradientSliderTrackShape(
                    gradient: LinearGradient(
                      colors: [
                        HSVColor.fromAHSV(1.0, _hsvColor.hue, 0.0, _hsvColor.value).toColor(),
                        HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, _hsvColor.value).toColor(),
                      ],
                    ),
                  ),
                ),
                child: Slider(
                  value: _hsvColor.saturation,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (val) {
                    setState(() {
                      _hsvColor = _hsvColor.withSaturation(val);
                      _hexController.text = _colorToHex(_hsvColor.toColor());
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Brightness / Value Slider
              _buildSliderLabel('BRIGHTNESS', '${(_hsvColor.value * 100).round()}%'),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 10,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                  trackShape: _GradientSliderTrackShape(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        HSVColor.fromAHSV(1.0, _hsvColor.hue, _hsvColor.saturation, 1.0).toColor(),
                      ],
                    ),
                  ),
                ),
                child: Slider(
                  value: _hsvColor.value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (val) {
                    setState(() {
                      _hsvColor = _hsvColor.withValue(val);
                      _hexController.text = _colorToHex(_hsvColor.toColor());
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Quick Swatches Grid
              const Text(
                'QUICK PALETTE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSwatches.map((color) {
                  final isSelected = currentColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => _setColor(color),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white24,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, currentColor),
                      child: const Text('APPLY COLOR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _GradientSliderTrackShape extends SliderTrackShape {
  final Gradient gradient;

  const _GradientSliderTrackShape({required this.gradient});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 10;
    final double trackLeft = offset.dx + 12;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - 24;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..style = PaintingStyle.fill;

    final RRect roundedRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(trackRect.height / 2),
    );

    context.canvas.drawRRect(roundedRect, paint);
  }
}
