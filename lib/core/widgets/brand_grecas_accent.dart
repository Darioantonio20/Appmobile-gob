import 'package:flutter/material.dart';

import '../theme/brand_assets.dart';

/// Thin decorative strip of the official "grecas" pattern along one edge of
/// a screen. Tiled vertically ([ImageRepeat.repeatY]) instead of stretched
/// to fit — the pattern is a repeat unit, so tiling is what keeps it
/// crisp and proportional at any screen height, from a small phone to a
/// tall tablet.
///
/// Deliberately narrow (below [AppSpacing]'s smallest page padding) so it
/// reads as a designed accent, not a sidebar competing with page content —
/// wrap the page content in its normal [ResponsiveCenter]/padding as usual;
/// that padding is what keeps text clear of the strip.
class BrandGrecasAccent extends StatelessWidget {
  const BrandGrecasAccent({super.key, this.width = 12, this.alignment = Alignment.centerLeft});

  final double width;

  /// [Alignment.centerLeft] or [Alignment.centerRight] — which edge of the
  /// parent [Stack] this pins itself to.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(BrandAssets.grecas),
              repeat: ImageRepeat.repeatY,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }
}
