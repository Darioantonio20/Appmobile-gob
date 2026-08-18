import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/survey.dart';

/// Renders the right input control for a [SurveyQuestion], dispatching on
/// [SurveyQuestion.type]. This is the one place that needs a new branch
/// when [QuestionType] gains a case.
///
/// Every variant uses large tap targets and a single, consistent
/// select/deselect interaction — deliberately avoiding gesture-heavy
/// controls (sliders, swipes) that are harder for older or less
/// tech-familiar users to operate precisely.
class QuestionField extends StatelessWidget {
  const QuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    this.otherValue,
    this.onOtherChanged,
    this.errorText,
  });

  final SurveyQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  /// Free-text value for the "Otra (especifica)" choice — only relevant
  /// when [SurveyQuestion.allowOther] is set.
  final String? otherValue;
  final ValueChanged<String>? onOtherChanged;

  final String? errorText;

  bool get _otherSelected {
    if (!question.allowOther) return false;
    return value == SurveyQuestion.otherOptionValue ||
        (value is Iterable && (value as Iterable).contains(SurveyQuestion.otherOptionValue));
  }

  @override
  Widget build(BuildContext context) {
    final Widget field = switch (question.type) {
      QuestionType.shortText => _TextAnswerField(value: value as String?, onChanged: onChanged, maxLines: 1),
      QuestionType.longText => _TextAnswerField(value: value as String?, onChanged: onChanged, maxLines: 6),
      QuestionType.singleChoice =>
        _SingleChoiceField(question: question, value: value as String?, onChanged: onChanged),
      QuestionType.multipleChoice => _MultipleChoiceField(
          question: question,
          value: (value as List?)?.cast<String>() ?? const [],
          onChanged: onChanged,
        ),
      QuestionType.scale => _ScaleField(question: question, value: value as num?, onChanged: onChanged),
      QuestionType.yesNo => _YesNoField(value: value as bool?, onChanged: onChanged),
      QuestionType.date => _DateField(value: value as String?, onChanged: onChanged),
      QuestionType.likertMatrix => _MatrixField(
          question: question,
          value: (value as Map?)?.cast<String, String>() ?? const {},
          onChanged: onChanged,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        if (_otherSelected) ...[
          const SizedBox(height: AppSpacing.sm),
          // Reuses the same stateful text field as short/long-text answers
          // — a plain TextField rebuilt with `TextEditingController(text:
          // otherValue)` on every keystroke would fight its own cursor.
          _TextAnswerField(
            value: otherValue,
            maxLines: 1,
            hint: 'Especifica tu respuesta',
            onChanged: (v) => onOtherChanged?.call(v as String? ?? ''),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TextAnswerField extends StatefulWidget {
  const _TextAnswerField({
    required this.value,
    required this.onChanged,
    required this.maxLines,
    this.hint = 'Escribe tu respuesta aquí',
  });

  final String? value;
  final ValueChanged<Object?> onChanged;
  final int maxLines;
  final String hint;

  @override
  State<_TextAnswerField> createState() => _TextAnswerFieldState();
}

class _TextAnswerFieldState extends State<_TextAnswerField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _TextAnswerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep in sync if the answer changes from outside this field (e.g. the
    // controller reloads a resumed draft) without fighting the user's cursor
    // while they're actively typing.
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? 4 : 1,
      style: Theme.of(context).textTheme.bodyLarge,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(hintText: widget.hint),
      onChanged: (text) => widget.onChanged(text),
    );
  }
}

/// Choices for single/multiple choice fields, with an "Otra (especifica)"
/// tile automatically appended when [SurveyQuestion.allowOther] is set —
/// backends don't need to remember to add it themselves.
List<QuestionOption> _optionsWithOther(SurveyQuestion question) {
  if (!question.allowOther) return question.options;
  return [...question.options, const QuestionOption(value: SurveyQuestion.otherOptionValue, label: 'Otra (especifica)')];
}

class _SingleChoiceField extends StatelessWidget {
  const _SingleChoiceField({required this.question, required this.value, required this.onChanged});

  final SurveyQuestion question;
  final String? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in _optionsWithOther(question))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ChoiceTile(
              label: option.label,
              selected: value == option.value,
              onTap: () => onChanged(option.value),
              leading: Icons.radio_button_unchecked,
              leadingSelected: Icons.radio_button_checked,
            ),
          ),
      ],
    );
  }
}

class _MultipleChoiceField extends StatelessWidget {
  const _MultipleChoiceField({required this.question, required this.value, required this.onChanged});

