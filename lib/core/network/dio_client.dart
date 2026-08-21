import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'api_endpoints.dart';
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
            // Accept is required by Laravel to actually return JSON error
            // bodies (401/422/etc.) instead of an HTML error page — without
            // it, `network_exceptions.dart`'s `message` extraction has
            // nothing to read.
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
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
          // Guard against a real, previously-reproduced infinite loop: a
          // stale/invalid stored token means *every* request 401s,
          // including `POST /logout` itself once `onUnauthorized` fires and
          // calls it — and that 401 would otherwise re-trigger
          // `onUnauthorized` again, which calls logout again, forever
          // (confirmed live: hundreds of `POST /logout` calls per second,
          // login never even reachable). Logout's own failure is never a
          // reason to log out again — it's already happening — so its 401
          // is excluded here.
          final isLogoutRequest = error.requestOptions.path == ApiEndpoints.logout;
          if (error.response?.statusCode == 401 && !isLogoutRequest) {
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
            // The response body (when there is one) is what actually says
            // *why* — `error.message` alone is just Dio's generic "bad
            // status code" description, e.g. useless for a 422's per-field
            // validation errors.
            final body = error.response?.data;
            log.warning('✗ ${error.requestOptions.uri}', body != null ? '${error.message}\nBody: $body' : error.message);
            handler.next(error);
          },
        ),
      );
    }
  }

  final Dio dio;
}
