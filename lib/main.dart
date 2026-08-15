import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');

  final container = ProviderContainer();

  // Restore any session cached on-device *before* the first frame, so the
  // router's very first redirect decision is already correct — no flash of
  // the login screen for a user who's already signed in.
  await container.read(authControllerProvider.notifier).bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AppmobileGobApp(),
    ),
  );
}
