import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/surveys/presentation/screens/survey_detail_screen.dart';
import '../../features/surveys/presentation/screens/survey_fill_screen.dart';
import '../../features/surveys/presentation/screens/survey_list_screen.dart';
import '../../features/surveys/presentation/screens/survey_success_screen.dart';
import '../../features/sync/presentation/sync_center_screen.dart';
import 'route_paths.dart';

/// Router is exposed as a provider (instead of a top-level singleton) so it
/// can react to auth state: logging in/out rebuilds it, which re-runs
/// `redirect` and sends the user to the right place. Recreating the router
/// on auth changes is intentional — it also resets the navigation stack,
/// which is exactly what you want on login/logout.
final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authControllerProvider);
  final isLoggedIn = user != null;

  return GoRouter(
    initialLocation: RoutePaths.surveys,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == RoutePaths.login;
      if (!isLoggedIn && !isLoggingIn) return RoutePaths.login;
      if (isLoggedIn && isLoggingIn) return RoutePaths.surveys;
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        pageBuilder: (context, state) => _fadeThrough(state, const LoginScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.surveys,
                pageBuilder: (context, state) => _fadeThrough(state, const SurveyListScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.syncCenter,
                pageBuilder: (context, state) => _fadeThrough(state, const SyncCenterScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.surveyDetail,
        pageBuilder: (context, state) {
          final surveyId = state.pathParameters['surveyId']!;
          return _slideUp(state, SurveyDetailScreen(surveyId: surveyId));
        },
      ),
      GoRoute(
        path: RoutePaths.surveyFill,
        pageBuilder: (context, state) {
          final surveyId = state.pathParameters['surveyId']!;
          final responseLocalId = state.uri.queryParameters['responseLocalId'];
          return _slideUp(
            state,
            SurveyFillScreen(surveyId: surveyId, responseLocalId: responseLocalId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.surveySuccess,
        pageBuilder: (context, state) {
          final surveyId = state.pathParameters['surveyId']!;
          return _fadeThrough(state, SurveySuccessScreen(surveyId: surveyId));
        },
      ),
    ],
  );
});

/// Gentle cross-fade — used for top-level destinations (tabs, login).
CustomTransitionPage<void> _fadeThrough(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child);
    },
  );
}

/// Slide-up + fade — used for screens pushed on top of the shell (detail,
/// fill, success), signaling "you're going deeper" rather than "switching
/// section".
CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
