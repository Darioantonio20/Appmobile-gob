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
    this.surveyorId,
    this.surveyorName,
    this.startedAt,
    this.latitude,
    this.longitude,
    this.appVersion,
  });

  final String localId;
  final String? serverId;
  final String surveyId;
  final String surveyTitle;

  /// `{ questionId: answerValue }`. Value shape depends on the question
  /// type: `String` (text/date/single-choice), `List<String>`
  /// (multiple-choice), `num` (scale), or `Map<String, String>`
  /// (row id → chosen option, for a Likert matrix). A synthetic
  /// `"<questionId>_other"` key holds the free-text value when the user
  /// picked "Otra (especifica)" — see `SurveyQuestion.otherAnswerKey`.
  final Map<String, Object?> answers;

  final SyncStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? syncedAt;
  final int retryCount;
  final String? lastError;

  // --- Audit metadata (Módulo C) ---------------------------------------

  /// Identifies who collected this response — the folio's owner. Filled in
  /// from the logged-in session when the draft is created.
  final String? surveyorId;
  final String? surveyorName;

  /// When the user actually started filling this one out (as opposed to
  /// [createdAt], which is the same instant for a fresh draft but is a DB
  /// concept — kept both because a resumed draft's `createdAt` shouldn't
  /// change, while this is set once, at first creation, for audit).
  final DateTime? startedAt;

  /// GPS captured on a best-effort basis when the survey is started —
  /// `null` when location services/permission aren't available. A survey
  /// is never blocked on acquiring a location fix.
  final double? latitude;
  final double? longitude;

  /// App version at the time this response was recorded, for support/audit.
  final String? appVersion;

  /// The human-readable folio for this response — the same UUID used as
  /// its local/idempotency identity, just labeled for display.
  String get folio => localId;

  bool get hasLocation => latitude != null && longitude != null;

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
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}
