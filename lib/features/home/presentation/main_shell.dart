import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final pendingCount = ref.watch(syncableResponsesProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Encuestas',
          ),
          NavigationDestination(
            icon: pendingCount == 0
                ? const Icon(Icons.sync_rounded)
                : Badge(label: Text('$pendingCount'), child: const Icon(Icons.sync_rounded)),
            selectedIcon: pendingCount == 0
                ? const Icon(Icons.sync_rounded)
                : Badge(label: Text('$pendingCount'), child: const Icon(Icons.sync_rounded)),
            label: 'Sincronización',
          ),
        ],
      ),
    );
  }
}
