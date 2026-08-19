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

  // TEMPORAL (dev): todavía no hay backend real conectado. Usuario de
  // prueba fijo (no "acepta cualquier cosa") para poder probar el flujo
  // completo sin servidor. Poner en `false` (o borrar este bloque) en
  // cuanto haya API real.
  static const bool _mockLogin = true;
  static const String mockEmail = 'encuestador@demo.mx';
  static const String mockPassword = 'Demo1234';

  Future<({String token, User user})> login({
    required String email,
    required String password,
  }) async {
    if (_mockLogin) {
      await Future.delayed(const Duration(milliseconds: 400));
      final matches = email.trim().toLowerCase() == mockEmail && password == mockPassword;
      if (!matches) {
        throw DioException(
          requestOptions: RequestOptions(path: ApiEndpoints.login),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiEndpoints.login),
            statusCode: 422,
            data: {'message': 'Correo o contraseña incorrectos.'},
          ),
        );
      }
      return (
        token: 'mock-token-dev',
        user: const User(id: '1', name: 'Encuestador Demo', email: mockEmail),
      );
    }
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
