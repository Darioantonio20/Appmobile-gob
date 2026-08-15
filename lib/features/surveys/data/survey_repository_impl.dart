import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/network_exceptions.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/result.dart';
import '../domain/survey.dart';
import '../domain/survey_repository.dart';
import '../domain/survey_response.dart';
import 'survey_local_datasource.dart';
import 'survey_remote_datasource.dart';

class SurveyRepositoryImpl implements SurveyRepository {
  SurveyRepositoryImpl(this._remote, this._local, this._uuid);

  final SurveyRemoteDataSource _remote;
  final SurveyLocalDataSource _local;
  final Uuid _uuid;
  final _log = AppLogger.of('SurveyRepository');

  @override
  Stream<List<Survey>> watchSurveys() => _local.watchActiveSurveys();

  @override
  Future<Result<List<Survey>>> refreshSurveys() async {
    try {
      final surveys = await _remote.fetchSurveys();
      await _local.cacheSurveys(surveys);
      return Result.success(surveys);
    } catch (e) {
      _log.warning('No se pudo refrescar encuestas; se conserva la caché local', e);
      return Result.failure(mapNetworkError(e));
    }
  }

  @override
  Future<Survey?> getSurvey(String id) => _local.getSurvey(id);

  @override
  Stream<List<SurveyResponse>> watchResponsesForSurvey(String surveyId) =>
      _local.watchResponsesForSurvey(surveyId);

  @override
  Stream<List<SurveyResponse>> watchAllResponses() => _local.watchAllResponses();

  @override
  Stream<List<SurveyResponse>> watchSyncableResponses() => _local.watchSyncableResponses();

  @override
  Future<SurveyResponse?> getResponse(String localId) => _local.getResponse(localId);

  @override
  Future<SurveyResponse> saveDraft({
    required Survey survey,
    String? localId,
    required Map<String, Object?> answers,
  }) async {
    final now = DateTime.now();
    final existing = localId == null ? null : await _local.getResponse(localId);
    final response = SurveyResponse(
      localId: localId ?? _uuid.v4(),
      serverId: existing?.serverId,
      surveyId: survey.id,
      surveyTitle: survey.title,
      answers: answers,
      status: existing?.status ?? SyncStatus.draft,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      submittedAt: existing?.submittedAt,
      syncedAt: existing?.syncedAt,
      retryCount: existing?.retryCount ?? 0,
      lastError: existing?.lastError,
    );
    await _local.saveResponse(response);
    return response;
  }

  @override
  Future<void> submit(String localId) async {
    final response = await _local.getResponse(localId);
    if (response == null) {
      _log.warning('submit() llamado con un localId desconocido: $localId');
      return;
    }

    final now = DateTime.now();
    final submitted = SurveyResponse(
      localId: response.localId,
      serverId: response.serverId,
      surveyId: response.surveyId,
      surveyTitle: response.surveyTitle,
      answers: response.answers,
      status: SyncStatus.pending,
      createdAt: response.createdAt,
      updatedAt: now,
      submittedAt: response.submittedAt ?? now,
      syncedAt: response.syncedAt,
      retryCount: response.retryCount,
      lastError: response.lastError,
    );
    await _local.saveResponse(submitted);

    // Best-effort immediate attempt. The caller doesn't wait on this — the
    // response is already durably `pending`, so if this fails (or we're
    // offline) the sync engine's reconnect/timer/manual-retry paths will
    // pick it up later. Data is never lost, only delayed.
    unawaited(_syncOne(submitted));
  }

  @override
  Future<void> discardDraft(String localId) => _local.deleteResponse(localId);

  @override
  Future<void> syncPendingResponses() async {
    final pending = await _local.getSyncableResponses();
    if (pending.isEmpty) return;
    _log.info('Sincronizando ${pending.length} respuesta(s) pendiente(s)…');
    for (final response in pending) {
      await _syncOne(response);
    }
  }

  @override
  Future<void> retrySingle(String localId) async {
    final response = await _local.getResponse(localId);
    if (response != null) await _syncOne(response);
  }

  Future<void> _syncOne(SurveyResponse response) async {
    await _local.markStatus(response.localId, status: SyncStatus.syncing);
    try {
      final serverId = await _remote.submitResponse(response);
      await _local.markStatus(
        response.localId,
        status: SyncStatus.synced,
        serverId: serverId,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      _log.warning('No se pudo enviar la respuesta ${response.localId}', e);
      await _local.markStatus(
        response.localId,
        status: SyncStatus.failed,
        retryCount: response.retryCount + 1,
        lastError: mapNetworkError(e).message,
      );
    }
  }
}

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepositoryImpl(
    ref.watch(surveyRemoteDataSourceProvider),
    ref.watch(surveyLocalDataSourceProvider),
    const Uuid(),
  );
});
