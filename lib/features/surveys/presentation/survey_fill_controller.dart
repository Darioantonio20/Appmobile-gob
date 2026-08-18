import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/utils/app_info.dart';
import '../../auth/presentation/auth_controller.dart';
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
    required this.currentSectionIndex,
    this.isSaving = false,
    this.isSubmitting = false,
    this.showValidation = false,
    this.justSubmitted = false,
  });

  final Survey survey;
  final String localId;
  final Map<String, Object?> answers;

  /// One "page" is a whole [SurveySection] now, scrolled through together —
  /// not one question at a time. A section is the natural unit to chunk on:
  /// it's already how surveys are authored/grouped, so this reuses that
  /// boundary instead of inventing an arbitrary "N questions per page" that
  /// would ignore the survey's own structure.
  final int currentSectionIndex;
  final bool isSaving;
  final bool isSubmitting;

  /// Whether validation errors should currently be shown. Applies to every
  /// question in [currentSection] at once (see [errorFor]) — with several
  /// questions on screen together, "the current question" no longer singles
  /// out just one to validate.
  final bool showValidation;
  final bool justSubmitted;

  SurveySection get currentSection => survey.sections[currentSectionIndex];
  List<SurveyQuestion> get currentQuestions => currentSection.questions;
  int get sectionNumber => currentSectionIndex + 1;
  int get totalSections => survey.sections.length;

  bool get isFirstSection => currentSectionIndex == 0;
  bool get isLastSection => currentSectionIndex == totalSections - 1;
  double get progress => totalSections == 0 ? 0 : (currentSectionIndex + 1) / totalSections;

  String? otherValueFor(SurveyQuestion question) => answers[question.otherAnswerKey] as String?;

  String? errorFor(SurveyQuestion question) =>
      showValidation ? question.validate(answers[question.id], otherValue: otherValueFor(question)) : null;

  SurveyFillReady copyWith({
    Map<String, Object?>? answers,
    int? currentSectionIndex,
    bool? isSaving,
    bool? isSubmitting,
    bool? showValidation,
    bool? justSubmitted,
  }) {
    return SurveyFillReady(
      survey: survey,
      localId: localId,
      answers: answers ?? this.answers,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      isSaving: isSaving ?? this.isSaving,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showValidation: showValidation ?? this.showValidation,
      justSubmitted: justSubmitted ?? this.justSubmitted,
    );
  }
}

/// Drives one "fill in a survey" session: loads (or creates) the draft,
/// tracks the current section, validates, autosaves to SQLite on every
/// change (debounced) so nothing is lost if the app is killed mid-fill, and
/// hands off to the repository on submit.
///
/// GPS + app version (Módulo C metadata) are captured once, in the
/// background, right after a *new* draft is created — never blocking the
/// user from starting to answer while a location fix is still pending.
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
        currentSectionIndex: 0,
      );
      return;
    }

    final user = _ref.read(authControllerProvider);
    final draft = await repo.saveDraft(
      survey: survey,
      answers: const {},
      surveyorId: user?.id,
      surveyorName: user?.name,
    );
    state = SurveyFillReady(survey: survey, localId: draft.localId, answers: const {}, currentSectionIndex: 0);

    unawaited(_captureStartMetadata(draft.localId));
  }

  /// Fire-and-forget GPS + app-version capture for a brand new response.
  /// Uses a narrow, answers-untouched update (`attachMetadata`) instead of
  /// round-tripping through [saveDraft], so it can never race with — and
  /// clobber — an answer the user typed while the location fix was still
  /// resolving.
  Future<void> _captureStartMetadata(String localId) async {
    final fix = await _ref.read(locationServiceProvider).getCurrentFix();
    final version = await _ref.read(appVersionProvider.future);
    await _ref.read(surveyRepositoryProvider).attachDraftMetadata(
          localId: localId,
          latitude: fix?.latitude,
          longitude: fix?.longitude,
          appVersion: version,
        );
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

  /// Validates every question in the current section and advances if they
  /// all pass. Returns false (and surfaces validation messages inline on
  /// whichever question(s) failed) otherwise.
  bool goNext() {
    final current = state;
    if (current is! SurveyFillReady) return false;
    final hasError = current.currentQuestions.any(
      (q) => q.validate(current.answers[q.id], otherValue: current.otherValueFor(q)) != null,
    );
    if (hasError) {
      state = current.copyWith(showValidation: true);
      return false;
    }
    if (current.isLastSection) return false;
    state = current.copyWith(currentSectionIndex: current.currentSectionIndex + 1, showValidation: false);
    return true;
  }

  void goBack() {
    final current = state;
    if (current is! SurveyFillReady || current.isFirstSection) return;
    state = current.copyWith(currentSectionIndex: current.currentSectionIndex - 1, showValidation: false);
  }

  /// Validates every question across every section before submitting; jumps
  /// to the first section with an invalid question if any fails. Returns
  /// true only when the response was actually queued for submission.
  Future<bool> submit() async {
    final current = state;
    if (current is! SurveyFillReady) return false;

    for (var i = 0; i < current.survey.sections.length; i++) {
      final hasError = current.survey.sections[i].questions.any(
        (q) => q.validate(current.answers[q.id], otherValue: current.answers[q.otherAnswerKey] as String?) != null,
      );
      if (hasError) {
        state = current.copyWith(currentSectionIndex: i, showValidation: true);
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
