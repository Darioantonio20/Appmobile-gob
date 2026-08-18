// Source for web/drift_worker.dart.js — NOT part of the app itself. Compile
// with:
//   dart compile js -O2 -o web/drift_worker.dart.js tool/drift_web_worker.dart
// Re-run that whenever the `drift` package version changes. See
// lib/core/database/connection/connection_web.dart for where the compiled
// output is loaded from.
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
