import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../domain/survey.dart';
import '../domain/survey_response.dart';

class SurveyRemoteDataSource {
  SurveyRemoteDataSource(this._dio);

  final Dio _dio;

  // TEMPORAL (dev): no real backend yet.
  // - fetchSurveys()/fetchSurvey() return 3 fixed sample surveys, no
  //   network — matches the *real* contract shape (question_id/type/TR-codes/
  //   etc. — see domain/survey.dart's doc comments) so switching this to
  //   `false` once the backend is reachable is the only change needed.
  // - submitResponse() genuinely posts over the network too, but to a real,
  //   free public test endpoint (jsonplaceholder) instead of simulating
  //   success in memory — that's what makes "fails without a connection,
  //   sends once it's back" actually testable against real connectivity
  //   instead of a fake in-app toggle. Swap the real endpoint back in
  //   (see below) once the real contract is confirmed.
  static const bool _mockSurveys = true;
  static const String _testSubmitUrl = 'https://jsonplaceholder.typicode.com/posts';

  static final List<Survey> _sampleSurveys = [
    Survey.fromJson({
      'survey_id': 'demo-001',
      'title': 'Satisfacción con servicios públicos',
      'description': 'Encuesta de ejemplo (datos locales, sin backend real todavía).',
      'sections': [
        {
          'section_id': 's1',
          'title': 'Datos generales',
          'order': 1,
          'questions': [
            {
              'question_id': 'q1',
              'type': 'TR-02',
              'question_text': '¿Cuál es tu nombre?',
              'is_required': true,
              'order': 1,
              'max_length': 100,
            },
            {
              'question_id': 'q2',
              'type': 'TR-04',
              'question_text': '¿En qué municipio vives?',
              'is_required': true,
              'order': 2,
              'options': [
                {'option_id': 'tuxtla', 'label': 'Tuxtla Gutiérrez'},
                {'option_id': 'sc', 'label': 'San Cristóbal de las Casas'},
                {'option_id': 'tapachula', 'label': 'Tapachula'},
                {'option_id': 'otro', 'label': 'Otro', 'requires_text': true},
              ],
            },
          ],
        },
        {
          'section_id': 's2',
          'title': 'Tu experiencia',
          'order': 2,
          'questions': [
            {
              'question_id': 'q3',
              'type': 'TR-05',
              'question_text': '¿Qué tan satisfecho estás con el servicio recibido? (1 a 5)',
              'is_required': true,
              'order': 1,
              'min_value': 1,
              'max_value': 5,
              'max_decimals': 0,
            },
            {
              'question_id': 'q4',
              'type': 'TR-03',
              'question_text': '¿Recomendarías este servicio a alguien más?',
              'is_required': true,
              'order': 2,
              'options': [
                {'option_id': 'si', 'label': 'Sí'},
                {'option_id': 'no', 'label': 'No'},
              ],
            },
            {
              'question_id': 'q5',
              'type': 'TR-02',
              'question_text': '¿Algo que quieras comentar?',
              'is_required': false,
              'order': 3,
              'max_length': 500,
            },
          ],
        },
      ],
    }),
    Survey.fromJson({
      'survey_id': 'demo-002',
      'title': 'Acceso a agua potable',
      'description': 'Encuesta de ejemplo (datos locales, sin backend real todavía).',
      'sections': [
        {
          'section_id': 's1',
          'title': 'Datos del hogar',
          'order': 1,
          'questions': [
            {
              'question_id': 'q1',
              'type': 'TR-05',
              'question_text': '¿Cuántas personas viven en tu hogar?',
              'is_required': true,
              'order': 1,
              'min_value': 1,
              'max_value': 20,
              'max_decimals': 0,
            },
            {
              'question_id': 'q2',
              'type': 'TR-03',
              'question_text': '¿Tu vivienda cuenta con toma de agua potable?',
              'is_required': true,
              'order': 2,
              'options': [
                {'option_id': 'si', 'label': 'Sí'},
                {'option_id': 'no', 'label': 'No'},
              ],
            },
          ],
        },
        {
          'section_id': 's2',
          'title': 'Frecuencia y calidad',
          'order': 2,
          'questions': [
            {
              'question_id': 'q3',
              'type': 'TR-04',
              'question_text': '¿Con qué frecuencia tienes agua?',
              'is_required': true,
              'order': 1,
              'options': [
                {'option_id': 'diario', 'label': 'Diario'},
                {'option_id': 'alternos', 'label': 'Días alternos'},
                {'option_id': 'semanal', 'label': '1-2 veces por semana'},
              ],
            },
            {
              'question_id': 'q4',
              'type': 'TR-05',
              'question_text': '¿Cómo calificarías la calidad del agua? (1 a 5)',
              'is_required': true,
              'order': 2,
              'min_value': 1,
              'max_value': 5,
              'max_decimals': 0,
            },
            {
              'question_id': 'q5',
              'type': 'TR-02',
              'question_text': 'Comentarios adicionales',
              'is_required': false,
              'order': 3,
              'max_length': 500,
            },
          ],
        },
      ],
    }),
    Survey.fromJson({
      'survey_id': 'demo-003',
      'title': 'Percepción de seguridad en tu colonia',
      'description': 'Encuesta de ejemplo (datos locales, sin backend real todavía).',
      'sections': [
        {
          'section_id': 's1',
          'title': 'Percepción general',
          'order': 1,
          'questions': [
            {
              'question_id': 'q1',
              'type': 'TR-05',
              'question_text': '¿Qué tan seguro te sientes en tu colonia? (1 a 5)',
              'is_required': true,
              'order': 1,
              'min_value': 1,
              'max_value': 5,
              'max_decimals': 0,
            },
            {
              'question_id': 'q2',
              'type': 'TR-03',
              'question_text': '¿Has sido víctima de algún delito en el último año?',
              'is_required': true,
              'order': 2,
              'options': [
                {'option_id': 'si', 'label': 'Sí'},
                {'option_id': 'no', 'label': 'No'},
              ],
            },
          ],
        },
        {
          'section_id': 's2',
          'title': 'Evaluación de servicios',
          'order': 2,
          'questions': [
            {
              'question_id': 'q3',
              'type': 'TR-08',
              'question_text': 'Califica cada servicio',
              'is_required': true,
              'order': 1,
              'options': [
                {'option_id': '1', 'label': 'Muy malo'},
                {'option_id': '2', 'label': 'Malo'},
                {'option_id': '3', 'label': 'Regular'},
                {'option_id': '4', 'label': 'Bueno'},
                {'option_id': '5', 'label': 'Muy bueno'},
              ],
              'sub_questions': [
                {'question_id': 'r1', 'question_text': 'Alumbrado público', 'parent_id': 'q3'},
                {'question_id': 'r2', 'question_text': 'Patrullaje policiaco', 'parent_id': 'q3'},
                {'question_id': 'r3', 'question_text': 'Tiempo de respuesta a emergencias', 'parent_id': 'q3'},
              ],
            },
            {
              'question_id': 'q4',
              'type': 'TR-02',
              'question_text': 'Comentarios',
              'is_required': false,
              'order': 2,
              'max_length': 500,
            },
          ],
        },
      ],
    }),
  ];

