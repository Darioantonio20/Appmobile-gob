/// REST contract this app expects from the government survey backend.
///
/// This is the single place that names endpoints, so pointing the app at
/// the real backend (once its exact contract is confirmed) means editing
/// this file and the two datasources that use it —
/// `features/auth/data/auth_remote_datasource.dart` and
/// `features/surveys/data/survey_remote_datasource.dart` — nothing in the
/// domain/presentation layers needs to change.
///
/// Assumed shapes (adjust to match the real API):
/// - `POST /auth/login` → `{ token, user: { id, name, email } }`
/// - `GET  /surveys` → `[ { id, title, description, updatedAt, questions: [...] }, ... ]`
/// - `GET  /surveys/{id}` → same shape as one list item
/// - `POST /surveys/{id}/responses` → accepts one filled-in survey response
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String me = '/auth/me';

  static const String surveys = '/surveys';
  static String survey(String surveyId) => '/surveys/$surveyId';
  static String submitResponse(String surveyId) => '/surveys/$surveyId/responses';
}
