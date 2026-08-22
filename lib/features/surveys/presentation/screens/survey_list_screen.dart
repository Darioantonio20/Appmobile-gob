import 'dart:async';

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
import '../../../../core/widgets/staggered_fade_in.dart';
import '../../../../core/widgets/state_views.dart';
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

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar encuestas…',
        // Green prefix icon and a fully-rounded (pill) green border,
        // overriding the app-wide input theme's magenta icon / `radiusMd`
        // corners — the reference mockup styles *this* field specifically,
        // and search reads better as a pill than as another rectangular
        // form input among the survey form fields elsewhere.
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.clear_rounded, color: theme.colorScheme.primary),
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        // Neutral placeholder, overriding the app-wide input theme's
        // magenta `hintStyle` — that magenta is right for a survey form
        // field the user must fill in, but here it made an optional search
        // box shout louder than the content it filters.
        hintStyle: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.45), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.8),
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surveysAsync = ref.watch(surveysStreamProvider);
    final responsesAsync = ref.watch(allResponsesProvider);

    // No app bar at all: the "Hola, {nombre}" greeting and the bar's bottom
    // separator were removed by explicit design direction (the greeting
    // said nothing actionable and cost a full toolbar of height on the
    // app's busiest screen), and the profile button that shared it has
    // since moved into the bottom nav bar with the other destinations. The
    // content now starts at the top of the safe area.
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
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
                      // No profile button here any more — it moved into the
                      // bottom nav bar alongside "Encuestas" and
                      // "Sincronización", where every other navigation
                      // control already lives. That frees this whole row,
                      // so the metrics start at the very top of the safe
                      // area.
                      const SizedBox(height: AppSpacing.sm),

                      // The stat cards *are* the filter. They used to be
                      // read-only counts with a separate filter control
                      // beside the search field (which opened a sheet
                      // listing the same four options with the same four
                      // counts) — the same information stated twice, in two
                      // places, one of them hidden behind a tap. Making the
                      // cards tappable collapses both into one control:
                      // every option and its count is visible at all times,
                      // and the active one is the one that's lit.
                      StaggeredFadeSlideIn(
                        index: 0,
                        child: _SurveyFilterCards(
                          selected: _selectedFilter,
                          counts: {
                            _SurveyFilter.all: totalAssigned,
                            _SurveyFilter.pending: totalAssigned - draftsCount - completedCount,
                            _SurveyFilter.drafts: draftsCount,
                            _SurveyFilter.completed: completedCount,
                          },
                          onSelected: (filter) => setState(() => _selectedFilter = filter),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Search now spans the full width — the filter button
                      // that used to sit beside it is gone (see above).
                      StaggeredFadeSlideIn(index: 1, child: _buildSearchField(theme)),

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
      ),
    );
  }
}


extension on _SurveyFilter {
  String get label => switch (this) {
        _SurveyFilter.all => 'Todas',
        _SurveyFilter.pending => 'Pendientes',
        _SurveyFilter.drafts => 'Borradores',
        _SurveyFilter.completed => 'Enviadas',
      };

  /// `all` gets a grid glyph — "everything at once" rather than any one
  /// state. The other three reuse the exact icon their status already
  /// carries on the survey cards and in the sync center, so a filter and
  /// the rows it produces are visibly the same thing.
  IconData get icon => switch (this) {
        _SurveyFilter.all => Icons.grid_view_rounded,
        _SurveyFilter.pending => Icons.assignment_outlined,
        _SurveyFilter.drafts => Icons.edit_note_rounded,
        _SurveyFilter.completed => Icons.cloud_done_rounded,
      };

  /// Two of these map onto a real [SyncStatus], so they take that status's
  /// own color — the same one the matching badge uses elsewhere. `pending`
  /// (assigned but not started) isn't literally `SyncStatus.pending`, but
  /// "work still owed" is what amber means throughout this app, so it
  /// borrows the same tone. `all` takes the brand accent since it isn't a
  /// status at all.
  Color colorFor(ThemeData theme) => switch (this) {
        _SurveyFilter.all => theme.colorScheme.secondary,
        _SurveyFilter.pending => SyncStatus.pending.colorFor(theme.brightness),
        _SurveyFilter.drafts => SyncStatus.draft.colorFor(theme.brightness),
        _SurveyFilter.completed => SyncStatus.synced.colorFor(theme.brightness),
      };
}

/// The four stat cards, which double as the status filter — see the call
/// site for why the separate filter control was folded into these.
class _SurveyFilterCards extends StatelessWidget {
  const _SurveyFilterCards({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final _SurveyFilter selected;
  final Map<_SurveyFilter, int> counts;
  final ValueChanged<_SurveyFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, filter) in _SurveyFilter.values.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _FilterCard(
                index: index,
                filter: filter,
                value: counts[filter] ?? 0,
                selected: filter == selected,
                onTap: () => onSelected(filter),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A "liquid glass" stat tile that is also the filter toggle for its own
/// status: a translucent pane tinted by that status's color, a glowing icon
/// disc, the count, and the label.
///
/// The glass is built from *flat* translucent layers, not a gradient — this
/// app's design language has no gradients anywhere (see the project's
/// flutter-ui-review skill, where a gradient app bar was explicitly
/// rejected as muddy), and a real `BackdropFilter` blur would be wasted
/// here anyway: these sit on a flat scaffold background, so there is
/// nothing behind them worth blurring, only GPU cost. Stacking a tinted
/// fill under a colored border gets the same depth read for free.
///
/// Entrance is staggered per [index] — the four tiles rise and scale in one
/// after another rather than together, and their numbers count up from
/// zero, so the row resolves as a small sequence instead of a static block
/// appearing at once.
///
/// Labels are wrapped in a scale-down `FittedBox` rather than ellipsised:
/// four tiles across a phone leaves each one narrow, and a filter whose
/// label reads "Borrado..." is a filter the user has to guess at. Shrinking
/// the glyphs keeps every option fully readable at any width and at the
/// app's 1.4x text-scale ceiling.
class _FilterCard extends StatefulWidget {
  const _FilterCard({
    required this.index,
    required this.filter,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final _SurveyFilter filter;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterCard> createState() => _FilterCardState();
}

class _FilterCardState extends State<_FilterCard> {
  bool _visible = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.filter.colorFor(theme);
    final isOn = widget.selected;

    return Semantics(
      button: true,
      selected: isOn,
      label: '${widget.filter.label}, ${widget.value}',
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: () {
          if (!isOn) HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 0.25),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 320),
            child: AnimatedScale(
              scale: _visible ? (_pressed ? 0.94 : 1) : 0.9,
              duration: Duration(milliseconds: _pressed ? 120 : 460),
              curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isOn ? 0.18 : 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: color.withValues(alpha: isOn ? 0.95 : 0.20),
                    width: isOn ? 2 : 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isOn ? color : color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.filter.icon,
                        size: 18,
                        color: isOn ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: widget.value),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, animated, _) => Text(
                        '$animated',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOn ? color : theme.colorScheme.onSurface,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.filter.label,
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isOn ? color : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isOn ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
