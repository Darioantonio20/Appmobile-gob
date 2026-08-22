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

    // No app bar: its title and bottom separator were removed by explicit
    // design direction. The survey's name is now presented properly in the
    // header below (with an icon and a "Llenando encuesta" caption) instead
    // of as a bare line of toolbar text, and the back control matches the
    // profile screen's.
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FillHeader(title: state is SurveyFillReady ? state.survey.title : 'Encuesta'),
            Expanded(
              child: switch (state) {
                SurveyFillLoading() => const LoadingView(message: 'Cargando encuesta…'),
                SurveyFillNotFound(:final message) => EmptyStateView(
                    title: 'No se encontró la encuesta',
                    message: message ?? 'Vuelve a la lista e inténtalo de nuevo.',
                    icon: Icons.search_off_rounded,
                  ),
                SurveyFillReady() => _FillBody(state: state, controller: ref.read(provider.notifier)),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Back control plus the survey's name. The name used to be plain app-bar
/// text, which read as unfinished for what is the single most important
/// label on the screen — it's now paired with an icon badge and a caption
/// saying what the user is actually doing, and gets two lines before it
/// truncates rather than one.
class _FillHeader extends StatelessWidget {
  const _FillHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandBackButton(color: theme.colorScheme.tertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Llenando encuesta',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
          // Autosave status moved up here from the bottom action bar, where
          // it sat wedged between the back arrow and "Siguiente" and read
          // as a third, broken button. It is status, not an action, so it
          // belongs with the other status on screen — and the bottom bar is
          // now just the two things you can actually press.
          isSaving: state.isSaving,
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
                    // Keyed by section *and* by which questions are actually
                    // showing: a logic jump can change the latter without
                    // changing the former (e.g. answering the gating
                    // question swaps in a different follow-up right after
                    // it, same section) — reusing this fade+slide transition
                    // for that case too, rather than an instant layout jump.
                    key: ValueKey('${state.currentSectionIndex}:${state.currentQuestions.map((q) => q.id).join(',')}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, question) in state.currentQuestions.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
      // Tightened throughout after feedback that these cards ate too much
      // of the screen: the number badge and the required/optional tag now
      // share the *same* line as the question text instead of occupying a
      // header row of their own above it, and the vertical rhythm dropped a
      // step (md -> sm) between every block. Same information, roughly a
      // third less height per question.
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$questionNumber',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  question.text,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              if (question.isRequired) ...[
                const SizedBox(width: AppSpacing.xs),
                // Only "Obligatoria" earns a tag now. "Opcional" was the
                // default state on most questions, so tagging it added a
                // chip to nearly every card to say "nothing special here".
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Obligatoria',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

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
            // Just the two real actions now — the autosave status that used
            // to sit between them moved into the progress card at the top
            // of the screen.
            Expanded(
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
