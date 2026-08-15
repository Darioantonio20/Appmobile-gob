import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/survey_repository_impl.dart';
import '../domain/survey.dart';

class SurveyFillArgs extends Equatable {
  const SurveyFillArgs({required this.surveyId, this.responseLocalId});

  final String surveyId;

  /// Pass an existing local id to resume a draft; leave null to start a
  /// fresh one.
  final String? responseLocalId;

  @override
  List<Object?> get props => [surveyId, responseLocalId];
}

sealed class SurveyFillState {
  const SurveyFillState();
}

class SurveyFillLoading extends SurveyFillState {
  const SurveyFillLoading();
}

/// The survey isn't in the local cache (e.g. deep link to a stale id, or
/// the cache was cleared). The screen shows a friendly "go back" state.
class SurveyFillNotFound extends SurveyFillState {
  const SurveyFillNotFound();
}

class SurveyFillReady extends SurveyFillState {
  const SurveyFillReady({
    required this.survey,
    required this.localId,
    required this.answers,
    required this.currentQuestionIndex,
    this.isSaving = false,
    this.isSubmitting = false,
    this.showValidation = false,
    this.justSubmitted = false,
  });

  final Survey survey;
  final String localId;
  final Map<String, Object?> answers;
  final int currentQuestionIndex;
  final bool isSaving;
  final bool isSubmitting;
  final bool showValidation;
  final bool justSubmitted;

  SurveyQuestion get currentQuestion => survey.questions[currentQuestionIndex];
  bool get isFirstQuestion => currentQuestionIndex == 0;
  bool get isLastQuestion => currentQuestionIndex == survey.questions.length - 1;
  double get progress =>
      survey.questions.isEmpty ? 0 : (currentQuestionIndex + 1) / survey.questions.length;
  String? get currentQuestionError =>
      showValidation ? currentQuestion.validate(answers[currentQuestion.id]) : null;

  SurveyFillReady copyWith({
    Map<String, Object?>? answers,
    int? currentQuestionIndex,
    bool? isSaving,
    bool? isSubmitting,
    bool? showValidation,
    bool? justSubmitted,
  }) {
    return SurveyFillReady(
      survey: survey,
      localId: localId,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isSaving: isSaving ?? this.isSaving,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showValidation: showValidation ?? this.showValidation,
      justSubmitted: justSubmitted ?? this.justSubmitted,
    );
  }
}

/// Drives one "fill in a survey" session: loads (or creates) the draft,
/// tracks the current question, validates, autosaves to SQLite on every
/// change (debounced) so nothing is lost if the app is killed mid-fill, and
/// hands off to the repository on submit.
class SurveyFillController extends StateNotifier<SurveyFillState> {
  SurveyFillController(this._ref, this._args) : super(const SurveyFillLoading()) {
    _init();
  }

  final Ref _ref;
  final SurveyFillArgs _args;
  Timer? _debounce;

  Future<void> _init() async {
    final repo = _ref.read(surveyRepositoryProvider);
    final survey = await repo.getSurvey(_args.surveyId);
    if (survey == null) {
      state = const SurveyFillNotFound();
      return;
    }

    if (_args.responseLocalId != null) {
      final existing = await repo.getResponse(_args.responseLocalId!);
      state = SurveyFillReady(
        survey: survey,
        localId: _args.responseLocalId!,
        answers: existing?.answers ?? {},
        currentQuestionIndex: 0,
      );
    } else {
      final draft = await repo.saveDraft(survey: survey, answers: const {});
      state = SurveyFillReady(survey: survey, localId: draft.localId, answers: const {}, currentQuestionIndex: 0);
    }
  }

  void setAnswer(String questionId, Object? value) {
    final current = state;
    if (current is! SurveyFillReady) return;
    final answers = Map<String, Object?>.from(current.answers)..[questionId] = value;
    state = current.copyWith(answers: answers, showValidation: false);
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _saveDraftNow);
  }

  Future<void> _saveDraftNow() async {
    final current = state;
    if (current is! SurveyFillReady) return;
    state = current.copyWith(isSaving: true);
    await _ref.read(surveyRepositoryProvider).saveDraft(
          survey: current.survey,
          localId: current.localId,
          answers: current.answers,
        );
    final after = state;
    if (after is SurveyFillReady) state = after.copyWith(isSaving: false);
  }

  /// Validates the current question and advances if it passes. Returns
  /// false (and surfaces the validation message) otherwise.
  bool goNext() {
    final current = state;
    if (current is! SurveyFillReady) return false;
    if (current.currentQuestion.validate(current.answers[current.currentQuestion.id]) != null) {
      state = current.copyWith(showValidation: true);
      return false;
    }
    if (current.isLastQuestion) return false;
    state = current.copyWith(currentQuestionIndex: current.currentQuestionIndex + 1, showValidation: false);
    return true;
  }

  void goBack() {
    final current = state;
    if (current is! SurveyFillReady || current.isFirstQuestion) return;
    state = current.copyWith(currentQuestionIndex: current.currentQuestionIndex - 1, showValidation: false);
  }

  /// Validates every question (not just the current one) before submitting;
  /// jumps to the first invalid question if any fails. Returns true only
  /// when the response was actually queued for submission.
  Future<bool> submit() async {
    final current = state;
    if (current is! SurveyFillReady) return false;

    for (var i = 0; i < current.survey.questions.length; i++) {
      final question = current.survey.questions[i];
      if (question.validate(current.answers[question.id]) != null) {
        state = current.copyWith(currentQuestionIndex: i, showValidation: true);
        return false;
      }
    }

    _debounce?.cancel();
    state = current.copyWith(isSubmitting: true);
    final repo = _ref.read(surveyRepositoryProvider);
    await repo.saveDraft(survey: current.survey, localId: current.localId, answers: current.answers);
    await repo.submit(current.localId);

    final after = state;
    if (after is SurveyFillReady) state = after.copyWith(isSubmitting: false, justSubmitted: true);
    return true;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final surveyFillControllerProvider =
    StateNotifierProvider.autoDispose.family<SurveyFillController, SurveyFillState, SurveyFillArgs>(
  (ref, args) => SurveyFillController(ref, args),
);
