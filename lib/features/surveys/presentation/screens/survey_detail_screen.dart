import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // No app bar, same treatment as the profile screen: the "Detalle de la
    // encuesta" title and the bar's bottom separator were removed by
    // explicit design direction. The survey's own name is the first thing
    // in the card below, so the title only repeated it a line higher, and
    // the separator cut the screen in two for no structural reason. The
    // back control survives on its own, floated over the content.
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Outside the `when` on purpose: the back control has to exist
            // in *every* state, including the error and "no disponible"
            // ones. Inside, a failed load would leave the user on a screen
            // with no way out but the system gesture.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandBackButton(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
            Expanded(
              child: surveyAsync.when(
                loading: () => const LoadingView(),
                // `surveyByIdProvider` -> `getSurvey` throws the [AppFailure]
                // itself for a definitive backend rejection (see
                // `SurveyRepositoryImpl.getSurvey`) — unwrap it so its exact
                // message (e.g. "no existe o no tienes permiso") shows
                // verbatim instead of a generic one.
                error: (error, _) => ErrorStateView(
                  failure: error is AppFailure ? error : AppFailure.unknown(null, error),
                  onRetry: () => ref.invalidate(surveyByIdProvider(surveyId)),
                ),
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
              // Top padding trimmed to `sm`: the back-button row above
              // already supplies the breathing room the old app bar used to.
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 120),
              children: [
                // Main Survey Overview Card
                StaggeredFadeSlideIn(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.assignment_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                survey.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (survey.description != null && survey.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            survey.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _InfoChip(
                              icon: Icons.quiz_outlined,
                              label: '${survey.questionCount} preguntas',
                            ),
                            _InfoChip(
                              icon: Icons.layers_outlined,
                              label: '${survey.sections.length} ${survey.sections.length == 1 ? 'sección' : 'secciones'}',
                            ),
                            if (survey.validUntil != null)
                              _InfoChip(
                                icon: Icons.event_available_rounded,
                                label: 'Vigente hasta ${DateFormat('d/MM/y').format(survey.validUntil!)}',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Sections Breakdown Preview
                if (survey.sections.isNotEmpty) ...[
                  StaggeredFadeSlideIn(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estructura de la encuesta',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final (sIndex, section) in survey.sections.indexed)
                          Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${sIndex + 1}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    section.title.isEmpty ? 'Sección ${sIndex + 1}' : section.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  '${section.questions.length} preg.',
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Responses Section
                StaggeredFadeSlideIn(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial de respuestas (${responses.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (responses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Aún no has registrado respuestas para esta encuesta.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (final response in responses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _ResponseTile(response: response, surveyId: surveyId),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: surveyAsync.valueOrNull == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(AppSpacing.md),
              child: Builder(
                builder: (context) {
                  final responses = responsesAsync.valueOrNull ?? const <SurveyResponse>[];
                  final draft = responses.where((r) => r.status == SyncStatus.draft).firstOrNull;

                  if (draft != null) {
                    return AppButton(
                      label: 'Continuar borrador',
                      icon: Icons.edit_document,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push(RoutePaths.surveyFillPath(surveyId, responseLocalId: draft.localId));
                      },
                    );
                  }

                  return AppButton(
                    label: 'Llenar encuesta',
                    icon: Icons.edit_note_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(RoutePaths.surveyFillPath(surveyId));
                    },
                  );
                },
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            ? () {
                HapticFeedback.selectionClick();
                context.push(RoutePaths.surveyFillPath(surveyId, responseLocalId: response.localId));
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDraft
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDraft
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDraft ? Icons.edit_rounded : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: isDraft ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDraft ? 'Borrador en curso' : 'Respuesta registrada',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDraft ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(surveyRepositoryProvider).retrySingle(response.localId);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
