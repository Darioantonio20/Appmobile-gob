import 'package:flutter/material.dart';

import '../theme/brand_assets.dart';

/// Subtle background texture of the official "grecas" pattern (Mayan-inspired
/// geometric motif) along the right edge of a screen, sitting behind the
/// page content in low opacity — a background accent, not a competing
/// foreground graphic.
///
/// The source asset (`grecas.png`) is a narrow vertical strip (344×1991px)
/// meant to be *tiled*, not stretched — [ImageRepeat.repeatY] does that, but
/// only looks right once the image is actually scaled down to the target
/// width first via [ResizeImage]; without that, `DecorationImage` renders
/// each tile at the source's full 344px width and just clips it down to fit,
/// which is what made this read as tiny repeated fragments before rather
/// than a clean pattern.
class BrandGrecasAccent extends StatelessWidget {
  const BrandGrecasAccent({
    super.key,
    this.width = 160,
    this.alignment = Alignment.centerRight,
    this.opacity = 0.16,
  });

  final double width;

  /// [Alignment.centerLeft] or [Alignment.centerRight] — which edge of the
  /// parent [Stack] this pins itself to.
  final Alignment alignment;

  /// Kept low on purpose — this sits *behind* page content (first child in
  /// the login screen's [Stack]), so it needs to read as texture, not
  /// compete with the form on top of it.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ResizeImage(
                  const AssetImage(BrandAssets.grecas),
                  width: (width * devicePixelRatio).round(),
                ),
                repeat: ImageRepeat.repeatY,
                alignment: Alignment.topCenter,
                opacity: opacity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
