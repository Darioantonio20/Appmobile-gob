import 'package:flutter/material.dart';

/// AppBar in the brand's solid primary color — used on every top-level
/// screen (survey list, detail, sync center, profile) instead of a plain
/// surface-colored bar. This one change is the most visible "does this app
/// look designed" signal a user gets, since it's the first thing on screen
/// everywhere, so it's centralized here rather than re-styled per screen.
///
/// Solid on purpose (was a primary→tertiary gradient at first — dropped per
/// explicit feedback that it read as muddy/looked bad; a flat brand color
/// is also just more consistent with the rest of this app's flat design
/// language, which never uses gradients or shadows elsewhere either).
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, required this.title, this.actions, this.leading, this.bottom});

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = theme.colorScheme.onPrimary;
    final titleStyle = (theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge)?.copyWith(color: onBrand);

    return AppBar(
      title: DefaultTextStyle(style: titleStyle ?? TextStyle(color: onBrand), child: title),
      leading: leading,
      actions: actions,
      bottom: bottom,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: onBrand,
      iconTheme: IconThemeData(color: onBrand),
      actionsIconTheme: IconThemeData(color: onBrand),
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
