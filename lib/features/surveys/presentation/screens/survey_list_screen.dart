import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/brand_app_bar.dart';
import '../../../../core/widgets/staggered_fade_in.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/survey_repository_impl.dart';
import '../../domain/survey_response.dart';
import '../survey_providers.dart';
import '../widgets/survey_card.dart';

enum _SurveyFilter { all, pending, drafts, completed }

class SurveyListScreen extends ConsumerStatefulWidget {
  const SurveyListScreen({super.key});

  @override
  ConsumerState<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends ConsumerState<SurveyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _SurveyFilter _selectedFilter = _SurveyFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final result = await ref.read(surveyRepositoryProvider).refreshSurveys();
    if (!mounted) return;
    result.when(
      success: (_) {},
      failure: (failure) {
        if (failure.type != FailureType.network) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final surveysAsync = ref.watch(surveysStreamProvider);
    final responsesAsync = ref.watch(allResponsesProvider);

    return Scaffold(
      appBar: BrandAppBar(
        title: Text(user == null ? 'Encuestas' : 'Hola, ${user.name.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Mi perfil',
            onPressed: () => context.push(RoutePaths.profile),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: surveysAsync.when(
          loading: () => const LoadingView(message: 'Cargando encuestas…'),
          error: (error, _) => ErrorStateView(
            failure: mapNetworkError(error),
            onRetry: _refresh,
          ),
          data: (surveys) {
            if (surveys.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 120),
                    EmptyStateView(
                      title: 'Sin encuestas disponibles',
                      message:
                          'Cuando tengas encuestas asignadas aparecerán aquí. Desliza hacia abajo para buscar nuevas.',
                      icon: Icons.assignment_outlined,
                    ),
                  ],
                ),
              );
            }

            final responsesBySurvey = <String, SurveyResponse>{};
            for (final response in responsesAsync.valueOrNull ?? const <SurveyResponse>[]) {
              responsesBySurvey.putIfAbsent(response.surveyId, () => response);
            }

            // Stats calculation
            final totalAssigned = surveys.length;
            int draftsCount = 0;
            int completedCount = 0;

            for (final survey in surveys) {
              final resp = responsesBySurvey[survey.id];
              if (resp?.status == SyncStatus.draft) {
                draftsCount++;
              } else if (resp?.status == SyncStatus.synced) {
                completedCount++;
              }
            }

            // Filter & search logic
            final filteredSurveys = surveys.where((survey) {
              final matchesSearch = _searchQuery.isEmpty ||
                  survey.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (survey.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

              if (!matchesSearch) return false;

              final resp = responsesBySurvey[survey.id];
              return switch (_selectedFilter) {
                _SurveyFilter.all => true,
                _SurveyFilter.pending => resp == null,
                _SurveyFilter.drafts => resp?.status == SyncStatus.draft,
                _SurveyFilter.completed => resp?.status == SyncStatus.synced,
              };
            }).toList();

            final theme = Theme.of(context);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ResponsiveCenter(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.sm),

                      // Metrics Banner
                      StaggeredFadeSlideIn(
                        index: 0,
                        child: _SurveyMetricsRow(
                          total: totalAssigned,
                          drafts: draftsCount,
                          completed: completedCount,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Search Box
                      StaggeredFadeSlideIn(
                        index: 1,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar encuestas…',
                            prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.secondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Filter Chips
                      StaggeredFadeSlideIn(
                        index: 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'Todas ($totalAssigned)',
                                selected: _selectedFilter == _SurveyFilter.all,
                                onSelected: () => setState(() => _selectedFilter = _SurveyFilter.all),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _FilterChip(
                                label: 'Pendientes (${totalAssigned - draftsCount - completedCount})',
                                selected: _selectedFilter == _SurveyFilter.pending,
                                onSelected: () => setState(() => _selectedFilter = _SurveyFilter.pending),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _FilterChip(
                                label: 'Borradores ($draftsCount)',
                                selected: _selectedFilter == _SurveyFilter.drafts,
                                onSelected: () => setState(() => _selectedFilter = _SurveyFilter.drafts),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _FilterChip(
                                label: 'Completadas ($completedCount)',
                                selected: _selectedFilter == _SurveyFilter.completed,
                                onSelected: () => setState(() => _selectedFilter = _SurveyFilter.completed),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // List or Empty result
                      if (filteredSurveys.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: EmptyStateView(
                            title: 'Sin coincidencias',
                            message: 'No encontramos encuestas con los filtros actuales.',
                            icon: Icons.filter_alt_off_rounded,
                            actionLabel: 'Restablecer filtros',
                            onAction: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedFilter = _SurveyFilter.all;
                              });
                            },
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = Responsive.gridColumns(context);
                            const spacing = AppSpacing.md;
                            final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                for (final (index, survey) in filteredSurveys.indexed)
                                  SizedBox(
                                    width: cardWidth,
                                    child: StaggeredFadeSlideIn(
                                      index: index + 3,
                                      child: SurveyCard(
                                        survey: survey,
                                        latestResponse: responsesBySurvey[survey.id],
                                        onTap: () => context.push(RoutePaths.surveyDetailPath(survey.id)),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SurveyMetricsRow extends StatelessWidget {
  const _SurveyMetricsRow({
    required this.total,
    required this.drafts,
    required this.completed,
  });

  final int total;
  final int drafts;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(
              label: 'Asignadas',
              value: '$total',
              icon: Icons.assignment_outlined,
              color: theme.colorScheme.secondary,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          Expanded(
            child: _MetricItem(
              label: 'Borradores',
              value: '$drafts',
              icon: Icons.edit_note_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          Expanded(
            child: _MetricItem(
              label: 'Enviadas',
              value: '$completed',
              icon: Icons.check_circle_outline_rounded,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;
    final bgColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerLow;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1.0),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
