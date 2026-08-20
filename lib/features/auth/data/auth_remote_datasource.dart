import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/utils/device_name.dart';
import '../domain/user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio, this._ref);

  final Dio _dio;
  final Ref _ref;

  Future<({String token, User user})> login({
    required String email,
    required String password,
  }) async {
    final deviceName = await _ref.read(deviceNameProvider.future);
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password, 'device_name': deviceName},
    );
    final data = response.data ?? const {};
    final token = data['token'] as String? ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? const {};
    return (token: token, user: User.fromJson(userJson));
  }

  /// Revokes the current token server-side. Best-effort from the caller's
  /// side (see [AuthRepositoryImpl.logout]) — local session clearing never
  /// waits on this succeeding, since the user should always be able to log
  /// out locally even offline.
  Future<void> logout() => _dio.post<void>(ApiEndpoints.logout);
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider), ref);
});
