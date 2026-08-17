import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_status.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
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
    final allResponses = ref.watch(allResponsesProvider).valueOrNull ?? const [];
    final syncedCount = allResponses.where((r) => r.status == SyncStatus.synced).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ResponsiveCenter(
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.sm),
            StaggeredFadeSlideIn(
              index: 0,
              beginOffset: const Offset(0, 0.1),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                  ),
                ),
                child: Column(
                  children: [
                    // The extra ring container (surface-colored, slightly bigger
                    // than the avatar) is what makes the avatar read as "sitting
                    // on" the gradient instead of blending into it.
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surface),
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
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      user?.name ?? 'Encuestador',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user?.email ?? '',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            StaggeredFadeSlideIn(
              index: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                        ),
                        child: Icon(Icons.cloud_done_rounded, color: theme.colorScheme.onPrimaryContainer, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: syncedCount),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (context, value, _) =>
                                Text('$value', style: theme.textTheme.headlineMedium),
                          ),
                          Text(
                            syncedCount == 1 ? 'Encuesta enviada' : 'Encuestas enviadas',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            StaggeredFadeSlideIn(
              index: 2,
              child: AppButton(
                label: 'Cerrar sesión',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => _confirmLogout(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar tu sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}
