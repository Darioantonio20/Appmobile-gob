import '../../../core/utils/result.dart';
import 'user.dart';

/// Contract the presentation layer codes against. `data/auth_repository_impl.dart`
/// is the only place that knows about Dio/secure-storage.
abstract class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  /// Logs out locally regardless of outcome; returns the backend's own
  /// confirmation message (`"Sesión cerrada exitosamente."`) when the
  /// server-side revoke actually succeeded, or `null` when it was skipped
  /// (offline) or failed — logout itself never fails from the caller's
  /// point of view.
  Future<String?> logout();

  /// Reads whatever session is cached on-device (no network call) — used at
  /// app startup to decide whether to show the login screen.
  Future<User?> restoreSession();
}
