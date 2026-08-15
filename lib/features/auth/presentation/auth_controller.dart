import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../data/auth_repository_impl.dart';
import '../domain/user.dart';

/// Current session, `null` when logged out. This is what [appRouterProvider]
/// watches to decide whether to show the login screen — logging in/out
/// rebuilds the router and resets the navigation stack.
///
/// [bootstrap] is awaited in `main.dart` *before* `runApp`, so by the time
/// the widget tree first builds, this already reflects any session restored
/// from secure storage — no splash/loading state needed here.
class AuthController extends Notifier<User?> {
  @override
  User? build() => null;

  Future<void> bootstrap() async {
    state = await ref.read(authRepositoryProvider).restoreSession();
  }

  Future<Result<User>> login({required String email, required String password}) async {
    final result = await ref.read(authRepositoryProvider).login(email: email, password: password);
    if (result case Success(data: final user)) {
      state = user;
    }
    return result;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final authControllerProvider = NotifierProvider<AuthController, User?>(AuthController.new);
