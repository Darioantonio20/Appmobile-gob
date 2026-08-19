import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Thick, high-contrast progress bar + "Sección X de Y" label used at the
/// top of the fill-in screen. Deliberately more prominent than a stock thin
/// [LinearProgressIndicator] so users always have a clear sense of how much
/// is left. Tracks sections now (each section is scrolled through as one
/// page), not individual questions.
class SurveyProgressBar extends StatelessWidget {
  const SurveyProgressBar({
    super.key,
    required this.progress,
    required this.current,
    required this.total,
    this.sectionTitle,
  });

  final double progress;
  final int current;
  final int total;

  /// The current section's own title (e.g. "Datos del hogar") — omitted
  /// when the section has no title, or the survey has just one section
  /// where it would just be noise.
  final String? sectionTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sección $current de $total',
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (sectionTitle != null && sectionTitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sectionTitle!,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.secondary),
            ),
          ],
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
