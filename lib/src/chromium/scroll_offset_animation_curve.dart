// Copyright 2015 The Chromium Authors
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google LLC nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// This library mirrors Chromium's ScrollOffsetAnimationCurve implementation
// to make it easier to integrate future changes from Chromium.
// Some linter rules are disabled to match Chromium's code style.
// Please avoid refactoring to keep the line-by-line similarity.
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: omit_local_variable_types
// ignore_for_file: parameter_assignments
// ignore_for_file: prefer_asserts_with_message
// ignore_for_file: public_member_api_docs
// ignore_for_file: unnecessary_breaks

// Based on revision 132.0.6793.1:
// https://source.chromium.org/chromium/chromium/src/+/refs/tags/132.0.6793.1:cc/animation/scroll_offset_animation_curve.cc

import 'dart:math';
import 'dart:ui';

import 'package:scroll_animator/src/utils/differentiable_curves.dart';
import 'package:scroll_animator/src/utils/duration.dart';

const double kConstantDuration = 9.0;
const double kDurationDivisor = 60.0;

// 0.7 seconds limit for long-distance programmatic scrolls
const double kDeltaBasedMaxDuration = 0.7 * kDurationDivisor;

const double kInverseDeltaRampStartPx = 120.0;
const double kInverseDeltaRampEndPx = 480.0;
const double kInverseDeltaMinDuration = 6.0;
const double kInverseDeltaMaxDuration = 12.0;

const double kInverseDeltaSlope =
    (kInverseDeltaMinDuration - kInverseDeltaMaxDuration) /
        (kInverseDeltaRampEndPx - kInverseDeltaRampStartPx);

const double kInverseDeltaOffset =
    kInverseDeltaMaxDuration - kInverseDeltaRampStartPx * kInverseDeltaSlope;

const double kImpulseCurveX1 = 0.25;
const double kImpulseCurveX2 = 0.0;
const double kImpulseCurveY2 = 1.0;

const double kImpulseMinDurationMs = 200.0;
const double kImpulseMaxDurationMs = 500.0;
const double kImpulseMillisecondsPerPixel = 1.5;

const double kEpsilon = 0.01;

double MaximumDimension(final Offset delta) =>
    delta.dx.abs() > delta.dy.abs() ? delta.dx : delta.dy;

DifferentiableCurve EaseInOutWithInitialSlope(double slope) {
  // Clamp slope to a sane value.
  slope = slope.clamp(-1000.0, 1000.0);

  // Based on DifferentiableCurves.easeInOut preset
  // with first control point scaled.
  const double x1 = 0.42;
  final double y1 = slope * x1;
  return DifferentiableCubic(x1, y1, 0.58, 1);
}

DifferentiableCurve ImpulseCurveWithInitialSlope(final double slope) {
  assert(slope >= 0);

  double x1 = kImpulseCurveX1;
  double y1 = 1.0;
  if (x1 * slope < 1.0) {
    y1 = x1 * slope;
  } else {
    x1 = y1 / slope;
  }

  const double x2 = kImpulseCurveX2;
  const double y2 = kImpulseCurveY2;
  return DifferentiableCubic(x1, y1, x2, y2);
}

bool IsNewTargetInOppositeDirection(
  final Offset current_position,
  final Offset old_target,
  final Offset new_target,
) {
  final Offset old_delta = old_target - current_position;
  final Offset new_delta = new_target - current_position;

  // We only declare the new target to be in the "opposite" direction when
  // one of the dimensions doesn't change at all. This may sound a bit strange,
  // but it avoids lots of issues.
  // For instance, if we are moving to the down & right and we are updated to
  // move down & left, then are we moving in the opposite direction? If we don't
  // do the check this way, then it would be considered in the opposite
  // direction and the velocity gets set to 0. The update would therefore look
  // pretty janky.
  if ((old_delta.dx - new_delta.dx).abs() < kEpsilon) {
    return (old_delta.dy >= 0.0) != (new_delta.dy >= 0.0);
  } else if ((old_delta.dy - new_delta.dy).abs() < kEpsilon) {
    return (old_delta.dx >= 0.0) != (new_delta.dx >= 0.0);
  } else {
    return false;
  }
}

