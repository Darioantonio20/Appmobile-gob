/// REST contract for the real backend (Laravel + Sanctum token auth) —
/// confirmed against the team's own Bruno collection (`Encuestas SESAECH`),
/// exported examples included:
///
/// - `POST /api/login` — body `{ email, password, device_name }` →
///   `{ token, user: { id, name, email } }`. `token` is a Sanctum
///   plain-text token (`"{id}|{secret}"`), sent back as `Authorization:
///   Bearer {token}` — see `core/network/dio_client.dart`.
/// - `POST /api/logout` — revokes the current token server-side →
///   `{ message }`.
/// - `GET  /api/surveys` — surveys assigned to the authenticated
///   encuestador → `[ { survey_id, title, description, valid_from,
///   valid_until }, ... ]` (no `sections` — list items are summaries).
/// - `GET  /api/surveys/{id}` — same shape, plus the full `sections` tree
///   (`question_id`/`type` as `TR-XX` codes/`options`/`logic_jumps`/
///   `sub_questions` — see `domain/survey.dart`'s doc comments for how
///   [QuestionType] gets inferred from this).
/// - `POST /api/surveys/sync` — submits one filled-in response. Body:
///   `{ response_id, survey_id, respondent_curp, gps_latitude,
///   gps_longitude, started_at, completed_at, answers: [ { question_id,
///   question_option_id, text_value, numeric_value }, ... ] }` →
///   `{ message }`. One endpoint for every survey (the survey is
///   identified inside the body, not the URL) — see
///   `SurveyRemoteDataSource.submitResponse` for how a [SurveyResponse]'s
///   flat answers map gets turned into that `answers` array.
/// - Errors: `401` → `{ message: "Unauthenticated." }`; `4xx` validation →
///   `{ message, errors: { field: [...] } }` — `core/network/
///   network_exceptions.dart` already reads `message` for both.
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/login';
  static const String logout = '/logout';

  static const String surveys = '/surveys';
  static String survey(String surveyId) => '/surveys/$surveyId';
  static const String submitResponse = '/surveys/sync';
}
