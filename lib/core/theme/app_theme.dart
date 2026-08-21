import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Builds the app's light and dark [ThemeData] from the design tokens in
/// [AppColors] / [AppTextStyles] / [AppSpacing]. Components are configured
/// once here (button size, input borders, card shape) so every screen gets
/// consistent, accessible defaults for free.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // Material 3's ColorScheme.fromSeed only takes one seed and derives
    // secondary/tertiary from it automatically — fine when there's one
    // brand color, but this brand kit specifies three (primary/secondary/
    // tertiary each a distinct official Pantone). Seeding three independent
    // schemes and stitching primary/secondary/tertiary (plus their on-/
    // container pairs) together keeps each role's contrast properly
    // HCT-computed instead of hand-picking colors that might not pass.
    final primarySeeded = ColorScheme.fromSeed(seedColor: AppColors.brandPrimary, brightness: brightness);
    final secondarySeeded = ColorScheme.fromSeed(seedColor: AppColors.brandSecondary, brightness: brightness);
    final tertiarySeeded = ColorScheme.fromSeed(seedColor: AppColors.brandTertiary, brightness: brightness);

    final colorScheme = primarySeeded.copyWith(
      // `secondary` is the exact brand hex (`AppColors.brandSecondary`,
      // `C90166`) rather than `secondarySeeded.primary` — explicit feedback
      // that the Material-tonal color didn't match the brand swatch: Material
      // 3's `ColorScheme.fromSeed` runs a seed through its HCT algorithm and
      // picks a *computed tone* at a fixed lightness (~40% for light mode),
      // which shifts the actual rendered RGB away from the literal seed hex
      // even though the hue stays close — close enough to look "off" next to
      // an exact reference swatch, which is exactly what was reported here.
      // The other brand colors keep their Material-tonal derivation
      // (unreported as an issue, and `secondaryContainer`/`onSecondaryContainer`
      // below still use the tonal palette too — only the solid accent color
      // itself needed to be exact).
      secondary: AppColors.brandSecondary,
      // White holds up against `brandSecondary` for the same reason
      // `elevatedButtonTheme` below already assumed it does (see that
      // comment) — kept explicit here rather than reusing the seeded
      // `onPrimary`, which was tuned for the *tonal* color, not this exact one.
      onSecondary: Colors.white,
      secondaryContainer: secondarySeeded.primaryContainer,
      onSecondaryContainer: secondarySeeded.onPrimaryContainer,
      // Same fix, same reason as `secondary` above: the literal brand hex
      // (`AppColors.brandTertiary`, `AE192D`) instead of `tertiarySeeded
      // .primary`'s Material-computed tone, confirmed against a reference
      // swatch to actually match this time too.
      tertiary: AppColors.brandTertiary,
      onTertiary: Colors.white,
      tertiaryContainer: tertiarySeeded.primaryContainer,
      onTertiaryContainer: tertiarySeeded.onPrimaryContainer,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: AppTextStyles.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        // Titles in the brand secondary (magenta) — plain (non-BrandAppBar)
        // app bars default to this so a future screen gets it for free.
        titleTextStyle: AppTextStyles.textTheme.titleLarge?.copyWith(
          color: colorScheme.secondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Solid brand secondary (magenta) + white text: of the three brand
          // colors, magenta has the lowest luminance (darkest), so it's the
          // one that holds up best with plain white text on top — chosen for
          // contrast, not just to match the title color, though it happens
          // to also tie primary actions visually to headings.
          backgroundColor: colorScheme.secondary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorScheme.secondary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          textStyle: AppTextStyles.textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          textStyle: AppTextStyles.textTheme.labelLarge,
          side: BorderSide(color: colorScheme.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          textStyle: AppTextStyles.textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        // Brand primary (green/teal) border always, not just on focus —
        // explicit feedback asked for the input border in this color;
        // focused just goes a touch thicker for the usual "this one's
        // active" hierarchy.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: AppTextStyles.textTheme.bodyLarge,
        // Placeholder text and the icons inside the field (prefix/suffix)
        // both in brand secondary (magenta) — explicit feedback: "the icons
        // [should be] whatever color the placeholder is". Applies to every
        // input app-wide via this one theme, including the survey fields.
        hintStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(
          color: colorScheme.secondary,
        ),
        prefixIconColor: colorScheme.secondary,
        suffixIconColor: colorScheme.secondary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        labelStyle: AppTextStyles.textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStateProperty.all(AppTextStyles.textTheme.labelMedium),
        indicatorColor: colorScheme.primaryContainer,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        contentTextStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, space: 1),
      // Dialogs/modals defaulted to bare Material (square-ish corners, no
      // brand identity) — explicit feedback that they "look too simple".
      // Rounded to match cards/buttons and titled in the brand secondary,
      // consistent with the title-color rule elsewhere.
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        titleTextStyle: AppTextStyles.textTheme.headlineSmall?.copyWith(color: colorScheme.secondary),
        contentTextStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
