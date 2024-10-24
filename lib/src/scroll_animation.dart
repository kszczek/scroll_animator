import 'dart:ui';

import 'package:scroll_animator/src/chromium/scroll_offset_animation_curve.dart';

/// An abstract class representing an animation curve for scrolling.
///
/// A scroll animation instance defines the duration and target value of the
/// scroll, and provides methods to retrieve the animation's state (position
/// and velocity) at a specific point in time since the animation started.
/// Additionally, it allows updating the target value while the animation
/// is running, ensuring smooth transitions between the pre- and post-update
/// animation curves.
abstract class ScrollAnimation {
  /// The total duration of the scroll animation.
  ///
  /// Defines how long the animation is expected to take to reach the target
  /// value. Calling [updateTargetValue] during the animation may adjust this
  /// duration to account for changes in the trajectory.
  Duration get duration;

  /// The target scroll offset the animation aims to reach.
  ///
  /// This value can be updated during the animation using [updateTargetValue].
  Offset get targetValue;

  /// Returns the scroll offset at the specified [elapsed] time since the
  /// animation started.
  Offset getValue(final Duration elapsed);

  /// Returns the rate of change of the scroll offset at the specified [elapsed]
  /// time since the animation started.
  ///
  /// This can be useful for handling scenarios such as applying a ballistic
  /// simulation when the scroll reaches its extent, enabling effects like
  /// bounce physics.
  Offset getVelocity(final Duration elapsed);

  /// Updates the [targetValue] of a running scroll animation at the specified
  /// [elapsed] time since the animation started.
  ///
  /// This method allows the target value to be modified during the animation,
  /// ensuring a smooth transition between the pre- and post-update curves.
  /// Updating the target may also adjust the [duration] to accommodate the
  /// new trajectory.
  void updateTargetValue(final Duration elapsed, final Offset targetValue);
}

/// An abstract factory class for creating instances of [ScrollAnimation]

// This abstract class is needed because concrete implementations may require
// customization and parameters to create different types of scroll animations.
// ignore: one_member_abstracts
abstract class ScrollAnimationFactory {
  /// Creates a new [ScrollAnimation] instance.
  ///
  /// Initializes a scroll animation from the [initialValue] (the current scroll
  /// offset) to the [targetValue] (the desired scroll offset). This method is
  /// typically used to start a new animation. For animations that are already
  /// running, prefer [ScrollAnimation.updateTargetValue] to smoothly adjust the
  /// target value.
  ScrollAnimation createScrollAnimation(
    final Offset initialValue,
    final Offset targetValue,
  );
}

class _ChromiumScrollAnimation implements ScrollAnimation {
  const _ChromiumScrollAnimation(this._curve);

  final ScrollOffsetAnimationCurve _curve;

  @override
  Duration get duration => _curve.Duration_();

  @override
  Offset get targetValue => _curve.target_value();

  @override
  Offset getValue(final Duration elapsed) => _curve.GetValue(elapsed);

  @override
  Offset getVelocity(final Duration elapsed) =>
      Offset(0, _curve.CalculateVelocity(elapsed));

  @override
  void updateTargetValue(final Duration elapsed, final Offset targetValue) =>
      _curve.UpdateTarget(elapsed, targetValue);
}

/// A [ScrollAnimationFactory] that produces ease-in-out style animations,
/// commonly used in Chromium-based browsers.
///
/// This factory creates scroll animations which follow an ease-in-out
/// cubic Bézier curve. The animation is characterized by a smooth
/// acceleration at the beginning and a gradual deceleration towards the
/// end, providing a fluid user experience when interacting with scrollable
/// content.
///
/// See also:
///
///  * [Smooth Scrolling in Chromium](http://bit.ly/smoothscrolling)
class ChromiumEaseInOut implements ScrollAnimationFactory {
  /// Creates a [ScrollAnimationFactory] that produces ease-in-out style
  /// animations, commonly used in Chromium-based browsers.
  const ChromiumEaseInOut();

  @override
  ScrollAnimation createScrollAnimation(
    final Offset initialValue,
    final Offset targetValue,
  ) =>
      _ChromiumScrollAnimation(
        ScrollOffsetAnimationCurve.withDefaultTimingFunction(
          targetValue: targetValue,
          animationType: AnimationType.kEaseInOut,
          durationBehavior: DurationBehavior.kInverseDelta,
        )..SetInitialValue(initialValue, Duration.zero, 0),
      );
}

/// A [ScrollAnimationFactory] that produces impulse-style animations,
/// modeled after the EdgeHTML browser's scrolling behavior.
///
/// The impulse-style animation mimics physical behavior, where content
/// accelerates quickly at the start (impulse) and then decelerates due
/// to friction. This type of animation feels more responsive to user
/// input, as it starts moving immediately after an interaction like a
/// mouse wheel scroll or touchpad gesture.
///
/// See also:
///
///  * [Impulse-style Scroll Animations](https://docs.google.com/document/d/1A3VmlY3ZR6UtJt3QQ5uuqaCOgPjV6vCMxvkpvPBe0g0/edit?tab=t.0)
class ChromiumImpulse implements ScrollAnimationFactory {
  /// Creates a [ScrollAnimationFactory] that produces impulse-style animations,
  /// modeled after the EdgeHTML browser's scrolling behavior.
  const ChromiumImpulse();

  @override
  ScrollAnimation createScrollAnimation(
    final Offset initialValue,
    final Offset targetValue,
  ) =>
      _ChromiumScrollAnimation(
        ScrollOffsetAnimationCurve.withDefaultTimingFunction(
          targetValue: targetValue,
          animationType: AnimationType.kImpulse,
        )..SetInitialValue(initialValue, Duration.zero, 0),
      );
}
