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
    final message = await ref.read(authRepositoryProvider).logout();
    state = null;
    // The login screen consumes and clears this once (see its `ref.listen`)
    // — offline logout still succeeds locally, just without this message.
    if (message != null) ref.read(logoutMessageProvider.notifier).state = message;
  }
}

final authControllerProvider = NotifierProvider<AuthController, User?>(AuthController.new);

/// One-shot feedback from the last [AuthController.logout] that actually
/// reached the server — the login screen shows it once (a `SnackBar`, since
/// this is confirmation, not something the user needs to keep reading) and
/// clears it back to `null` right after, so it never reappears on a later
/// rebuild or hot restart.
final logoutMessageProvider = StateProvider<String?>((ref) => null);
