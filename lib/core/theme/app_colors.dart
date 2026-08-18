import 'package:flutter/material.dart';

/// Design tokens for color — the official Gobierno brand kit (Pantone P
/// 131-6 C / P 69-70 C / P 53-16 C, plus black and Pantone P 23-2 C as
/// complementary neutrals). Every screen reads colors from
/// [AppTheme]/[AppColors], never hardcodes them, so a future palette swap
/// stays a one-file change.
class AppColors {
  AppColors._();

  // ── Official brand colors ────────────────────────────────────────────
  // Primary: Pantone P 131-6 C (institutional teal/green).
  static const Color brandPrimary = Color(0xFF009885);

  // Secondary: Pantone P 69-70 C (magenta).
  static const Color brandSecondary = Color(0xFFC91266);

  // Tertiary: Pantone P 53-16 C (red).
  static const Color brandTertiary = Color(0xFFAE192D);

  // Complementary neutrals: Process Black and Pantone P 23-2 C (warm tan).
  // Not woven into every surface (Material's own neutral-gray surface scale
  // is what's actually contrast-tested throughout this app); kept as named
  // constants for a deliberate accent use if one comes up.
  static const Color brandBlack = Color(0xFF000000);
  static const Color brandTan = Color(0xFFD3C2B4);

  /// Seed used to derive the whole Material 3 tonal palette (see
  /// [AppTheme] for how secondary/tertiary get seeded from the other two
  /// brand colors instead of auto-derived from this one).
  static const Color seed = brandPrimary;

  // Semantic colors that don't come from the Material seed palette. Each has
  // a brighter "Dark" variant: the base tone is picked for contrast against a
  // *light* background and reads as low-contrast/muddy text on a dark one —
  // see SyncStatus.colorFor, the one place that needs to pick between them.
  static const Color success = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF81C784);
  static const Color warning = Color(0xFFB26A00);
  static const Color warningDark = Color(0xFFFFB74D);
  // Error/danger aligned to the brand red (Pantone P 53-16 C) rather than a
  // generic Material red — "red for error" is both the convention and the
  // brand color here, a rare case where they overlap cleanly.
  static const Color danger = brandTertiary;
  static const Color dangerDark = Color(0xFFE57373);
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
