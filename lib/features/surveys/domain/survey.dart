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
  date;

  static QuestionType fromApi(String? raw) => switch (raw) {
        'short_text' => QuestionType.shortText,
        'long_text' => QuestionType.longText,
        'single_choice' => QuestionType.singleChoice,
        'multiple_choice' => QuestionType.multipleChoice,
        'scale' => QuestionType.scale,
        'yes_no' => QuestionType.yesNo,
        'date' => QuestionType.date,
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
  });

  final String id;
  final String text;
  final String? helperText;
  final QuestionType type;
  final bool isRequired;

  /// Used by [QuestionType.singleChoice] / [QuestionType.multipleChoice].
  final List<QuestionOption> options;

  /// Used by [QuestionType.scale].
  final num scaleMin;
  final num scaleMax;

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
      };

  /// Domain rule for "is this a valid answer to this question" — the single
  /// source of truth used by both the inline per-question validation in the
  /// fill form and the final guard before submit, so they can never
  /// disagree with each other.
  String? validate(Object? value) {
    if (!isRequired) return null;
    final isEmpty = value == null ||
        (value is String && value.trim().isEmpty) ||
        (value is Iterable && value.isEmpty);
    return isEmpty ? 'Esta pregunta es obligatoria.' : null;
  }
}

@immutable
class Survey {
  const Survey({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.questions,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime updatedAt;
  final List<SurveyQuestion> questions;

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
        id: json['id'].toString(),
        title: json['title'] as String? ?? 'Encuesta',
        description: json['description'] as String?,
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'updatedAt': updatedAt.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
