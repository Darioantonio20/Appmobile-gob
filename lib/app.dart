import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/app_theme.dart';
import 'features/surveys/data/survey_repository_impl.dart';

class AppmobileGobApp extends ConsumerStatefulWidget {
  const AppmobileGobApp({super.key});

  @override
  ConsumerState<AppmobileGobApp> createState() => _AppmobileGobAppState();
}

class _AppmobileGobAppState extends ConsumerState<AppmobileGobApp> {
  @override
  void initState() {
    super.initState();
    // Composition root wiring: tell the generic sync engine what "do a sync
    // pass" means for this app. One-time; see core/sync/sync_engine.dart.
    ref.read(syncEngineProvider.notifier).registerHandler(
          () => ref.read(surveyRepositoryProvider).syncPendingResponses(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        // Honor the device's font-scaling setting (real accessibility need
        // for this audience) but clamp the top end so an extreme OS setting
        // can't break a layout — text still ends up noticeably larger than
        // default, just never broken. The floor is 1.0 rather than the
        // system's: this app's base sizes are already tuned for older
        // readers, so we don't want a smaller-than-default OS preference
        // undercutting that baseline.
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.4);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child!,
        );
      },
    );
  }
}
