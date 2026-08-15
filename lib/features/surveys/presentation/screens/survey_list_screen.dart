import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/result.dart';
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
      appBar: AppBar(
        title: Text(user == null ? 'Encuestas' : 'Hola, ${user.name.split(' ').first}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmLogout(context, ref),
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
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.gridColumns(context),
                  mainAxisExtent: 168,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemCount: surveys.length,
                itemBuilder: (context, index) {
                  final survey = surveys[index];
                  return SurveyCard(
                    survey: survey,
                    latestResponse: responsesBySurvey[survey.id],
                    onTap: () => context.push(RoutePaths.surveyDetailPath(survey.id)),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}
