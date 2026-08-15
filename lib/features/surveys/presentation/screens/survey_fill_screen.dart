import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
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
      appBar: AppBar(
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
    final question = state.currentQuestion;
    final (section, sectionNumber) = state.currentSectionInfo;
    final showSectionLabel = state.survey.sections.length > 1;

    return Column(
      children: [
        SurveyProgressBar(
          progress: state.progress,
          current: state.currentQuestionIndex + 1,
          total: state.survey.allQuestions.length,
          sectionLabel: showSectionLabel
              ? 'Sección $sectionNumber de ${state.survey.sections.length}'
                  '${section.title.isNotEmpty ? ' · ${section.title}' : ''}'
              : null,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: ResponsiveCenter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(question.id),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    Text(question.text, style: Theme.of(context).textTheme.headlineSmall),
                    if (question.helperText != null && question.helperText!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        question.helperText!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    QuestionField(
                      question: question,
                      value: state.answers[question.id],
                      otherValue: state.currentOtherValue,
                      errorText: state.currentQuestionError,
                      onChanged: (value) => controller.setAnswer(question.id, value),
                      onOtherChanged: (text) => controller.setAnswer(question.otherAnswerKey, text),
                    ),
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
            opacity: state.isFirstQuestion ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(
              ignoring: state.isFirstQuestion,
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
          if (state.isSaving) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Guardando…', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
          ] else
            const Spacer(),
          Expanded(
            flex: 3,
            child: AppButton(
              label: state.isLastQuestion ? 'Enviar encuesta' : 'Siguiente',
              icon: state.isLastQuestion ? Icons.send_rounded : Icons.arrow_forward_rounded,
              isLoading: state.isSubmitting,
              onPressed: () {
                if (state.isLastQuestion) {
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
