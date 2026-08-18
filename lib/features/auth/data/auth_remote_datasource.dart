import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../domain/user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  // TEMPORAL (dev): todavía no hay backend real conectado (ver README).
  // Usuario de prueba fijo (no "acepta cualquier cosa") para poder probar el
  // flujo completo: entrar, llenar encuestas, y ver el envío fallar sin
  // conexión y reintentarse solo al recuperarla. Poner en `false` (o borrar
  // este bloque) en cuanto haya API real.
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
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data ?? const {};
    final token = data['token'] as String? ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? const {};
    return (token: token, user: User.fromJson(userJson));
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});
