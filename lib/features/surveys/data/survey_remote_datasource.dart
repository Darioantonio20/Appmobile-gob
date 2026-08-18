import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../domain/survey.dart';
import '../domain/survey_response.dart';

class SurveyRemoteDataSource {
  SurveyRemoteDataSource(this._dio);

  final Dio _dio;

  // TEMPORAL (dev): todavía no hay backend real conectado (ver README).
  // fetchSurveys()/fetchSurvey() devuelven 3 encuestas de ejemplo fijas, sin
  // red, para poder llenar formularios sin depender de ningún servidor.
  //
  // submitResponse() es distinto a propósito: en vez de simular el envío en
  // memoria, sí hace una petición HTTP real a un endpoint público de pruebas
  // (jsonplaceholder — gratuito, hecho justo para esto: siempre responde 201
  // a un POST). Así "falla sin wifi / se envía al recuperar conexión" es el
  // comportamiento real del dispositivo, no un truco simulado — sirve para
  // probar de verdad el sync engine (`core/sync/sync_engine.dart`).
  //
  // Poner en `false` (o borrar este bloque) en cuanto haya API real; ese día
  // también hay que devolver `submitResponse` a pegarle a
  // `ApiEndpoints.submitResponse` en vez de la URL de pruebas.
  static const bool _mockSurveys = true;
  static const String _testSubmitUrl = 'https://jsonplaceholder.typicode.com/posts';

