import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../domain/survey.dart';
import '../domain/survey_response.dart';

class SurveyRemoteDataSource {
  SurveyRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Survey>> fetchSurveys() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.surveys);
    final data = response.data ?? const [];
    return data.map((e) => Survey.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Survey> fetchSurvey(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.survey(id));
    return Survey.fromJson(response.data ?? const {});
  }

  /// Submits one filled-in response. Sends [SurveyResponse.localId] both in
  /// the body and as an `Idempotency-Key` header, so a retried send (e.g. a
  /// request that succeeded server-side but timed out on the way back)
  /// doesn't create a duplicate — as long as the backend honors the header,
  /// which is a standard, low-effort thing to ask for on its end.
  Future<String?> submitResponse(SurveyResponse response) async {
    final result = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.submitResponse(response.surveyId),
      data: {
        'folio': response.folio,
        'localId': response.localId,
        'answers': response.answers,
        'surveyorId': response.surveyorId,
        'surveyorName': response.surveyorName,
        'startedAt': response.startedAt?.toIso8601String(),
        'submittedAt': (response.submittedAt ?? DateTime.now()).toIso8601String(),
        'location': response.hasLocation ? {'lat': response.latitude, 'lng': response.longitude} : null,
        'appVersion': response.appVersion,
      },
      options: Options(headers: {'Idempotency-Key': response.localId}),
    );
    return result.data?['id']?.toString();
  }
}

final surveyRemoteDataSourceProvider = Provider<SurveyRemoteDataSource>((ref) {
  return SurveyRemoteDataSource(ref.watch(dioProvider));
});
