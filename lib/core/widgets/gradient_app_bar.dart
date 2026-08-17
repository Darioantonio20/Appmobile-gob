import 'package:flutter/material.dart';

/// AppBar with this app's signature primary→tertiary gradient background —
/// used on every top-level screen (survey list, detail, sync center,
/// profile) instead of a plain surface-colored bar. This one change is the
/// most visible "does this app look designed" signal a user gets, since
/// it's the first thing on screen everywhere, so it's centralized here
/// rather than re-styled per screen.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, required this.title, this.actions, this.leading, this.bottom});

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onGradient = theme.colorScheme.onPrimary;
    final titleStyle = (theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge)?.copyWith(color: onGradient);

    return AppBar(
      title: DefaultTextStyle(style: titleStyle ?? TextStyle(color: onGradient), child: title),
      leading: leading,
      actions: actions,
      bottom: bottom,
      backgroundColor: Colors.transparent,
      foregroundColor: onGradient,
      iconTheme: IconThemeData(color: onGradient),
      actionsIconTheme: IconThemeData(color: onGradient),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
