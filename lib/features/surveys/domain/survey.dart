import 'package:flutter/foundation.dart';

/// Rendering type inferred for a question. The real backend doesn't send
/// one of these directly — it sends a `type` code (`"TR-01"`..`"TR-08"`)
/// whose exact meaning isn't documented. [SurveyQuestion.fromJson] infers
/// this from *structure* instead (has options? has sub_questions? has a
/// numeric range? has a min_length?), which is unambiguous for every
/// example seen, including a real `GET /surveys/{id}` response confirming
/// TR-01 and TR-07 (see below — an earlier guess here had both as [date],
/// now disproven):
///
/// | API `type` | shape observed                          | inferred as     |
/// |---|---|---|
/// | TR-03, TR-04, TR-07 | `options: [...]`, no `sub_questions` | [singleChoice] |
/// | TR-05        | no options, `min_value`/`max_value`/`max_decimals` set | [numeric] |
/// | TR-01        | no options, `min_length` set, no `max_length` | [longText] |
/// | TR-02        | no options, no numeric/length hints    | [longText]       |
/// | TR-08        | `options` (the scale) + `sub_questions` | [likertMatrix] |
/// | TR-06        | only ever seen nested as a sub_question, no options of its own | folded into the parent's [SurveyQuestion.matrixRows], never rendered top-level |
///
/// No multiple-choice example was present in any sample payload — nothing
/// currently maps to [multipleChoice] (a `TR-07` question with more than
/// one `option.isCorrect` was seen, but that's scoring metadata, not proof
/// the UI should allow multi-select — see [QuestionOption.isCorrect]). If a
/// backend type turns out to mean "select several", that's one more
/// structural check to add here.
///
/// [date] has no confirmed backend code as of the payload above — every
/// TR-01..TR-08 code observed maps to one of the rows in the table. It's
/// kept for a future date-type question (built as a custom tap-based
/// control, never `showDatePicker` — see the project's `flutter-ui-review`
/// skill) and, until a real code is confirmed, nothing infers it.
enum QuestionType { singleChoice, multipleChoice, numeric, shortText, longText, likertMatrix, date }

@immutable
class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.label,
    this.isCorrect = false,
    this.weight = 0,
    this.requiresText = false,
    this.textPlaceholder,
  });

  final String id;
  final String label;

  /// Scoring metadata from the backend — the app never acts on these
  /// itself (no client-side scoring), just carries them.
  final bool isCorrect;
  final int weight;

  /// When true, selecting this option reveals a free-text field (e.g. an
  /// "Otro, especifique" choice) whose answer is required alongside it.
  /// See [SurveyQuestion.textAnswerKeyFor].
  final bool requiresText;
  final String? textPlaceholder;

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
        id: json['option_id'].toString(),
        label: json['label'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
        weight: (json['weight'] as num?)?.toInt() ?? 0,
        requiresText: json['requires_text'] as bool? ?? false,
        textPlaceholder: json['text_placeholder'] as String?,
      );

  /// Mirrors the API's own field names so this round-trips through
  /// [QuestionOption.fromJson] unchanged — used only to cache a fetched
  /// survey to SQLite, never sent back to the backend.
  Map<String, dynamic> toJson() => {
        'option_id': id,
        'label': label,
        'is_correct': isCorrect,
        'weight': weight,
        'requires_text': requiresText,
        'text_placeholder': textPlaceholder,
      };
}

/// "If the user picked [conditionOptionId] on this question, jump straight
/// to [targetQuestionId]" — server-authored skip logic. A real payload
/// confirmed jumps landing both *within* the same section (skipping one of
/// two questions right after the trigger) and, in principle, into a later
/// one — so this can't be resolved at section granularity alone. See
/// [Survey.reachableQuestionIds], which walks the whole survey
/// question-by-question and is what actually decides which questions get
/// shown/validated, in or across sections.
@immutable
class LogicJump {
  const LogicJump({required this.conditionOptionId, required this.targetQuestionId, this.description});

  final String conditionOptionId;
  final String targetQuestionId;
  final String? description;

  factory LogicJump.fromJson(Map<String, dynamic> json) => LogicJump(
        conditionOptionId: json['condition_option_id'].toString(),
        targetQuestionId: json['target_question_id'].toString(),
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'condition_option_id': conditionOptionId, 'target_question_id': targetQuestionId, 'description': description};
}

