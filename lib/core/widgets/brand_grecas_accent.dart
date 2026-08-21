import 'package:flutter/material.dart';

import '../theme/brand_assets.dart';

/// Subtle background texture of the official "grecas" pattern (Mayan-inspired
/// geometric motif), tiled along an edge of a screen or the edge of some
/// other box (a card, a header), sitting behind real content in low opacity
/// — a background accent, not a competing foreground graphic.
///
/// The source asset (`grecas.png`) is a narrow strip (344×1991px) meant to
/// be *tiled*, not stretched. Two earlier approaches both undercounted how
/// many repeats actually fit, confirmed on-device both times (the pattern
/// stopped partway down a tall phone screen, leaving blank space below):
/// `DecorationImage(repeat: ImageRepeat.repeatY)` over a `ResizeImage`, and
/// — its replacement — a `LayoutBuilder`-measured exact tile count forced
/// onto a `Column` via `OverflowBox`'s tight `minHeight`/`maxHeight`. Both
/// tried to compute exactly enough tiles for the available space; both
/// silently rendered fewer than the math called for. This sidesteps that
/// whole class of bug instead of chasing why: render a generous *fixed*
/// [_tileCount] of tiles — enough to cover any realistic screen or card,
/// tablets included, with real margin to spare — inside an [OverflowBox]
/// that gives them *unbounded* space along the tiling axis to lay out at
/// their natural size (no forced/measured length for anything to
/// under-deliver on), and let the [ClipRect] here trim the excess. Simpler,
/// and there's nothing left to miscount.
///
/// One more thing [OverflowBox] needs to actually stay pinned to
/// [alignment] rather than drifting to the center of the whole screen: it
/// always reports *its own* size to its parent as `constraints.biggest` —
/// the full size its parent offers — regardless of the min/max it's told to
/// give its child. Under `Align`'s loose constraints that's the entire
/// screen width, which silently defeats `alignment` (the actual
/// `thickness`-wide tile ends up centered in that full-width box instead of
/// pinned to the edge). The `SizedBox` below fixes the cross axis *before*
/// `OverflowBox`, so `OverflowBox` itself is only ever as wide (or tall, for
/// the horizontal form) as [thickness] — only the tiling axis inside it is
/// left unbounded.
class BrandGrecasAccent extends StatelessWidget {
  /// A vertical strip pinned to a screen edge (the default use — the login
  /// screen's full-height background accent), tiled top-to-bottom.
  const BrandGrecasAccent({
    super.key,
    this.thickness = 160,
    this.alignment = Alignment.centerRight,
    this.opacity = 0.16,
  }) : horizontal = false;

  /// A horizontal band along the top/bottom edge of some other box (e.g. a
  /// card), tiled left-to-right — each tile is the same motif rotated 90°
  /// so it reads correctly sideways instead of being squashed. Wrap the
  /// parent in a `ClipRRect`/`Container(clipBehavior: Clip.antiAlias)`
  /// matching its own corners so the tiling doesn't spill past a rounded
  /// edge.
  const BrandGrecasAccent.horizontal({
    super.key,
    this.thickness = 40,
    this.alignment = Alignment.bottomCenter,
    this.opacity = 0.16,
  }) : horizontal = true;

  /// Cross-axis size of the strip — width for the vertical (default) form,
  /// height for [BrandGrecasAccent.horizontal].
  final double thickness;

  /// For the vertical form: [Alignment.centerLeft]/[Alignment.centerRight],
  /// which edge of the parent this pins to. For the horizontal form:
  /// [Alignment.topCenter]/[Alignment.bottomCenter].
  final Alignment alignment;

  /// Kept low on purpose — this sits *behind* real content, so it needs to
  /// read as texture, not compete with what's on top of it.
  final double opacity;

  final bool horizontal;

  /// One tile is roughly a phone-screen tall at the default `thickness` —
  /// bumped from 10 to 12 after feedback that the pattern still ran out
  /// before the bottom of the screen on a taller/shorter-DPI viewport than
  /// what this had been checked against; 12 adds real margin past that too.
  static const int _tileCount = 12;

  @override
  Widget build(BuildContext context) {
    final tileImage = Image.asset(BrandAssets.grecas, width: thickness, fit: BoxFit.fitWidth);
    final tile = horizontal ? RotatedBox(quarterTurns: 1, child: tileImage) : tileImage;
    final tiles = List.generate(_tileCount, (_) => tile);

    return IgnorePointer(
      child: ClipRect(
        child: Align(
          alignment: alignment,
          child: SizedBox(
            // Only the cross axis is fixed here — `null` leaves the tiling
            // axis passing through whatever `Align` offered, which
            // `OverflowBox` below then overrides to unbounded.
            width: horizontal ? null : thickness,
            height: horizontal ? thickness : null,
            child: OverflowBox(
              maxWidth: horizontal ? double.infinity : null,
              maxHeight: horizontal ? null : double.infinity,
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacity,
                child: horizontal
                    ? Row(mainAxisSize: MainAxisSize.min, children: tiles)
                    : Column(mainAxisSize: MainAxisSize.min, children: tiles),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
