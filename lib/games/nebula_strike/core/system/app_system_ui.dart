import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Edge-to-edge system bars with transparent navigation/status areas.
///
/// [SafeArea] / [AppSafeArea] then only inset content when the device reports
/// real system UI (nav bar, gesture handle, notch) — not on every phone.
abstract final class AppSystemUi {
  static Future<void> configurePortrait() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}
