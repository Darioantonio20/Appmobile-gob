import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
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
    this.errorText,
  });

  final SurveyQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final Widget field = switch (question.type) {
      QuestionType.shortText => _TextAnswerField(value: value as String?, onChanged: onChanged, maxLines: 1),
      QuestionType.longText => _TextAnswerField(value: value as String?, onChanged: onChanged, maxLines: 6),
      QuestionType.singleChoice => _SingleChoiceField(question: question, value: value as String?, onChanged: onChanged),
      QuestionType.multipleChoice => _MultipleChoiceField(
          question: question,
          value: (value as List?)?.cast<String>() ?? const [],
          onChanged: onChanged,
        ),
      QuestionType.scale => _ScaleField(question: question, value: value as num?, onChanged: onChanged),
      QuestionType.yesNo => _YesNoField(value: value as bool?, onChanged: onChanged),
      QuestionType.date => _DateField(value: value as String?, onChanged: onChanged),
    };

    if (errorText == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 6),
            Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ],
    );
  }
}

class _TextAnswerField extends StatefulWidget {
  const _TextAnswerField({required this.value, required this.onChanged, required this.maxLines});

  final String? value;
  final ValueChanged<Object?> onChanged;
  final int maxLines;

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
      decoration: const InputDecoration(hintText: 'Escribe tu respuesta aquí'),
      onChanged: (text) => widget.onChanged(text),
    );
  }
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
        for (final option in question.options)
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
        for (final option in question.options)
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
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: borderColor, width: selected ? 2 : 1.5),
          ),
          child: Row(
            children: [
              Icon(
                selected ? leadingSelected : leading,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                size: 26,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
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
      color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          child: Center(
            child: Text(
              '$number',
              style: theme.textTheme.titleMedium?.copyWith(
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
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

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = value == null ? null : DateTime.tryParse(value!);
    final label = parsed == null ? 'Seleccionar fecha' : DateFormat('d \'de\' MMMM \'de\' y', 'es_MX').format(parsed);

    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: parsed ?? now,
          firstDate: DateTime(now.year - 100),
          lastDate: DateTime(now.year + 5),
          locale: const Locale('es', 'MX'),
        );
        if (picked != null) onChanged(picked.toIso8601String());
      },
      icon: const Icon(Icons.calendar_today_rounded),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}
