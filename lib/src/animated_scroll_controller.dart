import 'package:flutter/widgets.dart';
import 'package:scroll_animator/src/animated_scroll_position.dart';
import 'package:scroll_animator/src/scroll_animation.dart';

/// A [ScrollController] which provides an [AnimatedScrollPosition] for use by
/// [Scrollable] widgets.
class AnimatedScrollController extends ScrollController {
  /// Creates a scroll controller which provides an [AnimatedScrollPosition]
  /// with the specified [animationFactory] for use by [Scrollable] widgets.
  AnimatedScrollController({
    required final ScrollAnimationFactory animationFactory,
    super.initialScrollOffset = 0.0,
    super.keepScrollOffset = true,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  }) : _animationFactory = animationFactory;

  final ScrollAnimationFactory _animationFactory;

  @override
  ScrollPosition createScrollPosition(
    final ScrollPhysics physics,
    final ScrollContext context,
    final ScrollPosition? oldPosition,
  ) =>
      AnimatedScrollPosition(
        animationFactory: _animationFactory,
        physics: physics,
        context: context,
        initialPixels: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        oldPosition: oldPosition,
        debugLabel: debugLabel,
      );
}
