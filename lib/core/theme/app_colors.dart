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

  // Semantic colors that don't come from the Material seed palette. Each has
  // a brighter "Dark" variant: the base tone is picked for contrast against a
  // *light* background and reads as low-contrast/muddy text on a dark one —
  // see SyncStatus.colorFor, the one place that needs to pick between them.
  static const Color success = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF81C784);
  static const Color warning = Color(0xFFB26A00);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerDark = Color(0xFFEF5350);
  static const Color info = Color(0xFF01579B);
  static const Color infoDark = Color(0xFF64B5F6);

  // Sync-status specific colors (used by SyncStatusBadge across the app).
  static const Color syncPending = warning;
  static const Color syncPendingDark = warningDark;
  static const Color syncSynced = success;
  static const Color syncSyncedDark = successDark;
  static const Color syncFailed = danger;
  static const Color syncFailedDark = dangerDark;
  static const Color syncInProgress = info;
  static const Color syncInProgressDark = infoDark;
}
