// Layout regression test for [SurveyCard]. This app clamps OS text scaling
// to a 1.4x ceiling (see `lib/app.dart`) precisely because the audience
// skews older and turns text size up — and this project has already shipped
// a real overflow at that ceiling before (three dropdowns crammed into one
// Row; see the flutter-ui-review skill). The card's header row, its
// metadata + progress row and its action button all pack several
// variable-width things side by side, so they're exactly the shape that
// breaks. A `RenderFlex overflowed` failure surfaces as a thrown exception
// in tests, which is what these assertions catch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appmobile_gob/features/surveys/domain/survey.dart';
import 'package:appmobile_gob/features/surveys/presentation/widgets/survey_card.dart';

Survey _survey() => Survey(
      id: '2',
      // Deliberately long: a short title would never exercise the wrap.
      title: 'Conocimiento de programación de sistemas empresariales y gubernamentales',
      description: 'Encuesta para evaluar el conocimiento de programación de sistemas empresariales del personal.',
      sections: [
        SurveySection(
          id: '4',
          title: 'Básico',
          questions: [
            const SurveyQuestion(id: '20', type: QuestionType.shortText, text: 'Pregunta uno'),
            const SurveyQuestion(id: '21', type: QuestionType.shortText, text: 'Pregunta dos'),
          ],
        ),
        SurveySection(
          id: '5',
          title: 'Avanzado',
          questions: [
            const SurveyQuestion(id: '22', type: QuestionType.shortText, text: 'Pregunta tres'),
          ],
        ),
      ],
    );

Future<void> _pumpCard(WidgetTester tester, {required double textScale, required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SurveyCard(survey: _survey(), onTap: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('SurveyCard lays out without overflow on a narrow phone', (tester) async {
    await _pumpCard(tester, textScale: 1.0, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('Iniciar encuesta'), findsOneWidget);
    // The status pill's leading icon was dropped by design — the label
    // stands alone now.
    expect(find.text('Asignada'), findsOneWidget);
  });

  testWidgets('SurveyCard lays out without overflow at the app\'s 1.4x text-scale ceiling', (tester) async {
    await _pumpCard(tester, textScale: 1.4, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SurveyCard lays out without overflow on a tablet width', (tester) async {
    await _pumpCard(tester, textScale: 1.4, size: const Size(834, 1112));
    expect(tester.takeException(), isNull);
  });
}