  final SurveyQuestion question;
  final List<String> value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in _optionsWithOther(question))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ChoiceTile(
              label: option.label,
              selected: value.contains(option.value),
              leading: Icons.check_box_outline_blank,
              leadingSelected: Icons.check_box,
              onTap: () {
                final next = List<String>.from(value);
                if (next.contains(option.value)) {
                  next.remove(option.value);
                } else {
                  next.add(option.value);
                }
                onChanged(next);
              },
            ),
          ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.leadingSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData leading;
  final IconData leadingSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;
    final bgColor = selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55) : theme.colorScheme.surface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: borderColor, width: selected ? 2 : 1.5),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? leadingSelected : leading,
                  key: ValueKey(selected),
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: theme.textTheme.bodyLarge!.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact selectable chip used inside the Likert matrix. Deliberately not
/// [ChoiceChip]: that widget's default label color doesn't get an explicit
/// override in this app's [ChipThemeData], which made it nearly unreadable
/// against this card's `surfaceContainerLow` background. Uses the same
/// border+background convention as [_ChoiceTile] (proven readable there)
/// instead, animated so selecting an option transitions smoothly rather
/// than snapping.
class _MatrixOptionChip extends StatelessWidget {
  const _MatrixOptionChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;
    final bgColor = selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55) : theme.colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: borderColor, width: selected ? 2 : 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? Icon(Icons.check_rounded, key: const ValueKey('check'), size: 18, color: theme.colorScheme.primary)
                    : const SizedBox(key: ValueKey('nocheck'), width: 0, height: 18),
              ),
              if (selected) const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: theme.textTheme.labelMedium!.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaleField extends StatelessWidget {
  const _ScaleField({required this.question, required this.value, required this.onChanged});

  final SurveyQuestion question;
  final num? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final min = question.scaleMin.toInt();
    final max = question.scaleMax.toInt();

    return Column(
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            for (var i = min; i <= max; i++)
              _ScaleButton(number: i, selected: value?.toInt() == i, onTap: () => onChanged(i)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$min = Muy en desacuerdo', style: theme.textTheme.bodySmall),
            Text('$max = Muy de acuerdo', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _ScaleButton extends StatelessWidget {
  const _ScaleButton({required this.number, required this.selected, required this.onTap});

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: theme.textTheme.titleMedium!.copyWith(
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              child: Text('$number'),
            ),
          ),
        ),
      ),
    );
  }
}

class _YesNoField extends StatelessWidget {
  const _YesNoField({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChoiceTile(
            label: 'Sí',
            selected: value == true,
            leading: Icons.radio_button_unchecked,
            leadingSelected: Icons.check_circle,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChoiceTile(
            label: 'No',
            selected: value == false,
            leading: Icons.radio_button_unchecked,
            leadingSelected: Icons.cancel,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

/// Three plain dropdowns (día/mes/año) instead of [showDatePicker].
///
/// Deliberately not Flutter's built-in Material date picker: it computes its
/// header text scale from the ambient [MediaQuery] in a way that threw
/// `'maxScale > minScale': is not true` on a couple of real
/// devices/browsers — a framework-internal crash outside this app's
/// control. Three dropdowns sidestep it entirely (no dialog route, no
/// internal text-scale math) and fit this app's existing tap-to-select
/// pattern (see [_ChoiceTile]) better than a calendar grid does anyway.
class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<Object?> onChanged;

  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final parsed = value == null ? null : DateTime.tryParse(value!);
    final day = parsed?.day;
    final month = parsed?.month;
    final year = parsed?.year;

    final years = [for (var y = now.year; y >= now.year - 5; y--) y];
    final daysInSelectedMonth = DateTime(year ?? now.year, (month ?? now.month) + 1, 0).day;

    void update({int? newDay, int? newMonth, int? newYear}) {
      final y = newYear ?? year ?? now.year;
      final m = newMonth ?? month ?? now.month;
      final maxDay = DateTime(y, m + 1, 0).day;
      var d = newDay ?? day ?? now.day;
      if (d > maxDay) d = maxDay;
      onChanged(DateTime(y, m, d).toIso8601String());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _DatePartDropdown(
            label: 'Día',
            value: day,
            items: [for (var d = 1; d <= daysInSelectedMonth; d++) (d, '$d')],
            onChanged: (d) => update(newDay: d),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 5,
          child: _DatePartDropdown(
            label: 'Mes',
            value: month,
            items: [for (var m = 1; m <= 12; m++) (m, _months[m - 1])],
            onChanged: (m) => update(newMonth: m),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: _DatePartDropdown(
            label: 'Año',
            value: year,
            items: [for (final y in years) (y, '$y')],
            onChanged: (y) => update(newYear: y),
          ),
        ),
      ],
    );
  }
}

class _DatePartDropdown extends StatelessWidget {
  const _DatePartDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final int? value;
  final List<(int, String)> items;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      hint: const Text('—'),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      ),
      items: [
        for (final (itemValue, itemLabel) in items)
          DropdownMenuItem(value: itemValue, child: Text(itemLabel, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (picked) {
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// Likert matrix: [SurveyQuestion.matrixRows] answered against the shared
/// [SurveyQuestion.options] scale. Stacked "row card + choice chips" on
/// phones; an actual table (rows × columns) on tablets/desktop, per the
/// "optimizado para tabletas" requirement.
class _MatrixField extends StatelessWidget {
  const _MatrixField({required this.question, required this.value, required this.onChanged});

  final SurveyQuestion question;
  final Map<String, String> value;
  final ValueChanged<Object?> onChanged;

  void _select(String rowId, String optionValue) {
    onChanged({...value, rowId: optionValue});
  }

  @override
  Widget build(BuildContext context) {
    return Responsive.isTabletOrWider(context) ? _buildTable(context) : _buildStackedCards(context);
  }

  Widget _buildStackedCards(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final row in question.matrixRows)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.text, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final option in question.options)
                      _MatrixOptionChip(
                        label: option.label,
                        selected: value[row.id] == option.value,
                        onTap: () => _select(row.id, option.value),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      border: TableBorder.all(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      columnWidths: {0: const FlexColumnWidth(2), for (var i = 0; i < question.options.length; i++) i + 1: const FlexColumnWidth(1)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
          children: [
            const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: SizedBox()),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(option.label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
              ),
          ],
        ),
        for (final row in question.matrixRows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(row.text, style: theme.textTheme.bodyMedium),
              ),
              for (final option in question.options)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Center(
                    child: Radio<String>(
                      value: option.value,
                      groupValue: value[row.id],
                      onChanged: (v) => _select(row.id, v!),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
