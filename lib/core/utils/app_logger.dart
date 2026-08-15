import 'package:flutter/foundation.dart';

/// Minimal, dependency-free logger. Centralizing this here (instead of
/// scattering `debugPrint` calls) means there's exactly one place to plug in
/// a crash/analytics reporter later.
class AppLogger {
  AppLogger(this._tag);

  final String _tag;

  static AppLogger of(String tag) => AppLogger(tag);

  void info(String message) => _log('INFO', message);

  void warning(String message, [Object? error]) => _log('WARN', message, error);

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error);
    if (stackTrace != null && kDebugMode) debugPrint(stackTrace.toString());
  }

  void _log(String level, String message, [Object? error]) {
    if (!kDebugMode && level == 'INFO') return;
    final suffix = error != null ? ' — $error' : '';
    debugPrint('[$level] $_tag: $message$suffix');
  }
}
