enum ShipType { interceptor, guardian, striker }

extension ShipTypeX on ShipType {
  String get displayName => switch (this) {
        ShipType.interceptor => 'Interceptor',
        ShipType.guardian => 'Guardian',
        ShipType.striker => 'Striker',
      };

  String get description => switch (this) {
        ShipType.interceptor => 'Swift agile fighter with rapid twin cannons.',
        ShipType.guardian => 'Heavy armor hull that absorbs extra damage.',
        ShipType.striker => 'Burst damage cruiser with piercing plasma shots.',
      };

  double get speedMultiplier => switch (this) {
        ShipType.interceptor => 1.25,
        ShipType.guardian => 0.9,
        ShipType.striker => 1.0,
      };

  double get fireRateMultiplier => switch (this) {
        ShipType.interceptor => 1.35,
        ShipType.guardian => 0.85,
        ShipType.striker => 1.0,
      };

  double get damageMultiplier => switch (this) {
        ShipType.interceptor => 0.85,
        ShipType.guardian => 1.0,
        ShipType.striker => 1.45,
      };

  int get maxHp => switch (this) {
        ShipType.interceptor => 3,
        ShipType.guardian => 5,
        ShipType.striker => 3,
      };
}
