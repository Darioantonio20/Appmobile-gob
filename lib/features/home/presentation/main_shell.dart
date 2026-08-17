import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
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
    final theme = Theme.of(context);
    final pendingCount = ref.watch(syncableResponsesProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      body: navigationShell,
      // Rounded top + a distinct surface tint (still flat — no shadow, this
      // app's cards/bars never use elevation) is what makes the nav bar read
      // as its own designed element instead of a bare system default.
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        child: Container(
          color: theme.colorScheme.surfaceContainer,
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            backgroundColor: Colors.transparent,
            elevation: 0,
            onDestinationSelected: (index) =>
                navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.assignment_outlined),
                selectedIcon: const _BouncyIcon(Icons.assignment_rounded),
                label: 'Encuestas',
              ),
              NavigationDestination(
                icon: pendingCount == 0
                    ? const Icon(Icons.sync_rounded)
                    : Badge(label: Text('$pendingCount'), child: const Icon(Icons.sync_rounded)),
                selectedIcon: pendingCount == 0
                    ? const _BouncyIcon(Icons.sync_rounded)
                    : Badge(label: Text('$pendingCount'), child: const _BouncyIcon(Icons.sync_rounded)),
                label: 'Sincronización',
              ),
            ],
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
  const _BouncyIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Icon(icon),
    );
  }
}
