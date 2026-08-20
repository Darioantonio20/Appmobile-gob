import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection/connection.dart';

part 'app_database.g.dart';

/// Locally-cached surveys, as last fetched from the backend.
///
/// Sections/questions are stored as one JSON blob ([sectionsJson]) rather
/// than normalized child tables: a survey's structure is always
/// read/written as one unit (never queried section-by-section or
/// question-by-question), so normalizing it would only add join complexity
/// for no benefit. The JSON is decoded into typed [SurveySection] objects
/// at the repository boundary — nothing above `data/` ever touches raw
/// JSON.
@DataClassName('SurveyRow')
class SurveysTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  /// The survey's [SurveySection] list (each with its nested questions),
  /// as JSON — see the class doc for why this whole tree is one blob
  /// rather than normalized tables.
  TextColumn get sectionsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Assignment/availability window from the backend (added in schema v4) —
  /// informational only; see `Survey.validFrom`/`validUntil`.
  DateTimeColumn get validFrom => dateTime().nullable()();
  DateTimeColumn get validUntil => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One locally-saved, filled-in survey — the offline-first core of the app.
///
/// A row is created the moment the user starts filling a survey ([status] =
/// draft) and lives entirely on-device until submitted. Submitting flips it
/// to `pending`; from there the sync engine (`core/sync/sync_service.dart`)
/// owns moving it to `syncing` → `synced`/`failed`. There's no separate
/// "sync queue" table — `status IN ('pending', 'failed')` *is* the queue,
/// so there's exactly one place that can go out of sync with reality.
@DataClassName('SurveyResponseRow')
class SurveyResponsesTable extends Table {
  /// Client-generated UUID. This is the row's real identity — a draft or
  /// pending response has no server id yet, and using a stable local id
  /// (instead of, say, an autoincrement int) means a response created
  /// offline can be safely retried/deduplicated once it does reach the
  /// server (send it as the idempotency key).
  TextColumn get localId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get surveyId => text()();

  /// Snapshot of the survey title at fill time, so the Sync Center can
  /// always show something meaningful even if the survey cache is later
  /// replaced or the survey is no longer active.
  TextColumn get surveyTitle => text()();

  /// `{ questionId: answerValue }`. Answer shapes vary by question type —
  /// text, a string list, or a number — decoded into typed answers at the
  /// `data/` layer boundary (see `survey_local_datasource.dart`).
  TextColumn get answersJson => text()();

  /// [SyncStatus] name: draft | pending | syncing | synced | failed.
  TextColumn get status => text().withDefault(const Constant('draft'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get submittedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  // --- Audit metadata (added in schema v2) ---
  TextColumn get surveyorId => text().nullable()();
  TextColumn get surveyorName => text().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get appVersion => text().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}

@DriftDatabase(tables: [SurveysTable, SurveyResponsesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Lets tests (or a future desktop-only tool) inject an in-memory
  /// connection instead of opening a real file.
  AppDatabase.withConnection(super.connection);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(surveyResponsesTable, surveyResponsesTable.surveyorId);
            await m.addColumn(surveyResponsesTable, surveyResponsesTable.surveyorName);
            await m.addColumn(surveyResponsesTable, surveyResponsesTable.startedAt);
            await m.addColumn(surveyResponsesTable, surveyResponsesTable.latitude);
            await m.addColumn(surveyResponsesTable, surveyResponsesTable.longitude);
            await m.addColumn(surveyResponsesTable, surveyResponsesTable.appVersion);
          }
          if (from < 3) {
            // surveys_table is a pure, disposable cache (always fully
            // replaced on the next successful `/surveys` fetch — see
            // `replaceAllSurveys`), so the simplest safe migration for its
            // reshaped `questionsJson` → `sectionsJson` column is to just
            // recreate the table empty rather than transform old rows.
            await m.deleteTable('surveys_table');
            await m.createTable(surveysTable);
          }
          if (from < 4) {
            await m.addColumn(surveysTable, surveysTable.validFrom);
            await m.addColumn(surveysTable, surveysTable.validUntil);
          }
        },
      );

  // ---------------------------------------------------------------------
  // Surveys
  // ---------------------------------------------------------------------

