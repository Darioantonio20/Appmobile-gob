import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_local_datasource.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'network/dio_client.dart';

/// Composition root for providers that necessarily cross feature
/// boundaries. `core/` and `features/*` otherwise never import each other
/// sideways (features depend on core, not the reverse) — this file is the
/// single, explicit exception, so that coupling stays easy to find instead
/// of scattered.
///
/// Concretely: the network client needs to read the auth token and react to
/// 401s by logging out, which means it needs to know about the auth
/// feature. That wiring lives here instead of inside `core/network/`.
final dioProvider = Provider<Dio>((ref) {
  final client = DioClient(
    tokenProvider: () => ref.read(authLocalDataSourceProvider).readToken(),
    onUnauthorized: () => ref.read(authControllerProvider.notifier).logout(),
  );
  return client.dio;
});
