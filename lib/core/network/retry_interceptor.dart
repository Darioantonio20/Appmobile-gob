import 'package:dio/dio.dart';

import '../utils/app_logger.dart';

/// Retries a request a bounded number of times, with a short backoff, when
/// it fails for a *transient* reason: connection errors, timeouts, or a
/// 5xx from the server. Client errors (4xx) and 401 are never retried —
/// resending the exact same bad request won't fix it, and 401 has its own
/// handler in [DioClient].
///
/// This is a different, complementary safety net from the sync engine's
/// higher-level retry (`core/sync/sync_engine.dart`): this one recovers a
/// single flaky request within a couple of seconds; the sync engine
/// recovers "offline for hours" by re-queuing at the response level.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {this.maxAttempts = 2});

  final Dio _dio;
  final int maxAttempts;
  final _log = AppLogger.of('RetryInterceptor');

  static const _attemptKey = 'retryAttempt';

  bool _isRetryable(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        final status = error.response?.statusCode;
        return status != null && status >= 500;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (attempt >= maxAttempts || !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    final nextAttempt = attempt + 1;
    final delay = Duration(milliseconds: 400 * nextAttempt);
    _log.info('Reintentando ${err.requestOptions.uri} (intento $nextAttempt/$maxAttempts, en ${delay.inMilliseconds}ms)');
    await Future.delayed(delay);

    try {
      final options = err.requestOptions..extra[_attemptKey] = nextAttempt;
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (e) {
      handler.next(err);
    }
  }
}
