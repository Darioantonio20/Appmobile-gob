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
      // `GET /surveys` never includes questions — only `GET /surveys/{id}`
      // does. Prefetch every assigned survey's full detail now, in the
      // background, so the encuestador can open and fill any of them later
      // with zero connectivity (the whole point of going out to a
      // community). Fire-and-forget: the list screen doesn't wait on this,
      // and a failed prefetch here just means that one survey falls back to
      // whatever was already cached (or an on-open retry via [getSurvey]).
      unawaited(_prefetchFullSurveys(surveys));
      return Result.success(surveys);
    } catch (e) {
      _log.warning('No se pudo refrescar encuestas; se conserva la caché local', e);
      return Result.failure(mapNetworkError(e));
    }
  }

  Future<void> _prefetchFullSurveys(List<Survey> surveys) async {
    for (final survey in surveys) {
      try {
        final full = await _remote.fetchSurvey(survey.id);
        await _local.cacheSurvey(full);
      } catch (e) {
        _log.warning('No se pudo precargar la encuesta ${survey.id} para uso sin conexión', e);
      }
    }
  }

  @override
  Future<Survey?> getSurvey(String id) async {
    // Offline-first with a fresh-when-possible bias: try the network first
    // (so edits made on the backend show up), and only fall back to
    // whatever's cached locally when that fails — no connectivity, server
    // error, the survey no longer being assigned, etc. This is also what
    // makes [SurveyRemoteDataSource.fetchSurvey] (`GET /surveys/{id}`)
    // actually get called — without it, a survey's `sections` never made it
    // past the list-only cache from [refreshSurveys], and filling/sending
    // it was impossible.
    try {
      final survey = await _remote.fetchSurvey(id);
      await _local.cacheSurvey(survey);
      return survey;
    } catch (e) {
      _log.warning('No se pudo descargar la encuesta $id; se usa la copia local si existe', e);
      return _local.getSurvey(id);
    }
  }

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
    String? surveyorId,
    String? surveyorName,
    double? latitude,
    double? longitude,
    String? appVersion,
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
      surveyorId: surveyorId ?? existing?.surveyorId,
      surveyorName: surveyorName ?? existing?.surveyorName,
      startedAt: existing?.startedAt ?? now,
      latitude: latitude ?? existing?.latitude,
      longitude: longitude ?? existing?.longitude,
      appVersion: appVersion ?? existing?.appVersion,
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
  Future<void> attachDraftMetadata({
    required String localId,
    double? latitude,
    double? longitude,
    String? appVersion,
  }) {
    return _local.attachMetadata(localId, latitude: latitude, longitude: longitude, appVersion: appVersion);
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
      // The answers payload needs each question's type (to know whether a
      // raw value is an option id, free text, or a number — see
      // SurveyRemoteDataSource._buildAnswers), so the survey itself has to
      // come along, not just the response.
      final survey = await _local.getSurvey(response.surveyId);
      if (survey == null) {
        throw StateError('La encuesta ${response.surveyId} ya no está disponible localmente.');
      }
      await _remote.submitResponse(survey, response);
      await _local.markStatus(
        response.localId,
        status: SyncStatus.synced,
        // The real endpoint just confirms with a message, no server-side
        // id to store — response_id (this response's own localId) is
        // already what identifies it end to end.
        serverId: response.localId,
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