  Stream<List<SurveyRow>> watchActiveSurveys() {
    return (select(surveysTable)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.title)]))
        .watch();
  }

  Future<SurveyRow?> getSurveyById(String id) {
    return (select(surveysTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<SurveyRow>> getAllSurveys() => select(surveysTable).get();

  /// The survey list endpoint returns the full authoritative set on every
  /// fetch, so we replace the whole local cache in one transaction rather
  /// than trying to diff it. This is safe because user data (answers)
  /// lives in [SurveyResponsesTable], never here.
  ///
  /// Callers are responsible for carrying over each survey's previously
  /// downloaded `sectionsJson` when the incoming data doesn't include it
  /// (the list endpoint never does) — see
  /// `SurveyLocalDataSource.cacheSurveys`. This method itself just replaces
  /// rows as given.
  Future<void> replaceAllSurveys(List<SurveysTableCompanion> surveys) async {
    await transaction(() async {
      await delete(surveysTable).go();
      await batch((batch) => batch.insertAll(surveysTable, surveys));
    });
  }

  /// Upserts a single survey's full detail (sections/questions included) —
  /// used after downloading `GET /surveys/{id}`, which is the only endpoint
  /// that returns questions. Unlike [replaceAllSurveys], this never touches
  /// other rows, so downloading one survey's detail can't clobber another's.
  Future<void> upsertSurvey(SurveysTableCompanion survey) {
    return into(surveysTable).insertOnConflictUpdate(survey);
  }

  // ---------------------------------------------------------------------
  // Responses
  // ---------------------------------------------------------------------

  Stream<List<SurveyResponseRow>> watchResponsesForSurvey(String surveyId) {
    return (select(surveyResponsesTable)
          ..where((t) => t.surveyId.equals(surveyId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<SurveyResponseRow>> watchAllResponses() {
    return (select(surveyResponsesTable)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  /// Reactive view of "what the sync engine still owes the server" — used
  /// to drive the Sync Center list and the pending-count badge.
  Stream<List<SurveyResponseRow>> watchSyncableResponses() {
    return (select(surveyResponsesTable)
          ..where((t) => t.status.isIn(const ['pending', 'failed']))
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
        .watch();
  }

  /// One-off snapshot used by the sync engine when it actually processes
  /// the queue (a `Future`, not a `Stream`, so one sync pass works off a
  /// stable list even if the UI keeps emitting new states while it runs).
  Future<List<SurveyResponseRow>> getSyncableResponses() {
    return (select(surveyResponsesTable)..where((t) => t.status.isIn(const ['pending', 'failed']))).get();
  }

  Future<SurveyResponseRow?> getResponseByLocalId(String localId) {
    return (select(surveyResponsesTable)..where((t) => t.localId.equals(localId))).getSingleOrNull();
  }

  Future<void> upsertResponse(SurveyResponsesTableCompanion response) {
    return into(surveyResponsesTable).insertOnConflictUpdate(response);
  }

  Future<void> updateResponseStatus(
    String localId, {
    required String status,
    String? serverId,
    DateTime? syncedAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) {
    return (update(surveyResponsesTable)..where((t) => t.localId.equals(localId))).write(
      SurveyResponsesTableCompanion(
        status: Value(status),
        serverId: serverId == null ? const Value.absent() : Value(serverId),
        syncedAt: syncedAt == null ? const Value.absent() : Value(syncedAt),
        retryCount: retryCount == null ? const Value.absent() : Value(retryCount),
        lastError: lastError,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Narrow update used to attach GPS/app-version metadata without
  /// touching `answersJson` — see `SurveyRepository.attachDraftMetadata`.
  Future<void> updateResponseMetadata(
    String localId, {
    double? latitude,
    double? longitude,
    String? appVersion,
  }) {
    return (update(surveyResponsesTable)..where((t) => t.localId.equals(localId))).write(
      SurveyResponsesTableCompanion(
        latitude: latitude == null ? const Value.absent() : Value(latitude),
        longitude: longitude == null ? const Value.absent() : Value(longitude),
        appVersion: appVersion == null ? const Value.absent() : Value(appVersion),
      ),
    );
  }

  Future<void> deleteResponse(String localId) {
    return (delete(surveyResponsesTable)..where((t) => t.localId.equals(localId))).go();
  }
}

/// Single shared instance for the app's lifetime.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
