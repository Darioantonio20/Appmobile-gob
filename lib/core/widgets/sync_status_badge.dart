import 'package:flutter/material.dart';

import '../sync/sync_status.dart';
import '../theme/app_spacing.dart';

/// Small pill showing a [SyncStatus], reused on survey cards and the Sync
/// Center list. Color + icon + text together (never color alone) so it
/// reads fine for color-blind users too.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status, this.compact = false});

  final SyncStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spinning = status == SyncStatus.syncing;
    return Semantics(
      label: 'Estado: ${status.label}',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.sm : AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: status.color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spinning)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: status.color),
              )
            else
              Icon(status.icon, size: 16, color: status.color),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: status.color),
            ),
          ],
        ),
      ),
    );
  }
}
