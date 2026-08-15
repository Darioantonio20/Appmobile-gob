/// Centralized route path/name constants — screens and the router both
/// import this instead of hardcoding path strings.
class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String surveys = '/';
  static const String syncCenter = '/sync';

  static const String surveyDetail = '/surveys/:surveyId';
  static String surveyDetailPath(String surveyId) => '/surveys/$surveyId';

  static const String surveyFill = '/surveys/:surveyId/fill';
  static String surveyFillPath(String surveyId, {String? responseLocalId}) {
    final base = '/surveys/$surveyId/fill';
    return responseLocalId == null ? base : '$base?responseLocalId=$responseLocalId';
  }

  static const String surveySuccess = '/surveys/:surveyId/success';
  static String surveySuccessPath(String surveyId) => '/surveys/$surveyId/success';
}
