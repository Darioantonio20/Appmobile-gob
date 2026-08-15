import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams whether the device currently has a network interface up
/// (wifi/mobile/ethernet). This is a signal to *attempt* a sync, not a
/// guarantee the backend is reachable — a captive portal or a flaky tower
/// can still report "connected" with no real internet. That's fine here:
/// the sync engine's actual HTTP calls are the source of truth, and any
/// item that fails to upload simply stays `pending` for the next trigger
/// (reconnect, app resume, or manual retry), so a false positive here never
/// loses data — it just costs one failed request.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) async* {
  final connectivity = Connectivity();
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

/// Simple `true`/`false` view of [connectivityStreamProvider], defaulting to
/// `true` while the first check is still in flight so the UI doesn't flash
/// an "offline" banner on cold start.
final isOnlineProvider = Provider<bool>((ref) {
  final result = ref.watch(connectivityStreamProvider);
  return result.when(
    data: (results) => !results.contains(ConnectivityResult.none),
    loading: () => true,
    error: (_, __) => true,
  );
});
