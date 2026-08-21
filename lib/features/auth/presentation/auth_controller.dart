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
  /// Re-entrancy guard: [DioClient]'s `onUnauthorized` hook calls [logout]
  /// straight from a Dio error interceptor, so a burst of requests that all
  /// 401 at once (e.g. several in flight when a token goes stale) would
  /// otherwise fire several concurrent, redundant logout attempts. Combined
  /// with excluding `/logout`'s own 401 in [DioClient] (see its comment),
  /// this is what actually stops that from compounding into an infinite
  /// loop — confirmed live as hundreds of `POST /logout` calls per second,
  /// with login never even reachable.
  bool _loggingOut = false;

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
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      final message = await ref.read(authRepositoryProvider).logout();
      state = null;
      // The login screen consumes and clears this once (see its `ref.listen`)
      // — offline logout still succeeds locally, just without this message.
      if (message != null) ref.read(logoutMessageProvider.notifier).state = message;
    } finally {
      _loggingOut = false;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, User?>(AuthController.new);

/// One-shot feedback from the last [AuthController.logout] that actually
/// reached the server — the login screen shows it once (a `SnackBar`, since
/// this is confirmation, not something the user needs to keep reading) and
/// clears it back to `null` right after, so it never reappears on a later
/// rebuild or hot restart.
final logoutMessageProvider = StateProvider<String?>((ref) => null);
