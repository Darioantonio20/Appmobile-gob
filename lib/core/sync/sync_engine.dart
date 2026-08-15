import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_service.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

enum SyncEngineStatus { idle, syncing }

class SyncEngineState {
  const SyncEngineState({this.status = SyncEngineStatus.idle, this.lastSuccessAt, this.lastError});

  final SyncEngineStatus status;
  final DateTime? lastSuccessAt;
  final String? lastError;

  bool get isSyncing => status == SyncEngineStatus.syncing;
}

typedef SyncHandler = Future<void> Function();

/// Generic "when should we attempt a sync" orchestrator.
///
/// It reacts to the device coming back online, polls periodically as a
/// safety net (in case a reconnect event is missed), and exposes
/// [triggerNow] for pull-to-refresh / a manual "reintentar" button. It
/// deliberately knows nothing about *what* gets synced — that's plugged in
/// once via [registerHandler] from the composition root (`app.dart`) — so
/// this stays in `core/` and any future feature that needs background sync
/// can reuse it instead of rolling its own timer/connectivity plumbing.
class SyncEngineController extends Notifier<SyncEngineState> {
  Timer? _timer;
  SyncHandler? _handler;
  Future<void>? _inFlight;
  final _log = AppLogger.of('SyncEngine');

  @override
  SyncEngineState build() {
    ref.listen(isOnlineProvider, (previous, next) {
      if (previous == false && next == true) {
        _log.info('Conexión recuperada, intentando sincronizar…');
        triggerNow();
      }
    });

    _timer = Timer.periodic(AppConstants.syncPollInterval, (_) => triggerNow());
    ref.onDispose(() => _timer?.cancel());

    return const SyncEngineState();
  }

  void registerHandler(SyncHandler handler) => _handler = handler;

  /// Runs one sync pass if one isn't already running. Safe to call as often
  /// as you like (reconnect, timer, pull-to-refresh, manual retry) — calls
  /// that arrive while a pass is in flight just await that same pass.
  Future<void> triggerNow() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final handler = _handler;
    if (handler == null || !ref.read(isOnlineProvider)) return Future.value();

    state = SyncEngineState(status: SyncEngineStatus.syncing, lastSuccessAt: state.lastSuccessAt);

    final future = handler().then((_) {
      state = SyncEngineState(status: SyncEngineStatus.idle, lastSuccessAt: DateTime.now());
    }).catchError((Object e) {
      _log.error('Falló la sincronización', e);
      state = SyncEngineState(
        status: SyncEngineStatus.idle,
        lastSuccessAt: state.lastSuccessAt,
        lastError: e.toString(),
      );
    }).whenComplete(() => _inFlight = null);

    _inFlight = future;
    return future;
  }
}

final syncEngineProvider = NotifierProvider<SyncEngineController, SyncEngineState>(SyncEngineController.new);
