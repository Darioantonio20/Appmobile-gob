import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Thick, high-contrast progress bar + "Pregunta X de Y" label used at the
/// top of the fill-in screen. Deliberately more prominent than a stock thin
/// [LinearProgressIndicator] so users always have a clear sense of how much
/// is left.
class SurveyProgressBar extends StatelessWidget {
  const SurveyProgressBar({
    super.key,
    required this.progress,
    required this.current,
    required this.total,
    this.sectionLabel,
  });

  final double progress;
  final int current;
  final int total;

  /// e.g. "Sección 2 de 3 · Datos del hogar" — omitted entirely for
  /// single-section surveys, where it would just be noise.
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sectionLabel != null) ...[
            Text(
              sectionLabel!,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            'Pregunta $current de $total',
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0, 1)),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