Duration? VelocityBasedDurationBound(
  final Offset old_delta,
  final double velocity,
  final Offset new_delta,
) {
  final double new_delta_max_dimension = MaximumDimension(new_delta);

  // If we are already at the target, stop animating.
  if (new_delta_max_dimension.abs() < kEpsilon) {
    return Duration.zero;
  }

  // Guard against division by zero.
  if (velocity.abs() < kEpsilon) {
    // Since Dart's Duration class can't represent infinite durations,
    // we return null to signify an infinite duration.
    return null;
  }

  // Estimate how long it will take to reach the new target at our present
  // velocity, with some fudge factor to account for the "ease out".
  final double bound = (new_delta_max_dimension / velocity) * 2.5;

  // If bound < 0 we are moving in the opposite direction.
  return bound < 0 ? null : durationFromSeconds(bound);
}

enum AnimationType { kLinear, kEaseInOut, kImpulse }

// Indicates how the animation duration should be computed for Ease-in-out
// style scroll animation curves.
enum DurationBehavior {
  // Duration proportional to scroll delta; used for programmatic scrolls.
  kDeltaBased,
  // Constant duration; used for keyboard scrolls.
  kConstant,
  // Duration inversely proportional to scroll delta within certain bounds.
  // Used for mouse wheels, makes fast wheel flings feel "snappy" while
  // preserving smoothness of slow wheel movements.
  kInverseDelta,
}

DifferentiableCurve DefaultTimingFunction(final AnimationType animation_type) {
  switch (animation_type) {
    case AnimationType.kEaseInOut:
      return DifferentiableCurves.easeInOut;
    case AnimationType.kLinear:
      return DifferentiableCurves.linear;
    case AnimationType.kImpulse:
      return ImpulseCurveWithInitialSlope(0);
  }
}

class ScrollOffsetAnimationCurve {
  ScrollOffsetAnimationCurve({
    required final Offset targetValue,
    required final DifferentiableCurve timingFunction,
    required final AnimationType animationType,
    final DurationBehavior? durationBehavior,
  })  : assert(
          (animationType == AnimationType.kEaseInOut) ==
              (durationBehavior != null),
        ),
        _target_value_ = targetValue,
        _timing_function_ = timingFunction,
        _animation_type_ = animationType,
        _duration_behavior_ = durationBehavior,
        _has_set_initial_value_ = false;

  ScrollOffsetAnimationCurve.withDefaultTimingFunction({
    required final Offset targetValue,
    required final AnimationType animationType,
    final DurationBehavior? durationBehavior,
  }) : this(
          targetValue: targetValue,
          timingFunction: DefaultTimingFunction(animationType),
          animationType: animationType,
          durationBehavior: durationBehavior,
        );

  Offset _initial_value_ = Offset.zero;
  Offset _target_value_;
  Duration _total_animation_duration_ = Duration.zero;

  // Time from animation start to most recent UpdateTarget.
  Duration _last_retarget_ = Duration.zero;

  DifferentiableCurve _timing_function_;
  final AnimationType _animation_type_;

  // Only valid when |animation_type_| is EASE_IN_OUT.
  final DurationBehavior? _duration_behavior_;

  bool _has_set_initial_value_;

  static double? _animation_duration_for_testing_;

  static Duration EaseInOutSegmentDuration(
    final Offset delta,
    final DurationBehavior duration_behavior,
    final Duration delayed_by,
  ) {
    double duration = kConstantDuration;
    if (_animation_duration_for_testing_ == null) {
      switch (duration_behavior) {
        case DurationBehavior.kConstant:
          duration = kConstantDuration;
          break;
        case DurationBehavior.kDeltaBased:
          duration = min(
            sqrt(MaximumDimension(delta).abs()),
            kDeltaBasedMaxDuration,
          );
          break;
        case DurationBehavior.kInverseDelta:
          duration = kInverseDeltaOffset +
              MaximumDimension(delta).abs() * kInverseDeltaSlope;
          duration = duration.clamp(
            kInverseDeltaMinDuration,
            kInverseDeltaMaxDuration,
          );
          break;
      }
      duration /= kDurationDivisor;
    } else {
      duration = _animation_duration_for_testing_!;
    }

    final Duration delay_adjusted_duration =
        durationFromSeconds(duration) - delayed_by;
    return (delay_adjusted_duration >= Duration.zero)
        ? delay_adjusted_duration
        : Duration.zero;
  }

