import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../domain/survey.dart';
import '../domain/survey_response.dart';

/// `started_at`/`completed_at`/`submitted_at` go over the wire as
/// `YYYY-MM-DD HH:mm:ss` (MySQL/Laravel's default `DATETIME` cast format),
/// not ISO-8601 — the backend's own examples use this shape.
final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

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

  /// Submits one filled-in response to `POST /api/surveys/sync`. Needs
  /// [survey] (not just [response]) to know each question's [QuestionType]
  /// — that's what decides whether a raw answer value goes over the wire as
  /// `question_option_id`, `text_value`, or `numeric_value` (see
  /// [_buildAnswers]). The backend identifies the idempotency of a retried
  /// send by [SurveyResponse.localId] (`response_id`) — no separate header
  /// needed, unlike the earlier placeholder contract.
  Future<void> submitResponse(Survey survey, SurveyResponse response) async {
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.submitResponse,
      data: {
        'response_id': response.localId,
        'survey_id': _asId(response.surveyId),
        // No UI collects this yet — always empty until there's a field for
        // it. The backend's own example sends the same empty string.
        'respondent_curp': '',
        'gps_latitude': response.latitude,
        'gps_longitude': response.longitude,
        'started_at': response.startedAt == null ? null : _apiDateFormat.format(response.startedAt!),
        'completed_at': _apiDateFormat.format(response.submittedAt ?? DateTime.now()),
        'answers': _buildAnswers(survey, response.answers),
      },
    );
  }

  /// `question_id`/`question_option_id` are numeric on the real backend;
  /// this app's ids are strings throughout (see `domain/survey.dart`'s
  /// `.toString()` conversions), so send the numeric form when the id
  /// parses as one and fall back to the raw string otherwise (harmless for
  /// real data, just a safety net against a non-numeric id slipping in).
  Object _asId(String id) => int.tryParse(id) ?? id;

  /// Turns this app's flat, type-erased answers map (see
  /// [SurveyResponse.answers]'s doc comment for the value shapes) into the
  /// backend's `[{question_id, question_option_id, text_value,
  /// numeric_value}, ...]` array — one entry per question, except a Likert
  /// matrix question, which contributes one entry per row (rows have their
  /// own `question_id` on the backend, same as any other question — see the
  /// `sub_questions`/`TR-06` shape in `domain/survey.dart`).
  List<Map<String, dynamic>> _buildAnswers(Survey survey, Map<String, Object?> answers) {
    final entries = <Map<String, dynamic>>[];

    Map<String, dynamic> entry({
      required String questionId,
      Object? optionId,
      String? text,
      num? numeric,
    }) =>
        {
          'question_id': _asId(questionId),
          'question_option_id': optionId == null ? null : _asId(optionId.toString()),
          'text_value': text,
          'numeric_value': numeric,
        };

    String? otherTextFor(SurveyQuestion question, String optionId) {
      for (final option in question.options) {
        if (option.id == optionId) {
          return option.requiresText ? answers[question.textAnswerKeyFor(option)] as String? : null;
        }
      }
      return null;
    }

    for (final question in survey.allQuestions) {
      final value = answers[question.id];

      switch (question.type) {
        case QuestionType.singleChoice:
          if (value is String && value.isNotEmpty) {
            entries.add(entry(questionId: question.id, optionId: value, text: otherTextFor(question, value)));
          }
        case QuestionType.multipleChoice:
          if (value is Iterable) {
            for (final optionId in value) {
              entries.add(
                entry(
                  questionId: question.id,
                  optionId: optionId,
                  text: otherTextFor(question, optionId.toString()),
                ),
              );
            }
          }
        case QuestionType.numeric:
          final numericValue = value is num ? value : num.tryParse(value?.toString() ?? '');
          if (numericValue != null) entries.add(entry(questionId: question.id, numeric: numericValue));
        case QuestionType.shortText:
        case QuestionType.longText:
        case QuestionType.date:
          if (value is String && value.isNotEmpty) entries.add(entry(questionId: question.id, text: value));
        case QuestionType.likertMatrix:
          if (value is Map) {
            for (final row in question.matrixRows) {
              final rowValue = value[row.id] as String?;
              if (rowValue != null && rowValue.isNotEmpty) {
                entries.add(entry(questionId: row.id, optionId: rowValue));
              }
            }
          }
      }

      // Question-level "requires text" (rare — no options at all, just a
      // free-text follow-up tied to the question itself) is additional to
      // whatever the switch above already added, so it's its own entry
      // rather than merged into one.
      if (question.requiresText) {
        final questionText = answers[question.textAnswerKeyFor()] as String?;
        if (questionText != null && questionText.isNotEmpty) {
          entries.add(entry(questionId: question.id, text: questionText));
        }
      }
    }

    return entries;
  }
}

final surveyRemoteDataSourceProvider = Provider<SurveyRemoteDataSource>((ref) {
  return SurveyRemoteDataSource(ref.watch(dioProvider));
});
