import 'package:flutter/material.dart';

/// Fades + slides [child] in once, with an optional per-[index] delay so a
/// list/column of these reveals in a staggered cascade instead of everything
/// popping in at once. Purely cosmetic (no gesture, no state that matters
/// beyond "has it revealed yet"), so it's safe to drop around anything —
/// a card, a form section, a header.
///
/// The index-based delay is capped internally so a long list doesn't take
/// unreasonably long to finish revealing — past that cap every extra item
/// reveals together with the last staggered one instead of queuing further.
class StaggeredFadeSlideIn extends StatefulWidget {
  const StaggeredFadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayPerItem = const Duration(milliseconds: 25),
    this.duration = const Duration(milliseconds: 240),
    this.beginOffset = const Offset(0, 0.06),
  });

  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;
  final Offset beginOffset;

  // Was 8 (up to ~740ms before the last item finished appearing, combined
  // with the old 380ms duration) — cut down after feedback that the app
  // felt slow; content should be fully settled well under half a second.
  static const int _maxStaggeredIndex = 5;

  @override
  State<StaggeredFadeSlideIn> createState() => _StaggeredFadeSlideInState();
}

class _StaggeredFadeSlideInState extends State<StaggeredFadeSlideIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final cappedIndex = widget.index.clamp(0, StaggeredFadeSlideIn._maxStaggeredIndex);
    final delay = widget.delayPerItem * cappedIndex;
    if (delay == Duration.zero) {
      _visible = true;
    } else {
      Future.delayed(delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : widget.beginOffset,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