@immutable
class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.type,
    required this.text,
    this.parentId,
    this.apiTypeCode = '',
    this.isRequired = false,
    this.order = 0,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.maxDecimals,
    this.requiresText = false,
    this.textPlaceholder,
    this.options = const [],
    this.logicJumps = const [],
    this.matrixRows = const [],
  });

  final String id;
  final String? parentId;

  /// Raw backend code (`"TR-03"`, …) — kept for debugging/telemetry, not
  /// used for rendering decisions (see [type]).
  final String apiTypeCode;
  final QuestionType type;

  final String text;
  final bool isRequired;
  final int order;

  /// Text-answer constraints ([QuestionType.shortText]/[longText]).
  final int? minLength;
  final int? maxLength;

  /// Numeric-answer constraints ([QuestionType.numeric]).
  final num? minValue;
  final num? maxValue;
  final int? maxDecimals;

  /// Question-level "requires an accompanying free-text answer" — distinct
  /// from (and rarer than) [QuestionOption.requiresText], which is per
  /// option. Uses the same answer-key convention; see [textAnswerKeyFor].
  final bool requiresText;
  final String? textPlaceholder;

  /// [QuestionType.singleChoice]/[multipleChoice] (the choices) and
  /// [QuestionType.likertMatrix] (the shared scale / column headers).
  final List<QuestionOption> options;

  final List<LogicJump> logicJumps;

  /// [QuestionType.likertMatrix] only: one row per `sub_question` the
  /// backend nested under this question. Each row is answered with one of
  /// [options]' ids — only `.id`/`.text` are meaningful for a row; its own
  /// `options`/`type`/etc. are unused.
  final List<SurveyQuestion> matrixRows;

  /// Answers map key for the free-text field tied to [option] (or to this
  /// question itself, when [option] is null and [requiresText] is set).
  String textAnswerKeyFor([QuestionOption? option]) => option == null ? '${id}_text' : '${id}_opt_${option.id}';

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    final options =
        (json['options'] as List<dynamic>? ?? const []).map((o) => QuestionOption.fromJson(o as Map<String, dynamic>)).toList();
    final subQuestionsJson = json['sub_questions'] as List<dynamic>? ?? const [];
    final hasSubQuestions = subQuestionsJson.isNotEmpty;
    final rawType = json['type'] as String?;

    return SurveyQuestion(
      id: json['question_id'].toString(),
      parentId: json['parent_id']?.toString(),
      apiTypeCode: rawType ?? '',
      type: _inferType(json, hasOptions: options.isNotEmpty, hasSubQuestions: hasSubQuestions),
      text: json['question_text'] as String? ?? '',
      isRequired: json['is_required'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
      minLength: (json['min_length'] as num?)?.toInt(),
      maxLength: (json['max_length'] as num?)?.toInt(),
      minValue: _parseNum(json['min_value']),
      maxValue: _parseNum(json['max_value']),
      maxDecimals: (json['max_decimals'] as num?)?.toInt(),
      requiresText: json['requires_text'] as bool? ?? false,
      textPlaceholder: json['text_placeholder'] as String?,
      options: options,
      logicJumps:
          (json['logic_jumps'] as List<dynamic>? ?? const []).map((j) => LogicJump.fromJson(j as Map<String, dynamic>)).toList(),
      // Only folded in when this question actually has the shared scale to
      // answer them against — a question with sub_questions but no options
      // of its own doesn't match the one matrix pattern seen so far, so it
      // falls back to rendering as plain text rather than a broken matrix.
      matrixRows: hasSubQuestions && options.isNotEmpty
          ? subQuestionsJson.map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  static num? _parseNum(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw;
    return num.tryParse(raw.toString());
  }

  /// Mirrors the API's own field names so this round-trips through
  /// [SurveyQuestion.fromJson] unchanged — used only to cache a fetched
  /// survey to SQLite, never sent back to the backend. [type] itself isn't
  /// written back out — [apiTypeCode] is, and re-parsing re-derives [type]
  /// from structure exactly as it did the first time.
  Map<String, dynamic> toJson() => {
        'question_id': id,
        'parent_id': parentId,
        'type': apiTypeCode,
        'question_text': text,
        'is_required': isRequired,
        'order': order,
        'min_length': minLength,
        'max_length': maxLength,
        'min_value': minValue,
        'max_value': maxValue,
        'max_decimals': maxDecimals,
        'requires_text': requiresText,
        'text_placeholder': textPlaceholder,
        'options': options.map((o) => o.toJson()).toList(),
        'logic_jumps': logicJumps.map((j) => j.toJson()).toList(),
        'sub_questions': matrixRows.map((r) => r.toJson()).toList(),
      };

  static QuestionType _inferType(Map<String, dynamic> json, {required bool hasOptions, required bool hasSubQuestions}) {
    if (hasSubQuestions && hasOptions) return QuestionType.likertMatrix;
    if (hasOptions) return QuestionType.singleChoice;
    final hasNumericHint = json['min_value'] != null || json['max_value'] != null || json['max_decimals'] != null;
    if (hasNumericHint) return QuestionType.numeric;
    final maxLength = (json['max_length'] as num?)?.toInt();
    if (maxLength != null && maxLength <= 150) return QuestionType.shortText;
    return QuestionType.longText;
  }

  /// Domain rule for "is this a valid answer to this question" — the single
  /// source of truth used by both inline validation in the fill form and
  /// the final guard before submit, so they can never disagree.
  ///
  /// [textAnswers] holds any accompanying free-text values, keyed by
  /// [textAnswerKeyFor] — needed here because whether one is *required*
  /// depends on which option was picked.
  String? validate(Object? value, {Map<String, Object?> textAnswers = const {}}) {
    if (type == QuestionType.likertMatrix) {
      if (!isRequired) return null;
      final answers = value is Map ? value : const {};
      final unanswered = matrixRows.any((row) => (answers[row.id] as String?)?.isEmpty ?? true);
      return unanswered ? 'Responde todas las filas.' : null;
    }

    final isEmpty = value == null || (value is String && value.trim().isEmpty) || (value is Iterable && value.isEmpty);
    if (isRequired && isEmpty) return 'Esta pregunta es obligatoria.';
    if (isEmpty) return null; // optional and empty — nothing further to check

    if (type == QuestionType.numeric) {
      final numericValue = value is num ? value : num.tryParse(value.toString());
      if (numericValue == null) return 'Ingresa un número válido.';
      if (minValue != null && numericValue < minValue!) return 'El valor mínimo es $minValue.';
      if (maxValue != null && numericValue > maxValue!) return 'El valor máximo es $maxValue.';
    }

    if ((type == QuestionType.shortText || type == QuestionType.longText) && value is String) {
      if (minLength != null && value.trim().length < minLength!) return 'Mínimo $minLength caracteres.';
      if (maxLength != null && value.length > maxLength!) return 'Máximo $maxLength caracteres.';
    }

    // Question-level "requires text" (rare — most of the time it's
    // per-option, checked next).
    if (requiresText && ((textAnswers[textAnswerKeyFor()] as String?)?.trim().isEmpty ?? true)) {
      return 'Especifica tu respuesta.';
    }

    final selectedIds = value is Iterable ? value.cast<String>() : [value.toString()];
    for (final option in options) {
      if (!option.requiresText || !selectedIds.contains(option.id)) continue;
      if ((textAnswers[textAnswerKeyFor(option)] as String?)?.trim().isEmpty ?? true) {
        return 'Especifica tu respuesta.';
      }
    }

    return null;
  }
}

@immutable
class SurveySection {
  const SurveySection({required this.id, required this.title, this.order = 0, this.questions = const []});

  final String id;
  final String title;
  final int order;
  final List<SurveyQuestion> questions;

  factory SurveySection.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>? ?? const [])
        .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
        // Sub_questions only ever arrive nested inside their parent's own
        // `sub_questions` field, never duplicated into this flat list too —
        // this filter is a defensive no-op against that, not a fix for
        // something actually observed.
        .where((q) => q.parentId == null)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return SurveySection(
      id: json['section_id'].toString(),
      title: json['title'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() =>
      {'section_id': id, 'title': title, 'order': order, 'questions': questions.map((q) => q.toJson()).toList()};
}

@immutable
class Survey {
  const Survey({
    required this.id,
    required this.title,
    this.description,
    this.validFrom,
    this.validUntil,
    this.sections = const [],
  });

  final String id;
  final String title;
  final String? description;

  /// Assignment/availability window from the backend — informational only
  /// today. `GET /surveys` already only returns surveys currently assigned
  /// to the encuestador, so the app doesn't additionally gate on these
  /// client-side (and both are `null` in every example seen).
  final DateTime? validFrom;
  final DateTime? validUntil;

  /// Populated from `GET /surveys/{id}`; empty for a list-item-only
  /// [Survey] (`GET /surveys` doesn't include sections).
  final List<SurveySection> sections;

  /// Every top-level question across every section, in order — used where
  /// section grouping doesn't matter (progress calculation, flat
  /// validation sweeps). Matrix rows are intentionally excluded: they're
  /// answered as part of their parent, not independently.
  List<SurveyQuestion> get allQuestions => sections.expand((s) => s.questions).toList(growable: false);

  int get questionCount => sections.fold(0, (sum, s) => sum + s.questions.length);

  /// Index of the section containing [questionId] (searching top-level
  /// questions only), or `null` if not found — used to resolve a
  /// [LogicJump]'s target into "which section do we jump to".
  int? sectionIndexForQuestion(String questionId) {
    for (var i = 0; i < sections.length; i++) {
      if (sections[i].questions.any((q) => q.id == questionId)) return i;
    }
    return null;
  }

  /// Ordered ids of the top-level questions actually reachable given
  /// [answers], honoring every [SurveyQuestion.logicJumps] — the single
  /// source of truth for "which questions does the user actually see",
  /// used both to decide what to render within a section
  /// ([SurveyFillReady.currentQuestions]) and to drive section-to-section
  /// navigation ([SurveyFillController.goNext]).
  ///
  /// A real payload put two mutually-exclusive follow-ups (`26`/`27`) right
  /// after their gating question (`25`, "¿Quieres ir al cine conmigo?" —
  /// Sí→26, No→27), both in the *same* section, with no jump defined on
  /// `26` itself to skip past `27`. A plain "jump to target, else next in
  /// order" walk would show both once either branch was taken — this needs
  /// one more rule: every question named as *any* jump's target anywhere in
  /// the survey is "gated" — excluded from the default "next in order"
  /// fallback (whether or not its own gating question has fired yet) and
  /// only ever shown by actually being the *chosen* target of a fired jump.
  /// That's what makes `26` and `27` mutually exclusive here even though
  /// neither carries its own outgoing jump, and it's also why an unanswered
  /// gate hides every one of its listed targets rather than defaulting to
  /// showing the structurally-next one — with several questions on screen
  /// at once (this app never shows one question at a time), showing an
  /// unresolved branch's target before its condition is actually met would
  /// be misleading.
  ///
  /// Walks forward from the first question in survey order. At each step:
  /// if the question just visited has an answer matching one of its own
  /// jumps' `conditionOptionId`, the walk continues from that jump's
  /// `targetQuestionId` — wherever it is, same section or a later one —
  /// regardless of gating (an explicitly chosen target is never hidden).
  /// Otherwise it continues from the next non-gated question in order.
  /// Guards against a malformed jump cycle by stopping the walk the moment
  /// it would revisit a question.
  List<String> reachableQuestionIds(Map<String, Object?> answers) {
    final all = allQuestions;
    if (all.isEmpty) return const [];
    final byId = {for (final q in all) q.id: q};
    final gatedIds = <String>{for (final q in all) for (final jump in q.logicJumps) jump.targetQuestionId};

    final visited = <String>{};
    final path = <String>[];
    String? currentId = all.first.id;
    while (currentId != null && visited.add(currentId)) {
      path.add(currentId);
      final question = byId[currentId];
      if (question == null) break;
      currentId = _fireJump(question, answers) ?? _nextVisibleQuestionIdAfter(all, currentId, gatedIds);
    }
    return path;
  }

  /// Resolves [question]'s [LogicJump]s against [answers]; the first one
  /// whose `conditionOptionId` matches the selected value(s) wins (ties
  /// aren't expected in practice). Returns null when the question has no
  /// jumps, isn't answered yet, or nothing matches — meaning "no jump
  /// fires, walk continues in order".
  static String? _fireJump(SurveyQuestion question, Map<String, Object?> answers) {
    if (question.logicJumps.isEmpty) return null;
    final answer = answers[question.id];
    final selectedIds = answer is Iterable ? answer.map((v) => v?.toString()).toList() : [answer?.toString()];
    for (final jump in question.logicJumps) {
      if (selectedIds.contains(jump.conditionOptionId)) return jump.targetQuestionId;
    }
    return null;
  }

  /// The next question after [id] in survey order that isn't [gatedIds] —
  /// skipping over any question that's only meant to appear as someone's
  /// explicitly-chosen jump target (see [reachableQuestionIds]).
  static String? _nextVisibleQuestionIdAfter(List<SurveyQuestion> all, String id, Set<String> gatedIds) {
    final index = all.indexWhere((q) => q.id == id);
    if (index == -1) return null;
    for (var i = index + 1; i < all.length; i++) {
      if (!gatedIds.contains(all[i].id)) return all[i].id;
    }
    return null;
  }

  factory Survey.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>?;
    final sections = (sectionsJson ?? const []).map((s) => SurveySection.fromJson(s as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return Survey(
      id: json['survey_id'].toString(),
      title: json['title'] as String? ?? 'Encuesta',
      description: json['description'] as String?,
      validFrom: _parseDate(json['valid_from']),
      validUntil: _parseDate(json['valid_until']),
      sections: sections,
    );
  }

  static DateTime? _parseDate(Object? raw) => raw == null ? null : DateTime.tryParse(raw.toString());

  Map<String, dynamic> toJson() => {
        'survey_id': id,
        'title': title,
        'description': description,
        'valid_from': validFrom?.toIso8601String(),
        'valid_until': validUntil?.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}
