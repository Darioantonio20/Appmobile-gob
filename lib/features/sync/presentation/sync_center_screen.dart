import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/staggered_fade_in.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../../surveys/data/survey_repository_impl.dart';
import '../../surveys/domain/survey_response.dart';
import '../../surveys/presentation/survey_providers.dart';

/// Shows what's still owed to the server and what's already been sent —
/// the one place a surveyor can check "did my work actually go through?"
/// without needing connectivity to get a straight answer.
class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allResponsesProvider);
    final engineState = ref.watch(syncEngineProvider);

    return Scaffold(
      appBar: const BrandAppBar(title: Text('Sincronización')),
      body: allAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(failure: AppFailure.unknown(null, error)),
        data: (all) {
          final pending = all
              .where((r) => r.status != SyncStatus.synced && r.status != SyncStatus.draft)
              .toList();
          final synced = all.where((r) => r.status == SyncStatus.synced).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(syncEngineProvider.notifier).triggerNow(),
            child: ResponsiveCenter(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  StaggeredFadeSlideIn(
                    index: 0,
                    child: _StatusHeader(engineState: engineState, pendingCount: pending.length),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (pending.isEmpty)
                    StaggeredFadeSlideIn(index: 1, child: const _AllSyncedCard())
                  else ...[
                    Text('Pendientes (${pending.length})', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    for (final (index, response) in pending.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: StaggeredFadeSlideIn(index: index + 1, child: _ResponseRow(response: response)),
                      ),
                  ],
                  if (synced.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text('Enviadas (${synced.length})', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    for (final (index, response) in synced.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: StaggeredFadeSlideIn(
                          index: index + pending.length + 1,
                          child: _ResponseRow(response: response),
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusHeader extends ConsumerWidget {
  const _StatusHeader({required this.engineState, required this.pendingCount});

  final SyncEngineState engineState;
  final int pendingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastSync = engineState.lastSuccessAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  engineState.isSyncing
                      ? 'Sincronizando…'
                      : pendingCount == 0
                          ? 'Todo al día'
                          : '$pendingCount por enviar',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  lastSync == null
                      ? 'Aún no se ha sincronizado en esta sesión.'
                      : 'Última sincronización: ${DateFormat("d/MM/y HH:mm").format(lastSync)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 140,
            child: AppButton(
              label: 'Sincronizar',
              icon: Icons.sync_rounded,
              isLoading: engineState.isSyncing,
              onPressed: () => ref.read(syncEngineProvider.notifier).triggerNow(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllSyncedCard extends StatelessWidget {
  const _AllSyncedCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_done_rounded, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text('No tienes encuestas pendientes por enviar', style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ResponseRow extends ConsumerWidget {
  const _ResponseRow({required this.response});

  final SurveyResponse response;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateLabel = response.submittedAt ?? response.updatedAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: response.status == SyncStatus.failed
            ? Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(response.surveyTitle, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  DateFormat("d 'de' MMMM, HH:mm", 'es_MX').format(dateLabel),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (response.status == SyncStatus.failed && response.lastError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    response.lastError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SyncStatusBadge(status: response.status, compact: true),
          if (response.status == SyncStatus.failed)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reintentar envío',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(surveyRepositoryProvider).retrySingle(response.localId);
              },
            ),
        ],
      ),
    );
  }
}