  Duration EaseInOutBoundedSegmentDuration(
    final Offset new_delta,
    final Duration t,
    final Duration delayed_by,
  ) {
    final Offset old_delta = _target_value_ - _initial_value_;
    final double velocity = CalculateVelocity(t);

    // Use the velocity-based duration bound when it is less than the constant
    // segment duration. This minimizes the "rubber-band" bouncing effect when
    // |velocity| is large and |new_delta| is small.
    return minDuration(
      EaseInOutSegmentDuration(new_delta, _duration_behavior_!, delayed_by),
      VelocityBasedDurationBound(old_delta, velocity, new_delta),
    );
  }

  Duration SegmentDuration(
    final Offset delta,
    final Duration delayed_by, {
    final double? velocity,
  }) {
    switch (_animation_type_) {
      case AnimationType.kEaseInOut:
        assert(_duration_behavior_ != null);
        return EaseInOutSegmentDuration(
          delta,
          _duration_behavior_!,
          delayed_by,
        );
      case AnimationType.kLinear:
        assert(velocity != null);
        return LinearSegmentDuration(delta, delayed_by, velocity!);
      case AnimationType.kImpulse:
        return ImpulseSegmentDuration(delta, delayed_by);
    }
  }

  static Duration LinearSegmentDuration(
    final Offset delta,
    final Duration delayed_by,
    final double velocity,
  ) {
    final double duration_in_seconds =
        (_animation_duration_for_testing_ != null)
            ? _animation_duration_for_testing_!
            : (MaximumDimension(delta) / velocity).abs();
    final Duration delay_adjusted_duration =
        durationFromSeconds(duration_in_seconds) - delayed_by;
    return (delay_adjusted_duration >= Duration.zero)
        ? delay_adjusted_duration
        : Duration.zero;
  }

  static Duration ImpulseSegmentDuration(
    final Offset delta,
    final Duration delayed_by,
  ) {
    Duration duration;
    if (_animation_duration_for_testing_ != null) {
      duration = durationFromSeconds(_animation_duration_for_testing_!);
    } else {
      double duration_in_milliseconds =
          kImpulseMillisecondsPerPixel * MaximumDimension(delta).abs();
      duration_in_milliseconds = duration_in_milliseconds.clamp(
        kImpulseMinDurationMs,
        kImpulseMaxDurationMs,
      );
      duration = durationFromMilliseconds(duration_in_milliseconds);
    }

    duration -= delayed_by;
    return (duration >= Duration.zero) ? duration : Duration.zero;
  }

  void SetInitialValue(
    final Offset initial_value,
    final Duration delayed_by,
    final double velocity,
  ) {
    _initial_value_ = initial_value;
    _has_set_initial_value_ = true;

    final Offset delta = _target_value_ - initial_value;
    _total_animation_duration_ = SegmentDuration(
      delta,
      delayed_by,
      velocity: velocity,
    );
  }

  bool HasSetInitialValue() => _has_set_initial_value_;

  void ApplyAdjustment(final Offset adjustment) {
    _initial_value_ = _initial_value_ + adjustment;
    _target_value_ = _target_value_ + adjustment;
  }

  Offset GetValue(Duration t) {
    final Duration duration = _total_animation_duration_ - _last_retarget_;
    t -= _last_retarget_;

    if (duration == Duration.zero || (t >= duration)) {
      return _target_value_;
    }
    if (t <= Duration.zero) {
      return _initial_value_;
    }

    final double progress =
        _timing_function_.transform(t.inMicroseconds / duration.inMicroseconds);
    return Offset(
      lerpDouble(_initial_value_.dx, _target_value_.dx, progress)!,
      lerpDouble(_initial_value_.dy, _target_value_.dy, progress)!,
    );
  }

  Offset target_value() => _target_value_;

  Duration Duration_() => _total_animation_duration_;

  ScrollOffsetAnimationCurve Clone() => CloneToScrollOffsetAnimationCurve();

