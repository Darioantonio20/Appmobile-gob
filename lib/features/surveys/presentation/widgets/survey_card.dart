import 'package:flutter/material.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/sync_status_badge.dart';
import '../../domain/survey.dart';
import '../../domain/survey_response.dart';

/// One survey in the list. Shows a status badge when the user already has a
/// draft or submitted response for it, so it's obvious at a glance what
/// still needs attention.
///
/// Scales down slightly while pressed (a tactile "yes, this registered" cue
/// before the tap even completes) on top of the standard [InkWell] ripple —
/// stateful only for that press feedback, everything else here is static.
class SurveyCard extends StatefulWidget {
  const SurveyCard({super.key, required this.survey, required this.onTap, this.latestResponse});

  final Survey survey;
  final SurveyResponse? latestResponse;
  final VoidCallback onTap;

  @override
  State<SurveyCard> createState() => _SurveyCardState();
}

class _SurveyCardState extends State<SurveyCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final response = widget.latestResponse;
    final survey = widget.survey;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        survey.title,
                        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.secondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedSlide(
                      offset: _pressed ? const Offset(0.15, 0) : Offset.zero,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      child: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                if (survey.description != null && survey.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    survey.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.list_alt_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    // Expanded + ellipsis (was Spacer() + unbounded Text): on a narrow
                    // card (2-column phone grid) a long status label ("No se pudo
                    // enviar") plus this text didn't fit and overflowed. Expanded still
                    // pushes the badge to the right when there's room, but lets this
                    // text give way first — it's less important than the status badge —
                    // instead of the Row breaking.
                    Expanded(
                      child: Text(
                        '${survey.questionCount} preguntas',
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (response != null) SyncStatusBadge(status: response.status, compact: true),
                  ],
                ),
                if (response != null && response.status == SyncStatus.draft) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: response.progressFor(survey.allQuestions).clamp(0, 1)),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
