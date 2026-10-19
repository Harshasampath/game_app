import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

import '../widgets/app_safe_area.dart';

/// Full-screen cover shown while the device rotates between menu and combat.
class CombatTransitionOverlay extends StatelessWidget {
  const CombatTransitionOverlay({super.key, this.message = 'LAUNCHING...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xF00B1026),
      child: AppSafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTypography.orbitron(
                  color: const Color(0xFF74C0FC),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
