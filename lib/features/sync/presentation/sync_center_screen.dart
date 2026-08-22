import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/staggered_fade_in.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../../surveys/data/survey_repository_impl.dart';
import '../../surveys/domain/survey_response.dart';
import '../../surveys/presentation/survey_providers.dart';

/// Which slice of the response list the segmented control is showing.
enum _SyncTab { pending, synced }

/// Shows what's still owed to the server and what's already been sent —
/// the one place a surveyor can check "did my work actually go through?"
/// without needing connectivity to get a straight answer.
///
/// No app bar: the title and its caption were removed by explicit design
/// direction, and everything they said is now carried by the status panel
/// directly below (which states the sync state far more concretely anyway).
/// The two lists are no longer stacked one after the other either — a
/// segmented control switches between them, so neither one buries the other
/// once a surveyor has a few dozen responses.
class SyncCenterScreen extends ConsumerStatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  ConsumerState<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends ConsumerState<SyncCenterScreen> {
  _SyncTab _tab = _SyncTab.pending;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allResponsesProvider);
    final engineState = ref.watch(syncEngineProvider);

    return Scaffold(
      body: SafeArea(
        child: allAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorStateView(failure: AppFailure.unknown(null, error)),
          data: (all) {
            final pending = all
                .where((r) => r.status != SyncStatus.synced && r.status != SyncStatus.draft)
                .toList();
            final synced = all.where((r) => r.status == SyncStatus.synced).toList();
            final shown = _tab == _SyncTab.pending ? pending : synced;

            return RefreshIndicator(
              onRefresh: () => ref.read(syncEngineProvider.notifier).triggerNow(),
              child: ResponsiveCenter(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    StaggeredFadeSlideIn(
                      index: 0,
                      child: _StatusHeader(engineState: engineState, pendingCount: pending.length),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StaggeredFadeSlideIn(
                      index: 1,
                      child: _SyncSegmentedFilter(
                        selected: _tab,
                        pendingCount: pending.length,
                        syncedCount: synced.length,
                        onChanged: (tab) => setState(() => _tab = tab),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Cross-fades between the two lists rather than swapping
                    // instantly — with the segmented control right above it,
                    // an abrupt content swap makes the tap feel like a page
                    // reload instead of a filter.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(_tab),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (shown.isEmpty)
                            _EmptyTabCard(tab: _tab)
                          else ...[
                            // Spelled out on the list itself, not only in
                            // the status panel above: this is the exact
                            // spot a surveyor looks when worrying "did my
                            // work get lost?", and the honest answer —
                            // nothing is lost, it goes out by itself — is
                            // what stops them from re-filling a survey they
                            // already completed.
                            if (_tab == _SyncTab.pending) const _AutoSendNote(),
                            for (final response in shown)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _ResponseRow(response: response),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Two-option segmented control with a sliding, color-shifting indicator.
/// [AnimatedAlign] moves the filled pill between the halves while the
/// labels cross-fade their own color, so switching reads as one continuous
/// movement rather than two chips independently toggling.
class _SyncSegmentedFilter extends StatelessWidget {
  const _SyncSegmentedFilter({
    required this.selected,
    required this.pendingCount,
    required this.syncedCount,
    required this.onChanged,
  });

  final _SyncTab selected;
  final int pendingCount;
  final int syncedCount;
  final ValueChanged<_SyncTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingColor = SyncStatus.pending.colorFor(theme.brightness);
    final syncedColor = SyncStatus.synced.colorFor(theme.brightness);
    final isPending = selected == _SyncTab.pending;
    final activeColor = isPending ? pendingColor : syncedColor;

    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: isPending ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ),
          // `stretch`, not the default `center`: each half must fill the
          // control's full height so its tap target does too. With
          // `center`, the segment sized itself to its (short) label row and
          // only that band responded to taps — the rest of the visible
          // button did nothing, which is exactly how this was reported.
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SegmentLabel(
                  label: 'Por enviar',
                  icon: Icons.cloud_upload_outlined,
                  count: pendingCount,
                  active: isPending,
                  onTap: () => onChanged(_SyncTab.pending),
                ),
              ),
              Expanded(
                child: _SegmentLabel(
                  label: 'Enviadas',
                  icon: Icons.cloud_done_rounded,
                  count: syncedCount,
                  active: !isPending,
                  onTap: () => onChanged(_SyncTab.synced),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = active ? Colors.white : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: active,
      label: '$label, $count',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!active) HapticFeedback.selectionClick();
          onTap();
        },
        // `Center` inside the now-stretched half: the gesture detector
        // covers the whole segment (so every part of it is tappable) while
        // the label group stays optically centred within it.
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
              color: fg,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: active ? 1.1 : 1,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Icon(icon, size: 18, color: fg),
                ),
                const SizedBox(width: 6),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1)),
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withValues(alpha: 0.25) : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reassurance banner above the pending list: nothing here needs manual
/// action, it sends itself once there's signal.
class _AutoSendNote extends StatelessWidget {
  const _AutoSendNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = SyncStatus.pending.colorFor(theme.brightness);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Estas encuestas ya están guardadas en tu teléfono. Se enviarán '
              'solas en cuanto tengas conexión — no necesitas hacer nada.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state for whichever tab has nothing in it — the two say genuinely
/// different things, so this isn't one generic "no hay nada" for both.
class _EmptyTabCard extends StatelessWidget {
  const _EmptyTabCard({required this.tab});

  final _SyncTab tab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = tab == _SyncTab.pending;
    final color = isPending
        ? SyncStatus.synced.colorFor(theme.brightness)
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7), width: 1.2),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(
                isPending ? Icons.check_rounded : Icons.inbox_rounded,
                size: 38,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isPending ? 'Todo enviado' : 'Nada enviado todavía',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPending
                ? 'No tienes encuestas pendientes por enviar.'
                : 'Cuando envíes una encuesta aparecerá aquí.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The screen's hero panel. Previously a flat card with a line of text and
/// a button crammed beside it — the whole screen read as unfinished because
/// this, the first thing on it, carried no visual weight at all.
///
/// Now it states the sync state as a headline with a matching status icon
/// disc, and the icon *spins while syncing* so the screen has a live signal
/// during the one moment the user actually cares about progress. The panel
/// itself takes the state's own color (green when everything's through,
/// amber when work is still owed), so the answer to "am I done?" is legible
/// before reading a single word.
class _StatusHeader extends ConsumerStatefulWidget {
  const _StatusHeader({required this.engineState, required this.pendingCount});

  final SyncEngineState engineState;
  final int pendingCount;

  @override
  ConsumerState<_StatusHeader> createState() => _StatusHeaderState();
}

class _StatusHeaderState extends ConsumerState<_StatusHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didUpdateWidget(_StatusHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpinToState();
  }

  @override
  void initState() {
    super.initState();
    _syncSpinToState();
  }

  void _syncSpinToState() {
    if (widget.engineState.isSyncing) {
      if (!_spin.isAnimating) _spin.repeat();
    } else if (_spin.isAnimating) {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.engineState;
    final lastSync = state.lastSuccessAt;
    final isClear = widget.pendingCount == 0;

    final accent = state.isSyncing
        ? SyncStatus.syncing.colorFor(theme.brightness)
        : isClear
            ? SyncStatus.synced.colorFor(theme.brightness)
            : SyncStatus.pending.colorFor(theme.brightness);

    final icon = state.isSyncing
        ? Icons.sync_rounded
        : isClear
            ? Icons.cloud_done_rounded
            : Icons.cloud_upload_outlined;

    final headline = state.isSyncing
        ? 'Sincronizando…'
        : isClear
            ? 'Todo al día'
            : '${widget.pendingCount} por enviar';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: RotationTransition(
                  turns: _spin,
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isClear && !state.isSyncing
                          ? 'Tus encuestas ya están en el servidor.'
                          : 'Se enviarán solas en cuanto haya conexión.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lastSync == null
                      ? 'Aún no se ha sincronizado en esta sesión.'
                      : 'Última sincronización: ${DateFormat("d/MM/y HH:mm").format(lastSync)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: state.isSyncing ? 'Sincronizando…' : 'Sincronizar ahora',
            icon: Icons.sync_rounded,
            isLoading: state.isSyncing,
            onPressed: () => ref.read(syncEngineProvider.notifier).triggerNow(),
          ),
        ],
      ),
    );
  }
}

class _ResponseRow extends ConsumerWidget {
  const _ResponseRow({required this.response});

  final SurveyResponse response;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateLabel = response.submittedAt ?? response.updatedAt;
    final statusColor = response.status.colorFor(theme.brightness);
    final isFailed = response.status == SyncStatus.failed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        // Every row is outlined in its own status color now (not only the
        // failed ones) — scanning a long list for "which of these still
        // need me?" was the whole point of this screen, and a uniform
        // borderless block gave that away for free only on failures.
        border: Border.all(color: statusColor.withValues(alpha: isFailed ? 0.5 : 0.28), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(response.status.icon, size: 20, color: statusColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.surveyTitle,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            DateFormat("d 'de' MMMM, HH:mm", 'es_MX').format(dateLabel),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SyncStatusBadge(status: response.status, compact: true),
            ],
          ),
          if (isFailed) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      response.lastError ?? 'No se pudo enviar. Se reintentará automáticamente.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // A full labelled button rather than the bare refresh icon this
            // used to have — retry is the only action on this screen, and
            // an unlabelled icon made the single thing a user might need to
            // do here the least discoverable part of the row.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(surveyRepositoryProvider).retrySingle(response.localId);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: statusColor,
                  side: BorderSide(color: statusColor.withValues(alpha: 0.6), width: 1.4),
                  minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar envío'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
