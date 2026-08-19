import 'package:flutter/material.dart';

/// Typography scale.
///
/// Sizes are a bit larger than stock Material defaults (older/middle-aged
/// audience, legibility over density) but dialed back from an earlier pass
/// that read as too large specifically on phones — explicit feedback. Every
/// size still scales with the system font-size setting (we never use
/// `MediaQuery.textScalerOf(context).clamp` to cap it down) so users who
/// bump OS text size get an even bigger, not identical, result.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Roboto';

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.2),
    displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
    displaySmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25),
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
    headlineMedium: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.3),
    headlineSmall: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.3),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
  );
}
