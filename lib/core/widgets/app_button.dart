import 'package:flutter/material.dart';

/// Primary/secondary action button with a built-in loading state (shows a
/// spinner and disables itself) so async actions (login, submit, sync) can
/// never be double-tapped, and the user always gets visible feedback.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              // Primary button is a solid brand-secondary fill with white
              // text (see elevatedButtonTheme) — the spinner matches that
              // white, not colorScheme.onPrimary, which is a different role
              // now that the button isn't primary-colored.
              color: variant == AppButtonVariant.primary
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(label, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  ),
                ],
              )
            : Text(label, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center);

    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: effectiveOnPressed != null,
        label: isLoading ? '$label, cargando' : label,
        child: switch (variant) {
          AppButtonVariant.primary => ElevatedButton(onPressed: effectiveOnPressed, child: child),
          AppButtonVariant.secondary => OutlinedButton(onPressed: effectiveOnPressed, child: child),
          AppButtonVariant.text => TextButton(onPressed: effectiveOnPressed, child: child),
        },
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, text }
