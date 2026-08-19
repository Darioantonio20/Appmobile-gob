import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand_app_bar.dart';
import '../../../../core/widgets/state_views.dart';
import '../survey_fill_controller.dart';
import '../widgets/question_field.dart';
import '../widgets/survey_progress_bar.dart';

class SurveyFillScreen extends ConsumerWidget {
  const SurveyFillScreen({super.key, required this.surveyId, this.responseLocalId});

  final String surveyId;
  final String? responseLocalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = SurveyFillArgs(surveyId: surveyId, responseLocalId: responseLocalId);
    final provider = surveyFillControllerProvider(args);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (next is SurveyFillReady && next.justSubmitted) {
        context.pushReplacement(RoutePaths.surveySuccessPath(surveyId));
      }
    });

    return Scaffold(
      appBar: BrandAppBar(
        title: Text(state is SurveyFillReady ? state.survey.title : 'Encuesta'),
      ),
      body: switch (state) {
        SurveyFillLoading() => const LoadingView(message: 'Cargando encuesta…'),
        SurveyFillNotFound() => const EmptyStateView(
            title: 'No se encontró la encuesta',
            message: 'Vuelve a la lista e inténtalo de nuevo.',
            icon: Icons.search_off_rounded,
          ),
        SurveyFillReady() => _FillBody(state: state, controller: ref.read(provider.notifier)),
      },
    );
  }
}

class _FillBody extends StatelessWidget {
  const _FillBody({required this.state, required this.controller});

  final SurveyFillReady state;
  final SurveyFillController controller;

  @override
  Widget build(BuildContext context) {
    final section = state.currentSection;
    final isTablet = Responsive.isTabletOrWider(context);
    // A whole section's worth of questions on screen at once, scrolled
    // together — not the old "one question, tap Next" flow. Sections are
    // usually 2-4 questions (see the sample surveys), which is enough to
    // scroll through comfortably without feeling like a wall of text; a
    // section with a lot more than that would be a survey-authoring
    // problem, not something the fill screen should try to paper over by
    // inventing its own arbitrary chunking on top of the survey's own
    // structure.
    final questionSpacing = isTablet ? AppSpacing.xxl : AppSpacing.xl;

    return Column(
      children: [
        SurveyProgressBar(
          progress: state.progress,
          current: state.sectionNumber,
          total: state.totalSections,
          sectionTitle: state.totalSections > 1 ? section.title : null,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: ResponsiveCenter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(state.currentSectionIndex),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, question) in state.currentQuestions.indexed) ...[
                      if (index > 0) ...[
                        SizedBox(height: questionSpacing),
                        const Divider(height: 1),
                        SizedBox(height: questionSpacing),
                      ],
                      if (!question.isRequired)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            'Opcional',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      Text(
                        question.text,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Theme.of(context).colorScheme.secondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      QuestionField(
                        question: question,
                        value: state.answers[question.id],
                        textAnswers: state.answers,
                        errorText: state.errorFor(question),
                        onChanged: (value) => controller.setAnswer(question.id, value),
                        onTextAnswerChanged: controller.setAnswer,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
        _FillNavigationBar(state: state, controller: controller),
      ],
    );
  }
}

class _FillNavigationBar extends StatelessWidget {
  const _FillNavigationBar({required this.state, required this.controller});

  final SurveyFillReady state;
  final SurveyFillController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: state.isFirstSection ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(
              ignoring: state.isFirstSection,
              child: SizedBox(
                height: AppSpacing.buttonHeight,
                width: AppSpacing.buttonHeight,
                child: OutlinedButton(
                  onPressed: controller.goBack,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedSwitcher(
              // Was an instant if/else swap (Spacer() <-> spinner+text) —
              // popped in/out with a layout jump exactly when autosave
              // happened to fire around the same time as a section
              // transition, reading as a flicker/glitch. This fades and
              // resizes smoothly instead.
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: state.isSaving
                  ? Row(
                      key: const ValueKey('saving'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Guardando…',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    )
                  : const SizedBox(key: ValueKey('idle')),
            ),
          ),
          Expanded(
            flex: 3,
            child: AppButton(
              label: state.isLastSection ? 'Enviar encuesta' : 'Siguiente',
              icon: state.isLastSection ? Icons.send_rounded : Icons.arrow_forward_rounded,
              isLoading: state.isSubmitting,
              onPressed: () {
                if (state.isLastSection) {
                  controller.submit();
                } else {
                  controller.goNext();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
