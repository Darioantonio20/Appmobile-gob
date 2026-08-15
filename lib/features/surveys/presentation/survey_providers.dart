import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/survey_repository_impl.dart';
import '../domain/survey.dart';
import '../domain/survey_response.dart';

/// Reactive, offline-first survey list — reads straight from the local
/// cache, so it has data immediately even with no connection.
final surveysStreamProvider = StreamProvider<List<Survey>>((ref) {
  return ref.watch(surveyRepositoryProvider).watchSurveys();
});

final surveyByIdProvider = FutureProvider.family<Survey?, String>((ref, id) {
  return ref.watch(surveyRepositoryProvider).getSurvey(id);
});

final responsesForSurveyProvider = StreamProvider.family<List<SurveyResponse>, String>((ref, surveyId) {
  return ref.watch(surveyRepositoryProvider).watchResponsesForSurvey(surveyId);
});

/// Every locally-saved response, newest-edited first — backs the Sync
/// Center.
final allResponsesProvider = StreamProvider<List<SurveyResponse>>((ref) {
  return ref.watch(surveyRepositoryProvider).watchAllResponses();
});

/// Responses still owed to the server — drives the Sync Center's "pending"
/// section and the bottom-nav badge count.
final syncableResponsesProvider = StreamProvider<List<SurveyResponse>>((ref) {
  return ref.watch(surveyRepositoryProvider).watchSyncableResponses();
});
