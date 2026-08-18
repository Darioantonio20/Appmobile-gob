import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Android/iOS/Windows/macOS/Linux: a real sqlite3 file via the bundled
/// native library (see [sqlite3_flutter_libs] in pubspec.yaml).
QueryExecutor openConnection() {
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
