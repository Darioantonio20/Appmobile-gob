import 'package:flutter/foundation.dart';

/// Question types the fill-in form knows how to render. Add a new case here
/// + a matching branch in `question_field.dart` to support a new type — an
/// unrecognized value from the backend safely falls back to [shortText]
/// instead of crashing (see [QuestionType.fromApi]).
enum QuestionType {
  shortText,
  longText,
  singleChoice,
  multipleChoice,
  scale,
  yesNo,
  date,

  /// Likert matrix: a shared scale ([SurveyQuestion.options], used as the
  /// column headers) answered once per [SurveyQuestion.matrixRows] row.
  likertMatrix;

  static QuestionType fromApi(String? raw) => switch (raw) {
        'short_text' => QuestionType.shortText,
        'long_text' => QuestionType.longText,
        'single_choice' => QuestionType.singleChoice,
        'multiple_choice' => QuestionType.multipleChoice,
        'scale' => QuestionType.scale,
        'yes_no' => QuestionType.yesNo,
        'date' => QuestionType.date,
        'likert_matrix' => QuestionType.likertMatrix,
        _ => QuestionType.shortText,
      };

  String get apiValue => switch (this) {
        QuestionType.shortText => 'short_text',
        QuestionType.longText => 'long_text',
        QuestionType.singleChoice => 'single_choice',
        QuestionType.multipleChoice => 'multiple_choice',
        QuestionType.scale => 'scale',
        QuestionType.yesNo => 'yes_no',
        QuestionType.date => 'date',
        QuestionType.likertMatrix => 'likert_matrix',
      };
}

@immutable
class QuestionOption {
  const QuestionOption({required this.value, required this.label});

  final String value;
  final String label;

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
        value: json['value'].toString(),
        label: json['label']?.toString() ?? json['value'].toString(),
      );

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

/// One row/reactivo of a [QuestionType.likertMatrix] question.
@immutable
class MatrixRow {
  const MatrixRow({required this.id, required this.text});

  final String id;
  final String text;

  factory MatrixRow.fromJson(Map<String, dynamic> json) =>
      MatrixRow(id: json['id'].toString(), text: json['text'] as String? ?? '');

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

@immutable
class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.helperText,
    this.isRequired = true,
    this.options = const [],
    this.scaleMin = 1,
    this.scaleMax = 5,
    this.allowOther = false,
    this.matrixRows = const [],
  });

  final String id;
  final String text;
  final String? helperText;
  final QuestionType type;
  final bool isRequired;

  /// Used by [QuestionType.singleChoice] / [QuestionType.multipleChoice]
  /// (the choices) and [QuestionType.likertMatrix] (the shared scale /
  /// column headers).
  final List<QuestionOption> options;

  /// Used by [QuestionType.scale].
  final num scaleMin;
  final num scaleMax;

  /// Single/multiple choice only: appends an "Otra (especifica)" choice
  /// that reveals a free-text field when selected. The free-text value is
  /// stored under a derived answer key — see `otherAnswerKey`.
  final bool allowOther;

  /// Used by [QuestionType.likertMatrix]: the rows/reactivos, answered one
  /// [options] value each.
  final List<MatrixRow> matrixRows;

  /// Reserved option value the UI uses for the synthetic "Otra" choice.
  static const String otherOptionValue = '__other__';

  /// Answers map key used to store the free-text value for "Otra".
  String get otherAnswerKey => '${id}_other';

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) => SurveyQuestion(
        id: json['id'].toString(),
        text: json['text'] as String? ?? '',
        helperText: json['helperText'] as String?,
        type: QuestionType.fromApi(json['type'] as String?),
        isRequired: json['required'] as bool? ?? true,
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        scaleMin: (json['scaleMin'] as num?) ?? 1,
        scaleMax: (json['scaleMax'] as num?) ?? 5,
        allowOther: json['allowOther'] as bool? ?? false,
        matrixRows: (json['matrixRows'] as List<dynamic>? ?? const [])
            .map((r) => MatrixRow.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'helperText': helperText,
        'type': type.apiValue,
        'required': isRequired,
        'options': options.map((o) => o.toJson()).toList(),
        'scaleMin': scaleMin,
        'scaleMax': scaleMax,
        'allowOther': allowOther,
        'matrixRows': matrixRows.map((r) => r.toJson()).toList(),
      };

  /// Domain rule for "is this a valid answer to this question" — the single
  /// source of truth used by both the inline per-question validation in the
  /// fill form and the final guard before submit, so they can never
  /// disagree with each other.
  ///
  /// [otherValue] is only consulted when [allowOther] is set and the "Otra"
  /// choice was picked.
  String? validate(Object? value, {String? otherValue}) {
    if (!isRequired) return null;

    if (type == QuestionType.likertMatrix) {
      final answers = value is Map ? value : const {};
      final unanswered = matrixRows.any((row) => (answers[row.id] as String?)?.isEmpty ?? true);
      return unanswered ? 'Responde todas las filas.' : null;
    }

    final isEmpty = value == null ||
        (value is String && value.trim().isEmpty) ||
        (value is Iterable && value.isEmpty);
    if (isEmpty) return 'Esta pregunta es obligatoria.';

    if (allowOther) {
      final otherSelected = value == SurveyQuestion.otherOptionValue ||
          (value is Iterable && value.contains(SurveyQuestion.otherOptionValue));
      if (otherSelected && (otherValue == null || otherValue.trim().isEmpty)) {
        return 'Especifica tu respuesta.';
      }
    }

    return null;
  }
}

/// A group of related questions within a [Survey], shown together as one
/// step of the fill-in flow ("Sección X de Y").
@immutable
class SurveySection {
  const SurveySection({required this.id, required this.title, this.description, required this.questions});

  final String id;
  final String title;
  final String? description;
  final List<SurveyQuestion> questions;

  factory SurveySection.fromJson(Map<String, dynamic> json) => SurveySection(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

@immutable
class Survey {
  const Survey({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.sections,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime updatedAt;
  final List<SurveySection> sections;

  /// Every question across every section, in order — used where the
  /// section grouping doesn't matter (progress calculation, flat
  /// validation sweeps).
  List<SurveyQuestion> get allQuestions => sections.expand((s) => s.questions).toList(growable: false);

  int get questionCount => sections.fold(0, (sum, s) => sum + s.questions.length);

  factory Survey.fromJson(Map<String, dynamic> json) {
    final List<SurveySection> sections;
    if (json['sections'] is List) {
      sections = (json['sections'] as List)
          .map((s) => SurveySection.fromJson(s as Map<String, dynamic>))
          .toList();
    } else {
      // Lenient fallback for a backend that sends a flat `questions` array
      // instead of `sections`: treat the whole survey as one implicit,
      // untitled section rather than rejecting the payload.
      final questions = (json['questions'] as List<dynamic>? ?? const [])
          .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
      sections = questions.isEmpty ? const [] : [SurveySection(id: 'default', title: '', questions: questions)];
    }

    return Survey(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Encuesta',
      description: json['description'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      sections: sections,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'updatedAt': updatedAt.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}
