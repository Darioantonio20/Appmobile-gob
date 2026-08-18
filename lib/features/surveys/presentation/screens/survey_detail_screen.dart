import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand_app_bar.dart';
import '../../../../core/widgets/staggered_fade_in.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/sync_status_badge.dart';
import '../../data/survey_repository_impl.dart';
import '../../domain/survey_response.dart';
import '../survey_providers.dart';

class SurveyDetailScreen extends ConsumerWidget {
  const SurveyDetailScreen({super.key, required this.surveyId});

  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveyAsync = ref.watch(surveyByIdProvider(surveyId));
    final responsesAsync = ref.watch(responsesForSurveyProvider(surveyId));

    return Scaffold(
      appBar: const BrandAppBar(title: Text('Detalle de la encuesta')),
      body: surveyAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorStateView(failure: AppFailure.unknown(null, error)),
        data: (survey) {
          if (survey == null) {
            return const EmptyStateView(
              title: 'Encuesta no disponible',
              message: 'Puede que ya no esté asignada o que falte actualizar la lista.',
              icon: Icons.search_off_rounded,
            );
          }

          final responses = responsesAsync.valueOrNull ?? const <SurveyResponse>[];
          final theme = Theme.of(context);

          return ResponsiveCenter(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                StaggeredFadeSlideIn(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(survey.title, style: theme.textTheme.headlineSmall),
                      if (survey.description != null && survey.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(survey.description!, style: theme.textTheme.bodyLarge),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoChip(icon: Icons.list_alt_rounded, label: '${survey.questionCount} preguntas'),
                          _InfoChip(
                            icon: Icons.update_rounded,
                            label: 'Actualizada ${DateFormat('d/MM/y').format(survey.updatedAt)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (responses.isNotEmpty) ...[
                  Text('Mis respuestas', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  for (final (index, response) in responses.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: StaggeredFadeSlideIn(
                        index: index + 1,
                        child: _ResponseTile(response: response, surveyId: surveyId),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: surveyAsync.valueOrNull == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: 'Llenar nueva encuesta',
                icon: Icons.edit_note_rounded,
                onPressed: () => context.push(RoutePaths.surveyFillPath(surveyId)),
              ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ResponseTile extends ConsumerWidget {
  const _ResponseTile({required this.response, required this.surveyId});

  final SurveyResponse response;
  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDraft = response.status == SyncStatus.draft;
    final isFailed = response.status == SyncStatus.failed;
    final dateLabel = response.submittedAt ?? response.updatedAt;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: isDraft
            ? () => context.push(RoutePaths.surveyFillPath(surveyId, responseLocalId: response.localId))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDraft ? 'Borrador sin terminar' : 'Respuesta',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat("d 'de' MMMM, HH:mm", 'es_MX').format(dateLabel),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SyncStatusBadge(status: response.status, compact: true),
              if (isDraft) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
              ],
              if (isFailed) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reintentar envío',
                  onPressed: () => ref.read(surveyRepositoryProvider).retrySingle(response.localId),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
