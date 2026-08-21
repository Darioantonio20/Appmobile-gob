import 'dart:ui';

import 'package:flutter/material.dart';

/// AppBar as a translucent "liquid glass" panel — used on every top-level
/// screen (survey list, detail, sync center, profile) instead of a plain
/// surface-colored bar or a solid brand color. This one change is the most
/// visible "does this app look designed" signal a user gets, since it's the
/// first thing on screen everywhere, so it's centralized here rather than
/// re-styled per screen.
///
/// This went through several solid-color rounds first — red, then
/// secondary/pink, then red again — before explicit feedback asked for a
/// glass look instead specifically to sidestep re-litigating which flat
/// color to use: a frosted, mostly-transparent panel doesn't read as "red"
/// or "pink" at all, so the color debate that kept resurfacing here doesn't
/// apply anymore. Brand identity now lives in the (red) text/icon color on
/// top of the glass instead of in a solid background fill.
///
/// Genuinely frosted, not just a flat translucent color: [BackdropFilter]
/// blurs whatever's actually behind the bar (the tiny sliver visible
/// through the corners even without `extendBodyBehindAppBar`, and the full
/// scrolled content on any screen that does opt into that), and the
/// semi-transparent white fill plus a hairline bottom edge is what keeps it
/// readable as its own panel rather than just "blurry" with no definition.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, required this.title, this.actions, this.leading, this.bottom});

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Brand tertiary (red) for text/icons on top of the glass — the brand
    // statement this bar makes now lives here instead of in a solid fill.
    final onGlass = theme.colorScheme.tertiary;
    final titleStyle = (theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge)?.copyWith(
      color: onGlass,
      fontWeight: FontWeight.bold,
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.62),
            border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
          ),
          child: AppBar(
            title: DefaultTextStyle(style: titleStyle ?? TextStyle(color: onGlass), child: title),
            leading: leading,
            actions: actions,
            bottom: bottom,
            backgroundColor: Colors.transparent,
            foregroundColor: onGlass,
            iconTheme: IconThemeData(color: onGlass),
            actionsIconTheme: IconThemeData(color: onGlass),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
