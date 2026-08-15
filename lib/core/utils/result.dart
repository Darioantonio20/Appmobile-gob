import 'package:flutter/foundation.dart';

/// A typed success/failure wrapper used at every layer boundary (datasource
/// → repository → controller) instead of throwing raw exceptions through the
/// UI. Keeps error handling explicit and forces call sites to think about
/// the failure path.
@immutable
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppFailure failure) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Failure<T>) return failure(self.failure);
    throw StateError('Unreachable');
  }

  /// Returns the success value, or `null` when this is a [Failure].
  T? get dataOrNull {
    final self = this;
    return self is Success<T> ? self.data : null;
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;
}

/// Cause of a failure, so the UI can decide how to react (e.g. show an
/// "offline" banner vs. a generic error) without parsing message strings.
enum FailureType {
  network,
  server,
  cache,
  unauthorized,
  validation,
  unknown,
}

@immutable
class AppFailure {
  const AppFailure(this.type, this.message, {this.cause});

  final FailureType type;
  final String message;
  final Object? cause;

  factory AppFailure.network([String? message]) =>
      AppFailure(FailureType.network, message ?? 'Sin conexión a internet.');

  factory AppFailure.server([String? message]) =>
      AppFailure(FailureType.server, message ?? 'Ocurrió un error en el servidor.');

  factory AppFailure.cache([String? message]) =>
      AppFailure(FailureType.cache, message ?? 'No se pudo leer la información guardada.');

  factory AppFailure.unauthorized([String? message]) =>
      AppFailure(FailureType.unauthorized, message ?? 'Tu sesión expiró. Vuelve a iniciar sesión.');

  factory AppFailure.validation([String? message]) =>
      AppFailure(FailureType.validation, message ?? 'Revisa la información ingresada.');

  factory AppFailure.unknown([String? message, Object? cause]) =>
      AppFailure(FailureType.unknown, message ?? 'Ocurrió un error inesperado.', cause: cause);

  @override
  String toString() => 'AppFailure(type: $type, message: $message)';
}
