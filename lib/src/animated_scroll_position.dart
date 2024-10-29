import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:scroll_animator/src/animated_scroll_activity.dart';
import 'package:scroll_animator/src/animated_scroll_controller.dart';
import 'package:scroll_animator/src/scroll_animation.dart';
import 'package:scroll_animator/src/utils/curves.dart';

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
  ScrollType? _activityScrollType;

  @override
  Future<void> animateTo(
    final double to, {
    required final Duration duration,
    required final Curve curve,
  }) {
    if (curve is! ScrollAnimatorCurve) {
      return super.animateTo(to, duration: duration, curve: curve);
    }

    final isActivityRunning = !(_activity?.isFinished ?? true);
    final isProgrammaticActivity =
        (_activityScrollType == ScrollType.programmatic);

    if (isActivityRunning && isProgrammaticActivity) {
      _activity!.targetValue = to;
      return _activity!.done;
    }

    // TODO(kszczek): maintain velocity from previous activity of different type
    _activity = AnimatedScrollActivity(
      this,
      animation: _animationFactory.createScrollAnimation(
        Offset(0.0, pixels),
        Offset(0.0, to),
        ScrollType.programmatic,
      ),
      vsync: context.vsync,
    );
    _activityScrollType = ScrollType.programmatic;
    beginActivity(_activity);
    return _activity!.done;
  }

  @override
  void pointerScroll(final double delta) {
    if (delta == 0.0) {
      goBallistic(0.0);
      return;
    }

    final isActivityRunning = !(_activity?.isFinished ?? true);
    final isPointerActivity = (_activityScrollType == ScrollType.pointer);
    final target = (isActivityRunning && isPointerActivity)
        ? _activity!.targetValue
        : pixels;
    final newTarget = clampDouble(
      target + delta,
      minScrollExtent,
      maxScrollExtent,
    );

    if (newTarget == target && (!isActivityRunning || isPointerActivity)) {
      return;
    }

    if (isActivityRunning && isPointerActivity) {
      _activity!.targetValue = newTarget;
      return;
    }

    // TODO(kszczek): maintain velocity from previous activity of different type
    _activity = AnimatedScrollActivity(
      this,
      animation: _animationFactory.createScrollAnimation(
        Offset(0.0, target),
        Offset(0.0, newTarget),
        ScrollType.pointer,
      ),
      vsync: context.vsync,
      onDirectionChanged: updateUserScrollDirection,
    );
    _activityScrollType = ScrollType.pointer;
    beginActivity(_activity);
  }
}
