import 'package:flutter/material.dart';

/// Keeps interactive UI above system bars when they exist, with no extra gap when
/// the device reports zero bottom inset (e.g. some gesture-only layouts).
class AppSafeArea extends StatelessWidget {
  const AppSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: EdgeInsets.zero,
      child: child,
    );
  }
}
