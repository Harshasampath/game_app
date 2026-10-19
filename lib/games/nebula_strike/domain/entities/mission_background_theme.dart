import 'dart:ui';

/// Visual palette for combat parallax — one theme per mission sector.
class MissionBackgroundTheme {
  const MissionBackgroundTheme({
    required this.id,
    required this.skyGradient,
    required this.nebulaColors,
    required this.planetGradient,
    required this.planetGlow,
    required this.laneColor,
    required this.asteroidFar,
    required this.asteroidNear,
    required this.canvasBackground,
    this.scrollMultiplier = 1.0,
  });

  final String id;
  final List<Color> skyGradient;
  final List<Color> nebulaColors;
  final List<Color> planetGradient;
  final Color planetGlow;
  final Color laneColor;
  final Color asteroidFar;
  final Color asteroidNear;
  final Color canvasBackground;
  final double scrollMultiplier;
}

/// Preset backdrops keyed by mission id — each mission has a distinct identity.
class MissionBackgroundThemes {
  MissionBackgroundThemes._();

  /// M1 — calm teal dawn training sector (cool, green-blue, soft).
  static const training = MissionBackgroundTheme(
    id: 'training',
    skyGradient: [
      Color(0xFF071218),
      Color(0xFF0C2A2F),
      Color(0xFF134E4A),
      Color(0xFF0A1F1C),
    ],
    nebulaColors: [
      Color(0xFF0D9488),
      Color(0xFF2DD4BF),
      Color(0xFF5EEAD4),
      Color(0xFF14B8A6),
    ],
    planetGradient: [
      Color(0xFFCCFBF1),
      Color(0xFF5EEAD4),
      Color(0xFF0F766E),
      Color(0xFF042F2E),
    ],
    planetGlow: Color(0xFF2DD4BF),
    laneColor: Color(0xFF5EEAD4),
    asteroidFar: Color(0xFF4B6B6B),
    asteroidNear: Color(0xFF6B8F8F),
    canvasBackground: Color(0xFF071218),
    scrollMultiplier: 1.0,
  );

  static const outerRim = MissionBackgroundTheme(
    id: 'outer_rim',
    skyGradient: [Color(0xFF0A0612), Color(0xFF1A1028), Color(0xFF2D1B3D), Color(0xFF120A1A)],
    nebulaColors: [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFF97316), Color(0xFF4C1D95)],
    planetGradient: [Color(0xFFFDBA74), Color(0xFFEA580C), Color(0xFF7C2D12), Color(0xFF1C0A00)],
    planetGlow: Color(0xFFF97316),
    laneColor: Color(0xFFC084FC),
    asteroidFar: Color(0xFF57534E),
    asteroidNear: Color(0xFF78716C),
    canvasBackground: Color(0xFF0A0612),
    scrollMultiplier: 1.08,
  );

  static const asteroidBelt = MissionBackgroundTheme(
    id: 'asteroid_belt',
    skyGradient: [Color(0xFF0C0A08), Color(0xFF1C1410), Color(0xFF2A1F18), Color(0xFF100C08)],
    nebulaColors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFDC2626), Color(0xFF78350F)],
    planetGradient: [Color(0xFFD6D3D1), Color(0xFF78716C), Color(0xFF44403C), Color(0xFF1C1917)],
    planetGlow: Color(0xFFEF4444),
    laneColor: Color(0xFFF87171),
    asteroidFar: Color(0xFF6B5B4F),
    asteroidNear: Color(0xFF8B7355),
    canvasBackground: Color(0xFF0C0A08),
    scrollMultiplier: 1.12,
  );

  static const deepVoid = MissionBackgroundTheme(
    id: 'deep_void',
    skyGradient: [Color(0xFF000008), Color(0xFF0A0520), Color(0xFF150A35), Color(0xFF050210)],
    nebulaColors: [Color(0xFF4C1D95), Color(0xFF312E81), Color(0xFF6D28D9), Color(0xFF1E1B4B)],
    planetGradient: [Color(0xFFA78BFA), Color(0xFF5B21B6), Color(0xFF2E1065), Color(0xFF0F0520)],
    planetGlow: Color(0xFF8B5CF6),
    laneColor: Color(0xFFA855F7),
    asteroidFar: Color(0xFF3F3F46),
    asteroidNear: Color(0xFF52525B),
    canvasBackground: Color(0xFF000008),
    scrollMultiplier: 1.18,
  );

  /// M5 — volcanic nebula core (hot crimson, gold, inferno).
  static const nebulaCore = MissionBackgroundTheme(
    id: 'nebula_core',
    skyGradient: [
      Color(0xFF1A0005),
      Color(0xFF450A0A),
      Color(0xFF7F1D1D),
      Color(0xFF1C0505),
    ],
    nebulaColors: [
      Color(0xFFDC2626),
      Color(0xFFF97316),
      Color(0xFFFBBF24),
      Color(0xFFBE123C),
    ],
    planetGradient: [
      Color(0xFFFEF08A),
      Color(0xFFF97316),
      Color(0xFFB91C1C),
      Color(0xFF450A0A),
    ],
    planetGlow: Color(0xFFFB923C),
    laneColor: Color(0xFFFBBF24),
    asteroidFar: Color(0xFF7C2D12),
    asteroidNear: Color(0xFF9A3412),
    canvasBackground: Color(0xFF1A0005),
    scrollMultiplier: 1.25,
  );

  static const endless = MissionBackgroundTheme(
    id: 'endless',
    skyGradient: [Color(0xFF001208), Color(0xFF052E16), Color(0xFF0B3D2E), Color(0xFF001A0E)],
    nebulaColors: [Color(0xFF22C55E), Color(0xFFA3E635), Color(0xFF06B6D4), Color(0xFF15803D)],
    planetGradient: [Color(0xFFBBF7D0), Color(0xFF22C55E), Color(0xFF14532D), Color(0xFF052E16)],
    planetGlow: Color(0xFF4ADE80),
    laneColor: Color(0xFFA3E635),
    asteroidFar: Color(0xFF365314),
    asteroidNear: Color(0xFF4D7C0F),
    canvasBackground: Color(0xFF001208),
    scrollMultiplier: 1.15,
  );

  static MissionBackgroundTheme forMissionId(String missionId) => switch (missionId) {
        'm1' => training,
        'm2' => outerRim,
        'm3' => asteroidBelt,
        'm4' => deepVoid,
        'm5' => nebulaCore,
        'endless' => endless,
        _ => training,
      };
}
