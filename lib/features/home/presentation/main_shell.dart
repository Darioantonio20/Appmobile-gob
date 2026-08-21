import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/staggered_fade_in.dart';
import '../../surveys/presentation/survey_providers.dart';

/// Persistent bottom-navigation shell for the two top-level sections. Kept
/// to just two destinations on purpose — the target audience benefits far
/// more from "always know where the two things are" than from a richer nav
/// structure.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(
      syncableResponsesProvider.select((s) => s.valueOrNull?.length ?? 0),
    );
    // Brand primary (institutional green) against `BrandAppBar`'s tertiary
    // red — settled here after red and pink both got tried for this bar
    // too and neither read as contrasting with the red app bar (both are
    // warm/reddish-family colors, close to each other on the wheel rather
    // than opposite). Green is the actual complement to red here, *and* the
    // color already carrying every interactive/content accent on this
    // screen (buttons, borders, checkmarks, links) — using it for the one
    // other persistent chrome element ties the whole screen together
    // instead of introducing a third bookend hue nothing else on screen
    // uses. White icons/labels for contrast against the solid green.
    const barColor = AppColors.brandPrimary;
    const iconColor = Colors.white;

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      // Rounded top (still flat — no shadow, this app's cards/bars never
      // use elevation) is what makes the nav bar read as its own designed
      // element instead of a bare system default. Slides up from off-screen
      // on first mount instead of just appearing — explicit request; a full
      // `Offset(0, 1)` starting point (a whole bar-height below) is what
      // actually reads as "coming up" rather than a barely-there nudge.
      bottomNavigationBar: StaggeredFadeSlideIn(
        beginOffset: const Offset(0, 1),
        duration: const Duration(milliseconds: 420),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          child: Container(
            color: barColor,
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              backgroundColor: Colors.transparent,
              indicatorColor: Colors.white.withValues(alpha: 0.22),
              elevation: 0,
              labelTextStyle: WidgetStateProperty.all(const TextStyle(color: iconColor)),
              onDestinationSelected: (index) {
                if (index != navigationShell.currentIndex) {
                  HapticFeedback.selectionClick();
                }
                navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.assignment_outlined, color: iconColor),
                  selectedIcon: _BouncyIcon(Icons.assignment_rounded, color: iconColor),
                  label: 'Encuestas',
                ),
                NavigationDestination(
                  icon: pendingCount == 0
                      ? const Icon(Icons.sync_rounded, color: iconColor)
                      : Badge(label: Text('$pendingCount'), child: const Icon(Icons.sync_rounded, color: iconColor)),
                  selectedIcon: pendingCount == 0
                      ? const _BouncyIcon(Icons.sync_rounded, color: iconColor)
                      : Badge(
                          label: Text('$pendingCount'),
                          child: const _BouncyIcon(Icons.sync_rounded, color: iconColor),
                        ),
                  label: 'Sincronización',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Springs in from slightly-shrunk to full size — Flutter's [NavigationBar]
/// already builds a fresh instance of `selectedIcon` each time a
/// destination becomes selected, so this "just works" as a selection pop
/// without any extra state/keys to manage here.
class _BouncyIcon extends StatelessWidget {
  const _BouncyIcon(this.icon, {this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Icon(icon, color: color),
    );
  }
}
