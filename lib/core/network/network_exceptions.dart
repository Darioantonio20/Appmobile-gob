import 'package:dio/dio.dart';

import '../utils/result.dart';

/// Maps a [DioException] (or any thrown error) to the app's [AppFailure]
/// vocabulary, so repositories never leak Dio types into the domain layer.
AppFailure mapNetworkError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return AppFailure.network();
      case DioExceptionType.badCertificate:
        return AppFailure.network('No se pudo verificar la conexión segura.');
      case DioExceptionType.cancel:
        return AppFailure.unknown('La solicitud fue cancelada.');
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          return AppFailure.unauthorized();
        }
        if (status != null && status >= 400 && status < 500) {
          final serverMessage = _extractServerMessage(error.response?.data);
          return AppFailure.validation(serverMessage);
        }
        return AppFailure.server();
      case DioExceptionType.unknown:
        return AppFailure.network();
    }
  }
  return AppFailure.unknown(null, error);
}

String? _extractServerMessage(Object? data) {
  if (data is Map && data['message'] is String) return data['message'] as String;
  if (data is Map && data['error'] is String) return data['error'] as String;
  return null;
}
