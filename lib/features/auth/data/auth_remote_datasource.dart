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
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider), ref);
});
