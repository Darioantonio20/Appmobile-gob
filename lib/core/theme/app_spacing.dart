/// Spacing / radius / sizing scale. Use these instead of magic numbers so
/// density stays consistent and easy to retune app-wide.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  /// Minimum touch-target side length (Material accessibility guidance is
  /// 48; we go slightly bigger given the target audience).
  static const double minTouchTarget = 52;

  /// Height used for primary/secondary action buttons app-wide.
  static const double buttonHeight = 56;
}

/// Responsive breakpoints (logical pixels), phone-first.
class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktopOrWide(double width) => width >= desktop;
  static bool isPhone(double width) => width < tablet;
}
