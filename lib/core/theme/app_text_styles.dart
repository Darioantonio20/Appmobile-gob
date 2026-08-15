import 'package:flutter/material.dart';

/// Typography scale.
///
/// Sizes are intentionally larger than stock Material defaults: the primary
/// audience skews older/middle-aged, so legibility beats density. Every size
/// still scales with the system font-size setting (we never use
/// `MediaQuery.textScalerOf(context).clamp` to cap it down) so users who
/// bump OS text size get an even bigger, not identical, result.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Roboto';

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.2),
    displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.2),
    displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.25),
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
    labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
    labelMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
    labelSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
  );
}
