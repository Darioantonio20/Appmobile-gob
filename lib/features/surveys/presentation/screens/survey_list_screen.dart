import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../core/router/route_paths.dart';
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

class SurveyListScreen extends ConsumerStatefulWidget {
  const SurveyListScreen({super.key});

  @override
  ConsumerState<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends ConsumerState<SurveyListScreen> {
  @override
  void initState() {
    super.initState();
    // Best-effort refresh on open; the cached list (if any) is already
    // showing from the stream, so this only ever improves on what's there.
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    final result = await ref.read(surveyRepositoryProvider).refreshSurveys();
    if (!mounted) return;
    result.when(
      success: (_) {},
      failure: (failure) {
        // A network failure here just means "offline" — the cached list is
        // still showing, so there's nothing worth interrupting the user
        // for. Anything else (server/auth/unknown) is worth a heads-up.
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
      body: surveysAsync.when(
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
                    message: 'Cuando tengas encuestas asignadas aparecerán aquí. Desliza hacia abajo para buscar nuevas.',
                    icon: Icons.assignment_outlined,
                  ),
                ],
              ),
            );
          }

          final responsesBySurvey = <String, SurveyResponse>{};
          for (final response in responsesAsync.valueOrNull ?? const <SurveyResponse>[]) {
            // Streams are ordered newest-updated-first, so the first hit per
            // survey id is already the most relevant one to show.
            responsesBySurvey.putIfAbsent(response.surveyId, () => response);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ResponsiveCenter(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // A Wrap of fixed-width, natural-height cards — instead
                    // of GridView's fixed cell height — so a card never
                    // clips when its title/description wraps to a second
                    // line (long survey names) or the user bumps up system
                    // font size. Each card is free to be as tall as its own
                    // content needs.
                    final columns = Responsive.gridColumns(context);
                    const spacing = AppSpacing.md;
                    final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final (index, survey) in surveys.indexed)
                          SizedBox(
                            width: cardWidth,
                            child: StaggeredFadeSlideIn(
                              index: index,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
