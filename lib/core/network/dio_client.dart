import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'retry_interceptor.dart';

/// Called by the auth interceptor to attach the current token, if any.
/// Injected from outside (see `core/providers.dart`) so `core/` never
/// depends on `features/auth` directly.
typedef TokenProvider = Future<String?> Function();

/// Called when the backend reports the token is no longer valid (401),
/// so the app can drop the session and route back to login.
typedef UnauthorizedHandler = void Function();

/// Thin factory around [Dio] with the interceptors every request needs:
/// bearer-token injection, debug logging, and a hook for 401 handling.
class DioClient {
  DioClient({
    required TokenProvider tokenProvider,
    UnauthorizedHandler? onUnauthorized,
    String? baseUrl,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    dio.interceptors.add(RetryInterceptor(dio));

    if (kDebugMode) {
      final log = AppLogger.of('DioClient');
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            log.info('→ ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            log.info('← ${response.statusCode} ${response.requestOptions.uri}');
            handler.next(response);
          },
          onError: (error, handler) {
            log.warning('✗ ${error.requestOptions.uri}', error.message);
            handler.next(error);
          },
        ),
      );
    }
  }

  final Dio dio;
}
