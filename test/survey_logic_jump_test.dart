// Regression test for the skip-logic bug reported against a real
// `GET /api/surveys/2` response: question 25 ("¿Quieres ir al cine
// conmigo?") jumps to question 26 or 27 depending on the answer — both
// sitting in the *same* section, right after it. Before this fix,
// [SurveyFillReady.currentQuestions] rendered every question in a section
// unconditionally, so both follow-ups showed at once regardless of
// `logic_jumps`. This payload is trimmed to the fields that matter, but the
// shape (ids, types, options, jumps) is copied verbatim from the real
// response.
import 'package:flutter_test/flutter_test.dart';

import 'package:appmobile_gob/features/surveys/domain/survey.dart';

Map<String, dynamic> _question({
  required int id,
  required String type,
  required String text,
  List<Map<String, dynamic>> options = const [],
  List<Map<String, dynamic>> logicJumps = const [],
  List<Map<String, dynamic>> subQuestions = const [],
  int? minLength,
}) =>
    {
      'question_id': id,
      'parent_id': null,
      'type': type,
      'question_text': text,
      'is_required': false,
      'order': id,
      'min_length': minLength,
      'max_length': null,
      'min_value': null,
      'max_value': null,
      'max_decimals': null,
      'requires_text': false,
      'options': options,
      'logic_jumps': logicJumps,
      'sub_questions': subQuestions,
    };

Map<String, dynamic> _option(int id, String label, {bool isCorrect = false}) => {
      'option_id': id,
      'label': label,
      'is_correct': isCorrect,
      'weight': id,
      'requires_text': false,
      'text_placeholder': null,
    };

final _surveyJson = {
  'survey_id': 2,
  'title': 'Conocimiento de programación de sistemas',
  'sections': [
    {
      'section_id': 4,
      'title': 'Básico',
      'order': 1,
      'questions': [
        _question(id: 20, type: 'TR-03', text: '¿Cuál es un paradigma?', options: [_option(39, 'Funcional')]),
        _question(id: 21, type: 'TR-07', text: 'Nueva Pregunta2', options: [_option(42, 'A'), _option(43, 'B')]),
        _question(id: 22, type: 'TR-04', text: 'Nueva Preguntadd', options: [_option(46, 'Sí')]),
        _question(id: 24, type: 'TR-03', text: '¿Qué es DI?', options: [_option(49, 'Paradigma')]),
        _question(
          id: 25,
          type: 'TR-04',
          text: '¿Quieres ir al cine conmigo?',
          options: [_option(53, 'Sí'), _option(54, 'No')],
          logicJumps: [
            {'condition_option_id': 53, 'target_question_id': 26, 'description': 'Sí -> 26'},
            {'condition_option_id': 54, 'target_question_id': 27, 'description': 'No -> 27'},
          ],
        ),
        _question(id: 26, type: 'TR-07', text: '¿Qué película vemos?', options: [_option(55, 'A')]),
        _question(id: 27, type: 'TR-01', text: '¿Por qué no quieres ir?', minLength: 5),
        _question(
          id: 28,
          type: 'TR-08',
          text: 'Pregunta matriz',
          options: [_option(58, 'Opción'), _option(59, 'Opción2')],
          subQuestions: [_question(id: 29, type: 'TR-06', text: 'Subpregunta')],
        ),
      ],
    },
  ],
};

void main() {
  final survey = Survey.fromJson(_surveyJson);

  test('TR codes infer the structurally-correct QuestionType', () {
    final byId = {for (final q in survey.allQuestions) q.id: q};
    expect(byId['21']!.type, QuestionType.singleChoice); // TR-07 w/ options
    expect(byId['27']!.type, QuestionType.longText); // TR-01, no options, min_length set
    expect(byId['28']!.type, QuestionType.likertMatrix); // TR-08
  });

  test('before question 25 is answered, neither branch target shows (both are gated)', () {
    final reachable = survey.reachableQuestionIds(const {});
    expect(reachable, containsAllInOrder(['20', '21', '22', '24', '25', '28']));
    expect(reachable, isNot(contains('26')));
    expect(reachable, isNot(contains('27')));
  });

  test('answering "Sí" (53) jumps to 26 and excludes 27', () {
    final reachable = survey.reachableQuestionIds({'25': '53'});
    expect(reachable, containsAllInOrder(['25', '26', '28']));
    expect(reachable, isNot(contains('27')));
  });

  test('answering "No" (54) jumps to 27 and excludes 26', () {
    final reachable = survey.reachableQuestionIds({'25': '54'});
    expect(reachable, containsAllInOrder(['25', '27', '28']));
    expect(reachable, isNot(contains('26')));
  });
}
