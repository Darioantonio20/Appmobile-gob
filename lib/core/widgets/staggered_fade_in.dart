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
    this.delayPerItem = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 380),
    this.beginOffset = const Offset(0, 0.06),
  });

  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;
  final Offset beginOffset;

  static const int _maxStaggeredIndex = 8;

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
