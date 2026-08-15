import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_status.dart';
import 'survey.dart';

/// One locally-saved, filled-in survey (draft or submitted). This is the
/// domain view of a `SurveyResponsesTable` row — see
/// `data/survey_local_datasource.dart` for the Drift ↔ domain mapping.
@immutable
class SurveyResponse {
  const SurveyResponse({
    required this.localId,
    required this.surveyId,
    required this.surveyTitle,
    required this.answers,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
    this.submittedAt,
    this.syncedAt,
    this.retryCount = 0,
    this.lastError,
  });

  final String localId;
  final String? serverId;
  final String surveyId;
  final String surveyTitle;

  /// `{ questionId: answerValue }`. Value shape depends on the question
  /// type: `String` (text/date/single-choice), `List<String>`
  /// (multiple-choice), or `num` (scale).
  final Map<String, Object?> answers;

  final SyncStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? syncedAt;
  final int retryCount;
  final String? lastError;

  /// Fraction (0–1) of [questions] that currently have an answer, used for
  /// progress indicators on survey cards / the Sync Center.
  double progressFor(List<SurveyQuestion> questions) {
    if (questions.isEmpty) return 0;
    final answered = questions.where((q) => _hasValue(answers[q.id])).length;
    return answered / questions.length;
  }

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }
}
