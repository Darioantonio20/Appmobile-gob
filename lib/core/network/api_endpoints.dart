/// REST contract for the real backend (Laravel + Sanctum token auth),
/// confirmed against Postman-tested examples:
///
/// - `POST /api/login` — body `{ email, password, device_name }` →
///   `{ token, user: { id, name, email } }`. `token` is a Sanctum
///   plain-text token (`"{id}|{secret}"`), sent back as `Authorization:
///   Bearer {token}` — see `core/network/dio_client.dart`.
/// - `GET  /api/surveys` — surveys assigned to the authenticated
///   encuestador → `[ { survey_id, title, description, valid_from,
///   valid_until }, ... ]` (no `sections` — list items are summaries).
/// - `GET  /api/surveys/{id}` — same shape, plus the full `sections` tree.
/// - Errors: `401` → `{ message: "Unauthenticated." }`; `4xx` validation →
///   `{ message, errors: { field: [...] } }` — `core/network/
///   network_exceptions.dart` already reads `message` for both.
///
/// `submitResponse` is a placeholder: the API docs handed off so far cover
/// auth and reading surveys, but not yet how a filled-in response gets
/// posted back. Update this (and `SurveyRemoteDataSource.submitResponse`)
/// once that contract is confirmed — nothing else needs to change.
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/login';

  static const String surveys = '/surveys';
  static String survey(String surveyId) => '/surveys/$surveyId';
  static String submitResponse(String surveyId) => '/surveys/$surveyId/responses';
}
