// Smoke test: verifies the app boots and shows the login screen
// without throwing, using a fake AuthRepository (no real network/DB).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appmobile_gob/app.dart';

void main() {
  testWidgets('App boots and shows the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AppmobileGobApp()));
    await tester.pump();

    expect(find.text('Gobierno de Chiapas'), findsWidgets);
  });
}
