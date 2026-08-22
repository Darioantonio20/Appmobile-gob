import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/sync_status_badge.dart';
import '../../domain/survey.dart';
import '../../domain/survey_response.dart';

/// Redesigned institutional survey card.
/// Presents clear status hierarchy, question/section metadata, draft progress,
/// and smooth interactive feedback.
class SurveyCard extends StatefulWidget {
  const SurveyCard({
    super.key,
    required this.survey,
    required this.onTap,
    this.latestResponse,
  });

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
    final isDraft = response?.status == SyncStatus.draft;
    final isSynced = response?.status == SyncStatus.synced;
    final progress = isDraft ? response!.progressFor(survey.allQuestions).clamp(0.0, 1.0) : 0.0;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            // Plain surface + a brand-green border, per the reference
            // mockup — the card reads as "outlined in brand color" rather
            // than as a tinted grey block. A draft just thickens that same
            // green instead of switching to a different hue.
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: isDraft ? 0.6 : 0.3),
              width: isDraft ? 1.5 : 1.2,
            ),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header: Category badge & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rounded square, not a circle — matches the metric
                      // cards' own icon badges up the page, so the two
                      // don't read as two different badge languages on one
                      // screen.
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(
                          isDraft
                              ? Icons.edit_document
                              : isSynced
                                  ? Icons.assignment_turned_in_rounded
                                  : Icons.assignment_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (response != null)
                        SyncStatusBadge(status: response.status, compact: true)
                      else
                        _StatusPill(label: 'Asignada', color: theme.colorScheme.primary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Survey Title
                  Text(
                    survey.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Optional Description
                  if (survey.description != null && survey.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      survey.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // Metadata badges, plus a compact progress indicator
                  // trailing them — shown for every card, not just drafts
                  // (0% for a not-yet-started survey, real progress for a
                  // draft), per the reference mockup.
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _MetaChip(
                              icon: Icons.format_list_bulleted_rounded,
                              label: '${survey.questionCount} preguntas',
                            ),
                            if (survey.sections.length > 1)
                              _MetaChip(
                                icon: Icons.layers_outlined,
                                label: '${survey.sections.length} secciones',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 56,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: progress),
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, val, _) => LinearProgressIndicator(
                                    value: val,
                                    minHeight: 5,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Action footer — a solid filled button per the reference
                  // mockup, not the previous text+arrow row. `FilledButton`
                  // rather than this app's shared `AppButton` on purpose:
                  // `AppButton`'s primary variant is the brand secondary
                  // (pink) fill, but this card's action is specifically
                  // green in the mockup, so it's styled directly here
                  // instead of stretching `AppButton` to a color it doesn't
                  // otherwise use.
                  _CardActionButton(
                    label: isDraft
                        ? 'Continuar llenado'
                        : isSynced
                            ? 'Ver detalle'
                            : 'Iniciar encuesta',
                    onPressed: widget.onTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's primary action — a solid brand-green bar with the label and
/// a trailing arrow. Animated on press rather than static: the whole bar
/// scales down slightly and the arrow slides forward, so the tap reads as
/// "going somewhere" instead of just changing color. Built directly here
/// rather than via this app's shared `AppButton` because `AppButton`'s
/// primary variant is the brand *secondary* (pink) fill — this action is
/// specifically green in the reference mockup, and stretching `AppButton`
/// to a color it doesn't otherwise use would blur what that shared
/// component means everywhere else.
class _CardActionButton extends StatefulWidget {
  const _CardActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_CardActionButton> createState() => _CardActionButtonState();
}

class _CardActionButtonState extends State<_CardActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          height: AppSpacing.minTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: _pressed
                ? Color.alphaBlend(Colors.black.withValues(alpha: 0.12), theme.colorScheme.primary)
                : theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedSlide(
                offset: _pressed ? const Offset(0.35, 0) : Offset.zero,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text-only status pill — the leading icon it used to carry was dropped
/// per explicit design feedback; the label alone already says what the
/// state is, and the icon just crowded a pill this small.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
