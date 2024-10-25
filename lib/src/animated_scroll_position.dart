import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:scroll_animator/src/animated_scroll_activity.dart';
import 'package:scroll_animator/src/animated_scroll_controller.dart';
import 'package:scroll_animator/src/scroll_animation.dart';

/// A [ScrollPositionWithSingleContext] that animates pointer scroll deltas
/// based on the [ScrollAnimation] provided by specified
/// [ScrollAnimationFactory].
///
/// This class differs from [ScrollPositionWithSingleContext] only by its
/// [pointerScroll] implementation. Instead of suddenly updating the scroll
/// offset, this implementation uses an [AnimatedScrollActivity] to smooth
/// out large scroll deltas into multiple smaller ones. When a new scroll delta
/// arrives when an [AnimatedScrollActivity] is still active, this class tries
/// to update its target, rather than replacing it with a new activity to ensure
/// a smooth scrolling experience even when user changes the target offset
/// during the scroll animation.
///
/// See also:
///
///  * [AnimatedScrollActivity], a scroll activity which breaks down large
///    scroll deltas into multiple tiny ones based on the animation curve
///    provided to it by the [ScrollAnimation].
///  * [AnimatedScrollController], which provides instances of the
///    [AnimatedScrollPosition].
class AnimatedScrollPosition extends ScrollPositionWithSingleContext {
  /// A [ScrollPositionWithSingleContext] that animates pointer scroll deltas
  /// based on the [ScrollAnimation] provided by specified [animationFactory].
  AnimatedScrollPosition({
    required final ScrollAnimationFactory animationFactory,
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  }) : _animationFactory = animationFactory;

  final ScrollAnimationFactory _animationFactory;
  AnimatedScrollActivity? _activity;

  @override
  void pointerScroll(final double delta) {
    if (delta == 0.0) {
      goBallistic(0.0);
      return;
    }

    final useCurrentOffsetAsCurrentTarget = _activity?.isFinished ?? true;
    final currentTarget =
        (useCurrentOffsetAsCurrentTarget ? pixels : _activity?.targetValue) ??
            pixels;
    final double newTarget = math.min(
      math.max(currentTarget + delta, minScrollExtent),
      maxScrollExtent,
    );

    if (newTarget == currentTarget) {
      return;
    }

    if (_activity == null || _activity!.isFinished) {
      _activity = AnimatedScrollActivity(
        this,
        animation: _animationFactory.createScrollAnimation(
          Offset(0.0, currentTarget),
          Offset(0.0, newTarget),
          ScrollType.pointer,
        ),
        vsync: context.vsync,
        onDirectionChanged: updateUserScrollDirection,
      );
      beginActivity(_activity);
    } else {
      _activity!.targetValue = newTarget;
    }
  }
}
