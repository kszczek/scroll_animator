import 'package:flutter/animation.dart';
import 'package:scroll_animator/src/animated_scroll_position.dart';
import 'package:scroll_animator/src/scroll_animation.dart';

/// A constant function over the unit interval that always returns `1.0`.
///
/// This curve is meant to be used as a stub. For example,
/// [AnimatedScrollPosition.animateTo] checks for this curve type at runtime
/// and, if detected, sources animation parameters such as duration and the
/// the actual animation curve from the associated [ScrollAnimationFactory].
class ScrollAnimatorCurve extends Curve {
  /// Creates a constant curve that always returns `1.0`.
  const ScrollAnimatorCurve({required this.type});

  /// Source of this scroll event.
  final ScrollType type;

  @override
  double transform(final double t) => 1.0;
}
