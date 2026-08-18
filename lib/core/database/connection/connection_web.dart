import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web: sqlite3 compiled to WebAssembly, run in a worker. Requires two
/// files to exist under `web/` (see the drift_worker build step and
/// scripts/README) — `sqlite3.wasm` and `drift_worker.dart.js`. Drift picks
/// the best available storage the browser supports (OPFS > IndexedDB >
/// in-memory) on its own; see [WasmDatabase.open].
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'appmobile_gob',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return result.resolvedExecutor;
  });
}
