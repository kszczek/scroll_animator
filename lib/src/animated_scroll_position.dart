import 'dart:async';
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
    final isActivityMatchingType = (_activityScrollType == curve.type);
    final target = (isActivityRunning && isActivityMatchingType)
        ? _activity!.targetValue
        : pixels;

    if (target == to) {
      if (!isActivityRunning) {
        return Future<void>.value();
      } else if (isActivityMatchingType) {
        return _activity!.done;
      }
    }

    if (isActivityRunning && isActivityMatchingType) {
      _activity!.targetValue = to;
      return _activity!.done;
    }

    // TODO(kszczek): maintain velocity from previous activity of different type
    _activity = AnimatedScrollActivity(
      this,
      animation: _animationFactory.createScrollAnimation(
        Offset(0.0, pixels),
        Offset(0.0, to),
        curve.type,
      ),
      vsync: context.vsync,
      onDirectionChanged: curve.type != ScrollType.programmatic
          ? updateUserScrollDirection
          : null,
    );
    _activityScrollType = curve.type;
    beginActivity(_activity);
    return _activity!.done;
  }

  /// Updates the target position of an active scroll animation or initiates a
  /// new scroll animation based on the provided [delta] value.
  ///
  /// If an animation is already running from a previous [animateTo] or
  /// [pointerScroll] call, it will be cancelled before starting the new one.
  /// The [delta] value is clamped between the minimum and maximum scroll
  /// extents, and the resulting scroll animation respects the boundary
  /// conditions defined by the [ScrollPhysics].
  void keyboardScroll(final double delta) =>
      _relativeScroll(delta, ScrollType.keyboard);

  /// Updates the target position of an active scroll animation or initiates a
  /// new scroll animation based on the provided [delta] value.
  ///
  /// If an animation is already running from a previous [animateTo] or
  /// [keyboardScroll] call, it will be cancelled before starting the new one.
  /// The [delta] value is clamped between the minimum and maximum scroll
  /// extents, and the resulting scroll animation respects the boundary
  /// conditions defined by the [ScrollPhysics].
  ///
  /// A [delta] of `0.0` is treated as an inertia cancel event, immediately
  /// disposing of any velocity we've had and also, depending on the
  /// [ScrollPhysics], causes the scroll position to settle within scroll
  /// extents.
  @override
  void pointerScroll(final double delta) => (delta == 0.0)
      ? goBallistic(0.0)
      : _relativeScroll(delta, ScrollType.pointer);

  void _relativeScroll(final double delta, final ScrollType scrollType) {
    final isActivityRunning = !(_activity?.isFinished ?? true);
    final isActivityMatchingType = (_activityScrollType == scrollType);
    final target = (isActivityRunning && isActivityMatchingType)
        ? _activity!.targetValue
        : pixels;
    final newTarget = clampDouble(
      target + delta,
      minScrollExtent,
      maxScrollExtent,
    );

    unawaited(
      animateTo(
        newTarget,
        duration: const Duration(microseconds: 1),
        curve: ScrollAnimatorCurve(type: scrollType),
      ),
    );
  }
}
