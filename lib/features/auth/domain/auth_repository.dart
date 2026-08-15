import '../../../core/utils/result.dart';
import 'user.dart';

/// Contract the presentation layer codes against. `data/auth_repository_impl.dart`
/// is the only place that knows about Dio/secure-storage.
abstract class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  Future<void> logout();

  /// Reads whatever session is cached on-device (no network call) — used at
  /// app startup to decide whether to show the login screen.
  Future<User?> restoreSession();
}
