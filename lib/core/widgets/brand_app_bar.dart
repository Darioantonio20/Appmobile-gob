import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

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
/// A translucent surface tint plus a hairline bottom edge is what carries
/// the look. There *was* a real [BackdropFilter] blur here; it was removed
/// for performance after a report that the app felt slow, and it cost
/// nothing visually to do so: a backdrop blur only shows a difference when
/// there is content *behind* the bar to blur, which requires
/// `extendBodyBehindAppBar` — and no screen in this app sets it. The blur
/// was therefore re-blurring a flat scaffold background on every single
/// frame, at full GPU cost, for a result indistinguishable from the plain
/// translucent fill below. If a screen ever does opt into
/// `extendBodyBehindAppBar`, reintroduce the blur *there*, scoped to that
/// screen, rather than making every other screen pay for it again.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.bottom,
  });

  final Widget title;

  /// Optional one-line caption under [title] — a bare title on its own read
  /// as unfinished on the screens that only have two or three words up
  /// there ("Mi perfil", "Sincronización"). Adding context here is cheaper
  /// than padding those screens' bodies with explanatory text.
  final String? subtitle;

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

    return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.62),
            border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
          ),
          child: AppBar(
            title: subtitle == null
                ? DefaultTextStyle(style: titleStyle ?? TextStyle(color: onGlass), child: title)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: (titleStyle ?? TextStyle(color: onGlass)).copyWith(height: 1.1),
                        child: title,
                      ),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
            // A styled pill-shaped back control instead of Material's bare
            // default arrow — the default read as unfinished next to the
            // rest of this app's rounded, tinted chrome, and it's on every
            // pushed screen so it's worth centralizing here rather than
            // per-screen. Only substituted when there's actually something
            // to pop; a root tab keeps whatever `leading` it was given.
            leading: leading ?? (Navigator.of(context).canPop() ? BrandBackButton(color: onGlass) : null),
            actions: actions,
            bottom: bottom,
            backgroundColor: Colors.transparent,
            foregroundColor: onGlass,
            iconTheme: IconThemeData(color: onGlass),
            actionsIconTheme: IconThemeData(color: onGlass),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// Back control: a tinted rounded square with the arrow inside, matching
/// the icon-badge shape used on the survey cards and metric cards, and
/// animating on press (shrink) the same way this app's other tap targets
/// do — so "go back" doesn't end up being the one undesigned, unanimated
/// control on an otherwise polished screen.
///
/// [BrandAppBar] drops this in automatically; it's public so a screen that
/// deliberately has *no* app bar (see the profile screen, which pulls its
/// content to the very top) can still float the same control over its own
/// body instead of hand-rolling a second back-button style.
class BrandBackButton extends StatefulWidget {
  const BrandBackButton({super.key, required this.color});

  final Color color;

  @override
  State<BrandBackButton> createState() => _BrandBackButtonState();
}

class _BrandBackButtonState extends State<BrandBackButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Sizes itself to the 40x40 box and nothing more — deliberately *not*
    // wrapped in `Center`. It was, and inside `AppBar`'s narrow leading
    // slot that looked fine, but the profile screen places this straight
    // into a full-width column: there, the `Center` expanded to the whole
    // row and pulled the button to the middle of the screen, ignoring the
    // caller's own alignment. Staying intrinsically sized lets every caller
    // position it however they like.
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).maybePop();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _pressed ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 22, color: widget.color),
          ),
        ),
      ),
    );
  }
}
