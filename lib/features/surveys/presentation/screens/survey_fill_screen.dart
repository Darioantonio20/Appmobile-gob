import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/brand_app_bar.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/survey.dart';
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

    return Column(
      children: [
        SurveyProgressBar(
          progress: state.progress,
          current: state.sectionNumber,
          total: state.totalSections,
          sectionTitle: state.totalSections > 1 ? section.title : null,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                      for (final (index, question) in state.currentQuestions.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _QuestionCard(
                            questionNumber: index + 1,
                            question: question,
                            answerValue: state.answers[question.id],
                            textAnswers: state.answers,
                            errorText: state.errorFor(question),
                            onChanged: (value) => controller.setAnswer(question.id, value),
                            onTextAnswerChanged: controller.setAnswer,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.questionNumber,
    required this.question,
    required this.answerValue,
    required this.textAnswers,
    required this.onChanged,
    this.onTextAnswerChanged,
    this.errorText,
  });

  final int questionNumber;
  final SurveyQuestion question;
  final Object? answerValue;
  final Map<String, Object?> textAnswers;
  final ValueChanged<Object?> onChanged;
  final void Function(String key, String value)? onTextAnswerChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: hasError
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.65),
          width: hasError ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Number Badge + Required/Optional Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$questionNumber',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: question.isRequired
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  question.isRequired ? 'Obligatoria' : 'Opcional',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: question.isRequired
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: question.isRequired ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Question Title
          Text(
            question.text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Question Input Field
          QuestionField(
            question: question,
            value: answerValue,
            textAnswers: textAnswers,
            errorText: errorText,
            onChanged: onChanged,
            onTextAnswerChanged: onTextAnswerChanged,
          ),
        ],
      ),
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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
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
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: state.isSaving
                    ? Row(
                        key: const ValueKey('saving'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'Guardando…',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('saved'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Guardado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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
      ),
    );
  }
}
