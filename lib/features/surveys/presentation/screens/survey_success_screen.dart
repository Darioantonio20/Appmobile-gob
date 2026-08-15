import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';

/// Shown right after submit. Message adapts to connectivity: online reads
/// as "sent", offline reads as "saved, will send automatically" — never
/// implies the data might be lost.
class SurveySuccessScreen extends ConsumerWidget {
  const SurveySuccessScreen({super.key, required this.surveyId});

  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline ? Icons.check_circle_rounded : Icons.cloud_off_rounded,
                    size: 64,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  isOnline ? '¡Encuesta enviada!' : '¡Encuesta guardada!',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isOnline
                      ? 'Tu respuesta se envió correctamente. Gracias por tu trabajo.'
                      : 'No tienes conexión en este momento, pero no te preocupes: tu respuesta está guardada '
                          'en el dispositivo y se enviará automáticamente en cuanto vuelva el internet.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Volver a mis encuestas',
                  icon: Icons.list_alt_rounded,
                  onPressed: () => context.go(RoutePaths.surveys),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Llenar otra vez',
                  variant: AppButtonVariant.text,
                  onPressed: () => context.pushReplacement(RoutePaths.surveyFillPath(surveyId)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
