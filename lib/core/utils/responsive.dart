import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Screen-size classes used to switch layouts (single column on phones,
/// list+detail or wider padding on tablets/desktop).
enum ScreenSize { phone, tablet, desktop }

class Responsive {
  Responsive._();

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (AppBreakpoints.isDesktopOrWide(width)) return ScreenSize.desktop;
    if (AppBreakpoints.isTablet(width)) return ScreenSize.tablet;
    return ScreenSize.phone;
  }

  static bool isPhone(BuildContext context) => of(context) == ScreenSize.phone;
  static bool isTabletOrWider(BuildContext context) => of(context) != ScreenSize.phone;

  /// Horizontal page padding that grows with screen size, and caps content
  /// width on very wide screens so text doesn't stretch edge to edge.
  static EdgeInsets pagePadding(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.phone:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg);
    }
  }

  static double maxContentWidth(BuildContext context) =>
      of(context) == ScreenSize.desktop ? 900 : double.infinity;

  /// How many columns a grid (e.g. survey list on a tablet) should use.
  static int gridColumns(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.phone:
        return 1;
      case ScreenSize.tablet:
        return 2;
      case ScreenSize.desktop:
        return 3;
    }
  }
}

/// Centers and caps the width of [child] on wide screens, leaving it
/// full-width on phones. Wrap page bodies with this for consistent reading
/// widths on tablets/desktop.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
        child: Padding(
          padding: padding ?? Responsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}
