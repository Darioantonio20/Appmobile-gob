// Platform-conditional database connection opener.
//
// `dart:ffi` (used by the native sqlite3 bindings) simply doesn't compile
// for web — that's a compile-time incompatibility, not a runtime one, so a
// single file with a runtime `if (kIsWeb)` branch can't work here: any file
// that so much as imports `dart:ffi`/`package:drift/native.dart` fails to
// build for web regardless of whether that branch ever runs. Conditional
// imports are the actual fix: the compiler picks the right file for the
// target platform before either implementation's imports are even
// considered.
export 'connection_native.dart' if (dart.library.js_interop) 'connection_web.dart';
