import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_status.dart';
import '../domain/survey.dart';
import '../domain/survey_response.dart';

/// Owns every Drift ↔ domain conversion for this feature. Nothing outside
/// `data/` ever sees a [SurveyRow]/[SurveyResponseRow] or touches
/// `jsonEncode`/`jsonDecode` for these entities — that's the whole point of
/// having this layer.
class SurveyLocalDataSource {
  SurveyLocalDataSource(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------------
  // Surveys cache
  // ---------------------------------------------------------------------

  Stream<List<Survey>> watchActiveSurveys() {
    return _db.watchActiveSurveys().map((rows) => rows.map(_surveyFromRow).toList());
  }

  Future<Survey?> getSurvey(String id) async {
    final row = await _db.getSurveyById(id);
    return row == null ? null : _surveyFromRow(row);
  }

  Future<void> cacheSurveys(List<Survey> surveys) {
    final now = DateTime.now();
    return _db.replaceAllSurveys(
      surveys
          .map((s) => SurveysTableCompanion.insert(
                id: s.id,
                title: s.title,
                description: Value(s.description),
                questionsJson: jsonEncode(s.questions.map((q) => q.toJson()).toList()),
                updatedAt: s.updatedAt,
                fetchedAt: now,
              ))
          .toList(),
    );
  }

  Survey _surveyFromRow(SurveyRow row) {
    final questionsRaw = jsonDecode(row.questionsJson) as List<dynamic>;
    return Survey(
      id: row.id,
      title: row.title,
      description: row.description,
      updatedAt: row.updatedAt,
      questions: questionsRaw.map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>)).toList(),
    );
  }

  // ---------------------------------------------------------------------
  // Responses
  // ---------------------------------------------------------------------

  Stream<List<SurveyResponse>> watchResponsesForSurvey(String surveyId) {
    return _db.watchResponsesForSurvey(surveyId).map((rows) => rows.map(_responseFromRow).toList());
  }

  Stream<List<SurveyResponse>> watchAllResponses() {
    return _db.watchAllResponses().map((rows) => rows.map(_responseFromRow).toList());
  }

  Stream<List<SurveyResponse>> watchSyncableResponses() {
    return _db.watchSyncableResponses().map((rows) => rows.map(_responseFromRow).toList());
  }

  Future<List<SurveyResponse>> getSyncableResponses() async {
    final rows = await _db.getSyncableResponses();
    return rows.map(_responseFromRow).toList();
  }

  Future<SurveyResponse?> getResponse(String localId) async {
    final row = await _db.getResponseByLocalId(localId);
    return row == null ? null : _responseFromRow(row);
  }

  Future<void> saveResponse(SurveyResponse response) {
    return _db.upsertResponse(
      SurveyResponsesTableCompanion.insert(
        localId: response.localId,
        serverId: Value(response.serverId),
        surveyId: response.surveyId,
        surveyTitle: response.surveyTitle,
        answersJson: jsonEncode(response.answers),
        status: Value(response.status.name),
        createdAt: response.createdAt,
        updatedAt: response.updatedAt,
        submittedAt: Value(response.submittedAt),
        syncedAt: Value(response.syncedAt),
        retryCount: Value(response.retryCount),
        lastError: Value(response.lastError),
      ),
    );
  }

  Future<void> markStatus(
    String localId, {
    required SyncStatus status,
    String? serverId,
    DateTime? syncedAt,
    int? retryCount,
    String? lastError,
  }) {
    return _db.updateResponseStatus(
      localId,
      status: status.name,
      serverId: serverId,
      syncedAt: syncedAt,
      retryCount: retryCount,
      lastError: Value(lastError),
    );
  }

  Future<void> deleteResponse(String localId) => _db.deleteResponse(localId);

  SurveyResponse _responseFromRow(SurveyResponseRow row) {
    return SurveyResponse(
      localId: row.localId,
      serverId: row.serverId,
      surveyId: row.surveyId,
      surveyTitle: row.surveyTitle,
      answers: Map<String, Object?>.from(jsonDecode(row.answersJson) as Map),
      status: SyncStatus.fromName(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      submittedAt: row.submittedAt,
      syncedAt: row.syncedAt,
      retryCount: row.retryCount,
      lastError: row.lastError,
    );
  }
}

final surveyLocalDataSourceProvider = Provider<SurveyLocalDataSource>((ref) {
  return SurveyLocalDataSource(ref.watch(appDatabaseProvider));
});