  Future<List<Survey>> fetchSurveys() async {
    if (_mockSurveys) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _sampleSurveys;
    }
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.surveys);
    final data = response.data ?? const [];
    return data.map((e) => Survey.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Survey> fetchSurvey(String id) async {
    if (_mockSurveys) {
      await Future.delayed(const Duration(milliseconds: 150));
      return _sampleSurveys.firstWhere((s) => s.id == id, orElse: () => _sampleSurveys.first);
    }
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.survey(id));
    return Survey.fromJson(response.data ?? const {});
  }

  /// Submits one filled-in response. Sends [SurveyResponse.localId] both in
  /// the body (as `folio`) and as an `Idempotency-Key` header, so a retried
  /// send (e.g. a request that succeeded server-side but timed out on the
  /// way back) doesn't create a duplicate — as long as the backend honors
  /// the header, which is a standard, low-effort thing to ask for on its
  /// end.
  ///
  /// Unlike login/list/detail, this endpoint's exact shape hasn't been
  /// confirmed against the real backend yet — [ApiEndpoints.submitResponse]
  /// is a reasonable placeholder path, and the body below is this app's
  /// best guess at what the backend needs. Confirm both once that contract
  /// is available; nothing outside this method needs to change either way.
  Future<String?> submitResponse(SurveyResponse response) async {
    final body = {
      'folio': response.folio,
      'answers': response.answers,
      'surveyor_id': response.surveyorId,
      'surveyor_name': response.surveyorName,
      'started_at': response.startedAt?.toIso8601String(),
      'submitted_at': (response.submittedAt ?? DateTime.now()).toIso8601String(),
      'location': response.hasLocation ? {'lat': response.latitude, 'lng': response.longitude} : null,
      'app_version': response.appVersion,
    };
    if (_mockSurveys) {
      // Absolute URL on purpose — Dio uses it as-is and ignores baseUrl, so
      // this is a real request over the real network regardless of the
      // placeholder backend configured in ApiEndpoints/AppConstants.
      final testResult = await _dio.post<Map<String, dynamic>>(_testSubmitUrl, data: body);
      return testResult.data?['id']?.toString();
    }
    final result = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.submitResponse(response.surveyId),
      data: body,
      options: Options(headers: {'Idempotency-Key': response.localId}),
    );
    return result.data?['id']?.toString();
  }
}

final surveyRemoteDataSourceProvider = Provider<SurveyRemoteDataSource>((ref) {
  return SurveyRemoteDataSource(ref.watch(dioProvider));
});
