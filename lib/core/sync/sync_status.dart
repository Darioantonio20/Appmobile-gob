import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lifecycle of one locally-saved survey response.
///
/// `draft` → still being filled in, not submitted yet (only ever local).
/// `pending` → submitted by the user, waiting to reach the server.
/// `syncing` → the sync engine is actively sending it right now.
/// `synced` → the server accepted it; safe to treat as done.
/// `failed` → the server rejected it (e.g. validation) after retries;
///            needs a human to look at it in the Sync Center.
enum SyncStatus {
  draft,
  pending,
  syncing,
  synced,
  failed;

  static SyncStatus fromName(String name) =>
      SyncStatus.values.firstWhere((e) => e.name == name, orElse: () => SyncStatus.pending);

  bool get needsUpload => this == pending || this == failed;

  String get label => switch (this) {
        SyncStatus.draft => 'Borrador',
        SyncStatus.pending => 'Pendiente de enviar',
        SyncStatus.syncing => 'Enviando…',
        SyncStatus.synced => 'Enviado',
        SyncStatus.failed => 'No se pudo enviar',
      };

  /// Brightness-aware: the light-mode tones read as low-contrast/muddy text
  /// on a dark background, so dark mode gets brighter variants of the same
  /// hues instead (see [AppColors]).
  Color colorFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (this) {
      SyncStatus.draft => isDark ? AppColors.infoDark : AppColors.info,
      SyncStatus.pending => isDark ? AppColors.syncPendingDark : AppColors.syncPending,
      SyncStatus.syncing => isDark ? AppColors.syncInProgressDark : AppColors.syncInProgress,
      SyncStatus.synced => isDark ? AppColors.syncSyncedDark : AppColors.syncSynced,
      SyncStatus.failed => isDark ? AppColors.syncFailedDark : AppColors.syncFailed,
    };
  }

  IconData get icon => switch (this) {
        SyncStatus.draft => Icons.edit_note_rounded,
        SyncStatus.pending => Icons.cloud_upload_outlined,
        SyncStatus.syncing => Icons.sync_rounded,
        SyncStatus.synced => Icons.cloud_done_rounded,
        SyncStatus.failed => Icons.error_outline_rounded,
      };
}
