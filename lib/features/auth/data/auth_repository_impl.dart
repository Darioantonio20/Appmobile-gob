import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_exceptions.dart';
import '../../../core/utils/result.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'auth_local_datasource.dart';
import 'auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Result<User>> login({required String email, required String password}) async {
    try {
      final session = await _remote.login(email: email, password: password);
      if (session.token.isEmpty) {
        return Result.failure(AppFailure.server('El servidor no devolvió una sesión válida.'));
      }
      await _local.saveSession(token: session.token, user: session.user);
      return Result.success(session.user);
    } catch (e) {
      return Result.failure(mapNetworkError(e));
    }
  }

  @override
  Future<String?> logout() async {
    // Best-effort: revoke the token server-side, but never block a local
    // logout on it succeeding — the user can always log out offline, and a
    // token that couldn't be revoked (no connection, already expired, ...)
    // just ages out on its own.
    String? message;
    try {
      message = await _remote.logout();
    } catch (_) {
      // Ignored on purpose — see above.
    }
    await _local.clear();
    return message;
  }

  @override
  Future<User?> restoreSession() => _local.readUser();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});
