import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_status.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_assets.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand_app_bar.dart';
import '../../../core/widgets/brand_grecas_accent.dart';
import '../../../core/widgets/staggered_fade_in.dart';
import '../../surveys/presentation/survey_providers.dart';
import 'auth_controller.dart';

/// Read-only view of the logged-in encuestador, plus logout. Deliberately
/// small — the [User] domain model only carries id/name/email today (see
/// `domain/user.dart`), so this shows exactly that and nothing invented.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider);
    final allResponses =
        ref.watch(allResponsesProvider).valueOrNull ?? const [];
    final syncedCount = allResponses
        .where((r) => r.status == SyncStatus.synced)
        .length;

    // No app bar at all on this screen, by explicit design direction: the
    // "Mi perfil" title, the email under it and the bar's own bottom border
    // were all removed so the content starts at the very top of the safe
    // area. Everything the header used to say is already on the card right
    // below it (name, email, avatar), so the bar was pure repetition
    // costing a whole toolbar's worth of vertical space. The back control
    // survives on its own, floated over the content — see
    // `BrandBackButton`'s doc comment.
    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BrandBackButton(color: theme.colorScheme.tertiary),
              ),
            ),
            StaggeredFadeSlideIn(
              index: 0,
              beginOffset: const Offset(0, 0.1),
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  // Primary (brand green) here, not tertiary/red — per
                  // explicit feedback on this screen specifically, paired
                  // with `BrandAppBar` and the stats card below both now
                  // using secondary (brand pink) instead of tertiary too.
                  color: theme.colorScheme.primary,
                ),
                child: Stack(
                  // Explicit — `Stack` otherwise pins its non-positioned
                  // child to the top-start corner instead of centering it,
                  // which is what made the avatar/name/email read as
                  // not-quite-centered.
                  alignment: Alignment.center,
                  children: [
                    // A horizontal grecas band along the bottom edge — this
                    // screen read as too plain/flat; the same official
                    // texture used on the login screen (just rotated to run
                    // sideways here) ties the two together instead of
                    // introducing a new decorative device. `clipBehavior`
                    // above keeps its tiling from spilling past the card's
                    // own rounded corners. Opacity is much higher than the
                    // login screen's version (a background wash on a
                    // near-white page) — at that low an alpha here, the
                    // pattern's own colors washed out into the solid green
                    // behind it instead of reading as the actual grecas
                    // colors, which is the point of having it at all.
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BrandGrecasAccent.horizontal(thickness: 34, opacity: 0.9),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // The extra ring container (surface-colored, slightly
                          // bigger than the avatar) is what makes the avatar read
                          // as "sitting on" the header instead of blending into
                          // it. The elastic scale-in on top gives the header a
                          // focal point instead of just fading in flat with
                          // everything else.
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 550),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) => Transform.scale(scale: value, child: child),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.surface,
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  _initials(user?.name),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            user?.name ?? 'Encuestador',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user?.email ?? '',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.85,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tightened from xl/xxl throughout, per explicit feedback that
            // the two cards, the logout button and the footer logo were
            // drifting apart down a mostly-empty screen — pulling them
            // together is what lets the logo sit just under the button
            // instead of stranded at the bottom.
            const SizedBox(height: AppSpacing.sm),
            StaggeredFadeSlideIn(
              index: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  // Secondary (brand pink/magenta, `C90166`) — not tertiary
                  // (`AE192D`, red); tertiary stays reserved for danger/
                  // destructive contexts (see the logout confirm dialog
                  // below, and `AppColors.danger`) rather than doubling as
                  // an institutional accent here too. Everything on top is
                  // white/`onSecondary` for contrast against that solid pink.
                  color: theme.colorScheme.secondary,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The count in its own circle badge (semi-transparent
                    // white over the pink, not a second solid color — keeps
                    // this flat/on-brand rather than introducing a third
                    // surface color) reads as a stat, not just a stray
                    // number sitting next to an icon.
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.onSecondary.withValues(alpha: 0.16),
                        border: Border.all(color: theme.colorScheme.onSecondary.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: syncedCount),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => Text(
                          '$value',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done_rounded, color: theme.colorScheme.onSecondary, size: 18),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          syncedCount == 1 ? 'Encuesta enviada' : 'Encuestas enviadas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StaggeredFadeSlideIn(
              index: 2,
              // Full width, matching the two cards above it — it was inset
              // on the sides before, which made it read as belonging to a
              // different column than everything else on the screen.
              child: Padding(
                padding: EdgeInsets.zero,
                child: AppButton(
                  label: 'Cerrar sesión',
                  icon: Icons.logout_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _confirmLogout(context, ref),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StaggeredFadeSlideIn(
              index: 3,
              child: Center(
                child: Image.asset(
                  BrandAssets.secretaria,
                  height: 104,
                  fit: BoxFit.contain,
                  semanticLabel:
                      'Secretaría Ejecutiva del Sistema Anticorrupción del Estado de Chiapas',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.tertiaryContainer),
          child: Icon(Icons.logout_rounded, color: theme.colorScheme.onTertiaryContainer, size: 28),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.tertiary),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}
