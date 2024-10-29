import 'package:flutter/widgets.dart';
import 'package:scroll_animator/src/animated_scroll_position.dart';
import 'package:scroll_animator/src/scroll_animation.dart';
import 'package:scroll_animator/src/utils/curves.dart';

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

  /// Animates the position from its current value to the given value.
  ///
  /// If both [duration] and [curve] are non-null, this method behaves
  /// identically to [ScrollController.animateTo]. However, if neither is
  /// provided, the behavior depends on the type of attached scroll positions:
  ///
  ///  * For [AnimatedScrollPosition] instances, [duration] and [curve] are
  ///    sourced from the associated [ScrollAnimationFactory].
  ///  * For other [ScrollPosition] types, the position will typically jump
  ///    immediately to the specified [offset].
  ///
  /// Either both [duration] and [curve] must be provided, or neither.
  @override
  Future<void> animateTo(
    final double offset, {
    final Duration? duration,
    final Curve? curve,
  }) {
    assert(
      (duration != null) == (curve != null),
      'Either both duration and curve should be provided, or neither.',
    );
    return super.animateTo(
      offset,
      duration: duration ?? const Duration(microseconds: 1),
      curve: curve ?? const ScrollAnimatorCurve(type: ScrollType.programmatic),
    );
  }

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
