import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

/// Locally-cached surveys, as last fetched from the backend.
///
/// Questions are stored as a JSON blob ([questionsJson]) rather than a
/// normalized child table: a survey's question list is always read/written
/// as one unit (never queried question-by-question), so normalizing it
/// would only add join complexity for no benefit. The JSON is decoded into
/// typed [SurveyQuestion] objects at the repository boundary — nothing
/// above `data/` ever touches raw JSON.
@DataClassName('SurveyRow')
class SurveysTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get questionsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

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

  @override
  Set<Column> get primaryKey => {localId};
}

@DriftDatabase(tables: [SurveysTable, SurveyResponsesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Lets tests (or a future desktop-only tool) inject an in-memory
  /// connection instead of opening a real file.
  AppDatabase.withConnection(super.connection);

  @override
  int get schemaVersion => 1;

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

  /// The survey list endpoint returns the full authoritative set on every
  /// fetch, so we replace the whole local cache in one transaction rather
  /// than trying to diff it. This is safe because user data (answers)
  /// lives in [SurveyResponsesTable], never here.
  Future<void> replaceAllSurveys(List<SurveysTableCompanion> surveys) async {
    await transaction(() async {
      await delete(surveysTable).go();
      await batch((batch) => batch.insertAll(surveysTable, surveys));
    });
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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Ensures the bundled sqlite3 native library is used consistently
    // across Android/iOS/desktop instead of relying on the OS's version.
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'appmobile_gob.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