  ScrollOffsetAnimationCurve CloneToScrollOffsetAnimationCurve() =>
      ScrollOffsetAnimationCurve(
        targetValue: _target_value_,
        timingFunction: _timing_function_,
        animationType: _animation_type_,
        durationBehavior: _duration_behavior_,
      )
        .._initial_value_ = _initial_value_
        .._total_animation_duration_ = _total_animation_duration_
        .._last_retarget_ = _last_retarget_
        .._has_set_initial_value_ = _has_set_initial_value_;

  static void SetAnimationDurationForTesting(final Duration duration) {
    _animation_duration_for_testing_ = duration.InSecondsF();
  }

  double CalculateVelocity(final Duration t) {
    final Duration duration = _total_animation_duration_ - _last_retarget_;
    final double slope = _timing_function_
        .slope((t - _last_retarget_).inMicroseconds / duration.inMicroseconds);

    final Offset delta = _target_value_ - _initial_value_;

    // TimingFunction::Velocity just gives the slope of the curve. Convert it to
    // units of pixels per second.
    return slope * (MaximumDimension(delta) / duration.InSecondsF());
  }

  void UpdateTarget(Duration t, final Offset new_target) {
    assert(
      _animation_type_ != AnimationType.kLinear,
      'UpdateTarget is not supported on linear scroll animations.',
    );

    // UpdateTarget is still called for linear animations occasionally. This is
    // tracked via crbug.com/1164008.
    if (_animation_type_ == AnimationType.kLinear) {
      return;
    }

    // If the new UpdateTarget actually happened before the previous one, keep
    // |t| as the most recent, but reduce the duration of any generated
    // animation.
    final Duration delayed_by = maxDuration(Duration.zero, _last_retarget_ - t);
    t = maxDuration(t, _last_retarget_);

    if (_animation_type_ == AnimationType.kEaseInOut &&
        MaximumDimension(_target_value_ - new_target).abs() < kEpsilon) {
      // Don't update the animation if the new target is the same as the old one.
      // This is done for EaseInOut-style animation curves, since the duration is
      // inversely proportional to the distance, and it may cause an animation
      // that is longer than the one currently running.
      // Specifically avoid doing this for Impulse-style animation curves since
      // its duration is directly proportional to the distance, and we don't want
      // to drop user input.
      _target_value_ = new_target;
      return;
    }

    final Offset current_position = GetValue(t);
    final Offset new_delta = new_target - current_position;

    // We are already at or very close to the new target. Stop animating.
    if (MaximumDimension(new_delta).abs() < kEpsilon) {
      _last_retarget_ = t;
      _total_animation_duration_ = t;
      _target_value_ = new_target;
      return;
    }

    // The last segment was of zero duration.
    final Duration old_duration = _total_animation_duration_ - _last_retarget_;
    if (old_duration == Duration.zero) {
      assert(t == _last_retarget_);
      _total_animation_duration_ = SegmentDuration(new_delta, delayed_by);
      _target_value_ = new_target;
      return;
    }

    final Duration new_duration = (_animation_type_ == AnimationType.kEaseInOut)
        ? EaseInOutBoundedSegmentDuration(new_delta, t, delayed_by)
        : ImpulseSegmentDuration(new_delta, delayed_by);
    if (new_duration.InSecondsF() < kEpsilon) {
      // The duration is (close to) 0, so stop the animation.
      _target_value_ = new_target;
      _total_animation_duration_ = t;
      return;
    }

    // Adjust the slope of the new animation in order to preserve the velocity of
    // the old animation.
    final double velocity = CalculateVelocity(t);
    double new_slope =
        velocity * (new_duration.InSecondsF() / MaximumDimension(new_delta));

    if (_animation_type_ == AnimationType.kEaseInOut) {
      _timing_function_ = EaseInOutWithInitialSlope(new_slope);
    } else {
      assert(_animation_type_ == AnimationType.kImpulse);
      if (IsNewTargetInOppositeDirection(
        current_position,
        _target_value_,
        new_target,
      )) {
        // Prevent any rubber-banding by setting the velocity (and subsequently,
        // the slope) to 0 when moving in the opposite direciton.
        new_slope = 0;
      }
      _timing_function_ = ImpulseCurveWithInitialSlope(new_slope);
    }

    _initial_value_ = current_position;
    _target_value_ = new_target;
    _total_animation_duration_ = t + new_duration;
    _last_retarget_ = t;
  }
}
