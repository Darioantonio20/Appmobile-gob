// Smoke test: verifies the app boots and shows the login screen
// without throwing, using a fake AuthRepository (no real network/DB).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appmobile_gob/app.dart';

void main() {
  testWidgets('App boots and shows the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AppmobileGobApp()));
    // pumpAndSettle, not a single pump: the login screen's entrance uses
    // StaggeredFadeSlideIn, which schedules its own delayed Timers — a bare
    // pump() leaves those pending and flutter test fails on "pending
    // timers" even though the app itself is fine.
    await tester.pumpAndSettle();

    expect(find.text('Sistema de Encuestas Ciudadanas'), findsWidgets);
  });
}
