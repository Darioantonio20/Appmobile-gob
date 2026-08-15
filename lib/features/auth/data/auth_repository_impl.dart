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
  Future<void> logout() => _local.clear();

  @override
  Future<User?> restoreSession() => _local.readUser();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});