  static final List<Survey> _sampleSurveys = [
    Survey.fromJson({
      'id': 'demo-001',
      'title': 'Satisfacción con servicios públicos',
      'description': 'Encuesta de ejemplo (datos locales, sin backend real todavía).',
      'updatedAt': DateTime.now().toIso8601String(),
      'sections': [
        {
          'id': 's1',
          'title': 'Datos generales',
          'questions': [
            {'id': 'q1', 'text': '¿Cuál es tu nombre?', 'type': 'short_text', 'required': true},
            {
              'id': 'q2',
              'text': '¿En qué municipio vives?',
              'type': 'single_choice',
              'required': true,
              'options': [
                {'value': 'tuxtla', 'label': 'Tuxtla Gutiérrez'},
                {'value': 'sc', 'label': 'San Cristóbal de las Casas'},
                {'value': 'tapachula', 'label': 'Tapachula'},
              ],
              'allowOther': true,
            },
          ],
        },
        {
          'id': 's2',
          'title': 'Tu experiencia',
          'questions': [
            {
              'id': 'q3',
              'text': '¿Qué tan satisfecho estás con el servicio recibido?',
              'type': 'scale',
              'required': true,
              'scaleMin': 1,
              'scaleMax': 5,
            },
            {
              'id': 'q4',
              'text': '¿Recomendarías este servicio a alguien más?',
              'type': 'yes_no',
              'required': true,
            },
            {'id': 'q5', 'text': '¿Algo que quieras comentar?', 'type': 'long_text', 'required': false},
          ],
        },
      ],
    }),
    Survey.fromJson({
      'id': 'demo-002',
      'title': 'Acceso a agua potable',
      'description': 'Encuesta de ejemplo (datos locales, sin backend real todavía).',
      'updatedAt': DateTime.now().toIso8601String(),
      'sections': [
        {
          'id': 's1',
          'title': 'Datos del hogar',
          'questions': [
            {'id': 'q1', 'text': '¿Cuántas personas viven en tu hogar?', 'type': 'short_text', 'required': true},
            {
              'id': 'q2',
              'text': '¿Tu vivienda cuenta con toma de agua potable?',
              'type': 'yes_no',
              'required': true,
            },
          ],
        },
        {
          'id': 's2',
          'title': 'Frecuencia y calidad',
          'questions': [
            {
              'id': 'q3',
              'text': '¿Con qué frecuencia tienes agua?',
              'type': 'single_choice',
              'required': true,
              'options': [
                {'value': 'diario', 'label': 'Diario'},
                {'value': 'alternos', 'label': 'Días alternos'},
                {'value': 'semanal', 'label': '1-2 veces por semana'},
              ],
              'allowOther': true,
            },
            {
              'id': 'q4',
              'text': '¿Cómo calificarías la calidad del agua?',
              'type': 'scale',
              'required': true,
              'scaleMin': 1,
              'scaleMax': 5,
            },
            {
              'id': 'q5',
              'text': '¿Cuándo fue el último corte de agua?',
              'type': 'date',
              'required': false,
            },
            {'id': 'q6', 'text': 'Comentarios adicionales', 'type': 'long_text', 'required': false},
          ],
        },
      ],
    }),
    Survey.fromJson({
      'id': 'demo-003',
      'title': 'Percepción de seguridad en tu colonia',
      'description': 'Encuesta de ejemplo (datos locales, sin backend real todavía).',
      'updatedAt': DateTime.now().toIso8601String(),
      'sections': [
        {
          'id': 's1',
          'title': 'Percepción general',
          'questions': [
            {
              'id': 'q1',
              'text': '¿Qué tan seguro te sientes en tu colonia?',
              'type': 'scale',
              'required': true,
              'scaleMin': 1,
              'scaleMax': 5,
            },
            {
              'id': 'q2',
              'text': '¿Has sido víctima de algún delito en el último año?',
              'type': 'yes_no',
              'required': true,
            },
          ],
        },
        {
          'id': 's2',
          'title': 'Evaluación de servicios',
          'questions': [
            {
              'id': 'q3',
              'text': 'Califica cada servicio',
              'type': 'likert_matrix',
              'required': true,
              'options': [
                {'value': '1', 'label': 'Muy malo'},
                {'value': '2', 'label': 'Malo'},
                {'value': '3', 'label': 'Regular'},
                {'value': '4', 'label': 'Bueno'},
                {'value': '5', 'label': 'Muy bueno'},
              ],
              'matrixRows': [
                {'id': 'r1', 'text': 'Alumbrado público'},
                {'id': 'r2', 'text': 'Patrullaje policiaco'},
                {'id': 'r3', 'text': 'Tiempo de respuesta a emergencias'},
              ],
            },
            {
              'id': 'q4',
              'text': '¿Qué medidas te gustaría que se implementaran?',
              'type': 'multiple_choice',
              'required': true,
              'options': [
                {'value': 'patrullaje', 'label': 'Más patrullaje'},
                {'value': 'camaras', 'label': 'Cámaras de vigilancia'},
                {'value': 'alumbrado', 'label': 'Mejor alumbrado'},
                {'value': 'comunitario', 'label': 'Programas comunitarios'},
              ],
              'allowOther': true,
            },
            {'id': 'q5', 'text': 'Comentarios', 'type': 'long_text', 'required': false},
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
  /// the body and as an `Idempotency-Key` header, so a retried send (e.g. a
  /// request that succeeded server-side but timed out on the way back)
  /// doesn't create a duplicate — as long as the backend honors the header,
  /// which is a standard, low-effort thing to ask for on its end.
  Future<String?> submitResponse(SurveyResponse response) async {
    final body = {
      'folio': response.folio,
      'localId': response.localId,
      'answers': response.answers,
      'surveyorId': response.surveyorId,
      'surveyorName': response.surveyorName,
      'startedAt': response.startedAt?.toIso8601String(),
      'submittedAt': (response.submittedAt ?? DateTime.now()).toIso8601String(),
      'location': response.hasLocation ? {'lat': response.latitude, 'lng': response.longitude} : null,
      'appVersion': response.appVersion,
    };
    if (_mockSurveys) {
      // Absolute URL on purpose — Dio uses it as-is and ignores baseUrl, so
      // this hits the real internet regardless of the placeholder backend
      // configured in AppConstants.apiBaseUrl.
      final result = await _dio.post<Map<String, dynamic>>(_testSubmitUrl, data: body);
      return result.data?['id']?.toString();
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
