import 'package:flutter/material.dart';

/// Design tokens for color.
///
/// The palette is a placeholder civic green/amber scheme — swap [seed] and
/// the semantic colors below for the official Chiapas government brand kit
/// once you have it; every screen reads colors from [AppTheme]/[AppColors],
/// never hardcodes them, so this is a one-file change.
class AppColors {
  AppColors._();

  /// Seed used to derive the whole Material 3 tonal palette.
  static const Color seed = Color(0xFF0B6E4F); // institutional green

  // Semantic colors that don't come from the Material seed palette.
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF01579B);

  // Sync-status specific colors (used by SyncStatusBadge across the app).
  static const Color syncPending = Color(0xFFB26A00);
  static const Color syncSynced = Color(0xFF2E7D32);
  static const Color syncFailed = Color(0xFFC62828);
  static const Color syncInProgress = Color(0xFF01579B);
}
