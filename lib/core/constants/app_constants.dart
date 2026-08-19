/// Global, environment-level constants.
///
/// `apiBaseUrl` is read from `--dart-define=API_BASE_URL=...` so the same
/// build can point at dev/staging/prod without touching code:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://encuestas.chiapas.gob.mx/api
/// ```
///
/// The default below points at the Laravel dev backend on `localhost:8000`
/// — via `10.0.2.2`, the Android emulator's alias for the host machine's
/// `localhost` (a physical device or a real deployment needs an actual
/// reachable URL, passed via --dart-define as above). Swap this default
/// once there's a real staging/prod URL — nothing else in the app needs to
/// change either way, because every network call goes through
/// [ApiEndpoints] / [DioClient].
class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// How often the sync engine retries the pending-response queue while the
  /// app is open and online (in addition to reacting to connectivity
  /// changes and manual "retry" taps).
  static const Duration syncPollInterval = Duration(minutes: 2);

  static const int maxSyncRetries = 5;

  // Secure storage keys.
  static const String secureKeyAuthToken = 'auth_token';
  static const String secureKeyUserJson = 'auth_user';

  static const String appName = 'Encuestas Chiapas';
}
