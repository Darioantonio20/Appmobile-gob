/// Global, environment-level constants.
///
/// `apiBaseUrl` is read from `--dart-define=API_BASE_URL=...` so the same
/// build can point at dev/staging/prod without touching code:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api
/// ```
///
/// The default below points at the real production backend
/// (`encuestas.sesaech.gob.mx`) — confirmed reachable (a bare `GET
/// /api/surveys` correctly returns 401 Unauthenticated without a token). Use
/// `--dart-define` to point at a local Laravel dev server instead (your PC's
/// LAN IP, e.g. `192.168.x.x:8000` — never `localhost`, which on a physical
/// device resolves to the device itself, not your PC) when developing
/// against a backend that isn't deployed yet. Nothing else in the app needs
/// to change either way, because every network call goes through
/// [ApiEndpoints] / [DioClient].
class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://encuestas.sesaech.gob.mx/api',
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
