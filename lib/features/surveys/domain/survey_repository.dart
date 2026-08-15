import '../../../core/utils/result.dart';
import 'survey.dart';
import 'survey_response.dart';

/// Contract the presentation layer codes against — offline-first by
/// construction: every read is a local (Drift) read/stream, and the only
/// method that talks to the network directly is [refreshSurveys]. Writing
/// an answer never touches the network at all (see [saveDraft]/[submit]);
/// getting it to the server is entirely the sync engine's job
/// ([syncPendingResponses]/[retrySingle]).
abstract class SurveyRepository {
  /// Reactive list of cached, active surveys — works fully offline.
  Stream<List<Survey>> watchSurveys();

  /// Hits the backend for the current survey list and replaces the local
  /// cache on success. Failure (e.g. offline) is reported but never thrown
  /// — the UI keeps showing whatever was already cached.
  Future<Result<List<Survey>>> refreshSurveys();

  Future<Survey?> getSurvey(String id);

  Stream<List<SurveyResponse>> watchResponsesForSurvey(String surveyId);

  /// All responses, newest-edited first — backs the Sync Center.
  Stream<List<SurveyResponse>> watchAllResponses();

  /// Responses still owed to the server (`pending` or `failed`).
  Stream<List<SurveyResponse>> watchSyncableResponses();

  Future<SurveyResponse?> getResponse(String localId);

  /// Creates (when [localId] is null) or updates a local draft. Purely
  /// local — safe to call as often as needed (e.g. on every answer change)
  /// regardless of connectivity.
  ///
  /// The audit fields ([surveyorId] through [appVersion]) are only ever
  /// meant to be captured once, when the response is first created — pass
  /// them on that first call; every later autosave call omits them and the
  /// previously-stored values are carried forward untouched.
  Future<SurveyResponse> saveDraft({
    required Survey survey,
    String? localId,
    required Map<String, Object?> answers,
    String? surveyorId,
    String? surveyorName,
    double? latitude,
    double? longitude,
    String? appVersion,
  });

  /// Marks a draft as ready to send (`pending`) and kicks off a best-effort
  /// immediate send attempt. Returns as soon as the local write completes —
  /// callers don't need to wait for (or handle failure of) the network part,
  /// the response is durably queued either way.
  Future<void> submit(String localId);

  /// Narrow, answers-untouched update for the audit metadata (GPS, app
  /// version) that's captured asynchronously right after a response is
  /// created — see `SurveyFillController._captureStartMetadata`.
  Future<void> attachDraftMetadata({
    required String localId,
    double? latitude,
    double? longitude,
    String? appVersion,
  });

  Future<void> discardDraft(String localId);

  /// Sends every `pending`/`failed` response it can. This is what gets
  /// registered as the sync engine's handler.
  Future<void> syncPendingResponses();

  /// Manual "reintentar" for a single response from the Sync Center.
  Future<void> retrySingle(String localId);
}
