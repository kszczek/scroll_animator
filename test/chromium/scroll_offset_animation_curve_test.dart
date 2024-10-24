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

// This library mirrors Chromium's ScrollOffsetAnimationCurveTest
// implementation to make it easier to integrate future changes from Chromium.
// Some linter rules are disabled to match Chromium's code style.
// Please avoid refactoring to keep the line-by-line similarity.
// ignore_for_file: cascade_invocations
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: omit_local_variable_types

// Based on revision 132.0.6793.1:
// https://source.chromium.org/chromium/chromium/src/+/refs/tags/132.0.6793.1:cc/animation/scroll_offset_animation_curve_unittest.cc

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_animator/src/chromium/scroll_offset_animation_curve.dart';
import 'package:scroll_animator/src/utils/duration.dart';

const double kConstantDuration = 9.0;
const double kDurationDivisor = 60.0;
const double kInverseDeltaMaxDuration = 12.0;

// This is the value of the default Impulse bezier curve when t = 0.5
const double halfway_through_default_impulse_curve = 0.874246;

double offsetMaximumDimensionDistance(final Offset a, final Offset b) {
  final double dx = (a.dx - b.dx).abs();
  final double dy = (a.dy - b.dy).abs();
  return max(dx, dy);
}

void main() {
  test('DeltaBasedDuration', () {
    const target_value = Offset(100.0, 200.0);
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: target_value,
      animationType: AnimationType.kEaseInOut,
      durationBehavior: DurationBehavior.kDeltaBased,
    );

    curve.SetInitialValue(target_value, Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.0));

    // x decreases, y stays the same.
    curve.SetInitialValue(const Offset(136.0, 200.0), Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.1));

    // x increases, y stays the same.
    curve.SetInitialValue(const Offset(19.0, 200.0), Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.15));

    // x stays the same, y decreases.
    curve.SetInitialValue(const Offset(100.0, 344.0), Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.2));

    // x stays the same, y increases.
    curve.SetInitialValue(const Offset(100.0, 191.0), Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.05));

    // x decreases, y decreases.
    curve.SetInitialValue(const Offset(32500.0, 500.0), Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.7));

    // x decreases, y increases.
    curve.SetInitialValue(const Offset(150.0, 119.0), Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.15));

    // x increases, y decreases.
    curve.SetInitialValue(const Offset(0.0, 14600.0), Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.7));

    // x increases, y increases.
    curve.SetInitialValue(const Offset(95.0, 191.0), Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), equals(0.05));
  });

  test('GetValue', () {
    const initial_value = Offset(2.0, 40.0);
    const target_value = Offset(10.0, 20.0);
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: target_value,
      animationType: AnimationType.kEaseInOut,
      durationBehavior: DurationBehavior.kDeltaBased,
    );
    curve.SetInitialValue(initial_value, Duration.zero, 0);

    final Duration duration = curve.Duration_();
    expect(curve.Duration_().InSecondsF(), greaterThan(0));
    expect(curve.Duration_().InSecondsF(), lessThan(0.1));

    expect(curve.Duration_(), equals(duration));

    expect(curve.GetValue(const Duration(seconds: -1)), equals(initial_value));
    expect(curve.GetValue(Duration.zero), equals(initial_value));
    expect(
      curve.GetValue(duration * 0.5),
      // TODO(kszczek): When implementing two-dimensional scroll support,
      // consider using offsetMoreOrLessEquals() instead.
      within(
        distance: 0.00025,
        from: const Offset(6.0, 30.0),
        distanceFunction: offsetMaximumDimensionDistance,
      ),
    );
    expect(curve.GetValue(duration), equals(target_value));
    expect(
      curve.GetValue(duration + const Duration(seconds: 1)),
      equals(target_value),
    );

    // Verify that GetValue takes the timing function into account.
    final Offset value = curve.GetValue(duration * 0.25);
    expect(value.dx, closeTo(3.0333, 0.0002));
    expect(value.dy, closeTo(37.4168, 0.0002));
  });

  // Verify that a clone behaves exactly like the original.
  test('Clone', () {
    const initial_value = Offset(2.0, 40.0);
    const target_value = Offset(10.0, 20.0);
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: target_value,
      animationType: AnimationType.kEaseInOut,
      durationBehavior: DurationBehavior.kDeltaBased,
    );
    curve.SetInitialValue(initial_value, Duration.zero, 0);
    final Duration duration = curve.Duration_();

    final ScrollOffsetAnimationCurve clone = curve.Clone();

    expect(clone.Duration_(), equals(duration));

    expect(clone.GetValue(const Duration(seconds: -1)), equals(initial_value));
    expect(clone.GetValue(Duration.zero), equals(initial_value));
    expect(
      clone.GetValue(duration * 0.5),
      within(
        distance: 0.00025,
        from: const Offset(6.0, 30.0),
        distanceFunction: offsetMaximumDimensionDistance,
      ),
    );
    expect(clone.GetValue(duration), equals(target_value));
    expect(
      clone.GetValue(duration + const Duration(seconds: 1)),
      equals(target_value),
    );

    // Verify that the timing function was cloned correctly.
    final Offset value = clone.GetValue(duration * 0.25);
    expect(value.dx, closeTo(3.0333, 0.0002));
    expect(value.dy, closeTo(37.4168, 0.0002));
  });

  test('EaseInOutUpdateTarget', () {
    const initial_value = Offset.zero;
    const target_value = Offset(0.0, 3600.0);
    const double duration = kConstantDuration / kDurationDivisor;
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: target_value,
      animationType: AnimationType.kEaseInOut,
      durationBehavior: DurationBehavior.kConstant,
    );
    curve.SetInitialValue(initial_value, Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), closeTo(duration, 0.0002));
    expect(
      curve.GetValue(durationFromSeconds(duration / 2.0)).dy,
      closeTo(1800.0, 0.0002),
    );
    expect(
      curve.GetValue(durationFromSeconds(duration)).dy,
      closeTo(3600.0, 0.0002),
    );

    curve.UpdateTarget(
      durationFromSeconds(duration / 2),
      const Offset(0.0, 9900.0),
    );

    expect(curve.Duration_().InSecondsF(), closeTo(duration * 1.5, 0.0002));
    expect(
      curve.GetValue(durationFromSeconds(duration / 2.0)).dy,
      closeTo(1800.0, 0.0002),
    );
    expect(
      curve.GetValue(durationFromSeconds(duration)).dy,
      closeTo(6827.6, 0.1),
    );
    expect(
      curve.GetValue(durationFromSeconds(duration * 1.5)).dy,
      closeTo(9900.0, 0.0002),
    );

    curve.UpdateTarget(
      durationFromSeconds(duration),
      const Offset(0.0, 7200.0),
    );

    // A closer target at high velocity reduces the duration.
    expect(curve.Duration_().InSecondsF(), closeTo(duration * 1.0794, 0.0002));
    expect(
      curve.GetValue(durationFromSeconds(duration)).dy,
      closeTo(6827.6, 0.1),
    );
    expect(
      curve.GetValue(durationFromSeconds(duration * 1.08)).dy,
      closeTo(7200.0, 0.0002),
    );
  });

  test('ImpulseUpdateTarget', () {
    const initial_value = Offset.zero;
    const initial_target_value = Offset(0.0, 3600.0);
    final Offset initial_delta = initial_target_value - initial_value;
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: initial_target_value,
      animationType: AnimationType.kImpulse,
    );
    curve.SetInitialValue(initial_value, Duration.zero, 0);

    final Duration initial_duration =
        ScrollOffsetAnimationCurve.ImpulseSegmentDuration(
      initial_delta,
      Duration.zero,
    );
    expect(
      curve.Duration_().InSecondsF(),
      closeTo(initial_duration.InSecondsF(), 0.0002),
    );
    expect(
      curve.GetValue(initial_duration ~/ 2).dy,
      closeTo(initial_delta.dy * halfway_through_default_impulse_curve, 0.01),
    );
    expect(
      curve.GetValue(initial_duration).dy,
      closeTo(initial_delta.dy, 0.0002),
    );

    final Duration time_of_update = initial_duration ~/ 2;
    final Offset distance_halfway_through_initial_animation =
        curve.GetValue(time_of_update);

    const new_target_value = Offset(0.0, 9900.0);
    curve.UpdateTarget(time_of_update, new_target_value);

    final Offset new_delta =
        new_target_value - distance_halfway_through_initial_animation;
    final Duration updated_segment_duration =
        ScrollOffsetAnimationCurve.ImpulseSegmentDuration(
      new_delta,
      Duration.zero,
    );

    final Duration overall_duration = time_of_update + updated_segment_duration;
    expect(
      curve.Duration_().InSecondsF(),
      closeTo(overall_duration.InSecondsF(), 0.0002),
    );
    expect(
      curve.GetValue(time_of_update).dy,
      closeTo(distance_halfway_through_initial_animation.dy, 0.01),
    );
    expect(
      curve.GetValue(overall_duration).dy,
      closeTo(new_target_value.dy, 0.0002),
    );

    // Ensure that UpdateTarget increases the initial slope of the generated curve
    // (for velocity matching). To test this, we check if the value is greater
    // than the default value would be half way through.
    // Also - to ensure it isn't passing just due to floating point imprecision,
    // some epsilon is added to the default amount.
    expect(
      curve.GetValue(time_of_update + (updated_segment_duration ~/ 2)).dy,
      greaterThan(
        new_delta.dy * halfway_through_default_impulse_curve + 0.01,
      ),
    );
  });

  test('ImpulseUpdateTargetSwitchDirections', () {
    const initial_value = Offset.zero;
    const initial_target_value = Offset(0.0, 200.0);
    final double initial_duration =
        ScrollOffsetAnimationCurve.ImpulseSegmentDuration(
      initial_target_value,
      Duration.zero,
    ).InSecondsF();

    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: initial_target_value,
      animationType: AnimationType.kImpulse,
    );
    curve.SetInitialValue(initial_value, Duration.zero, 0);
    expect(curve.Duration_().InSecondsF(), closeTo(initial_duration, 0.0002));
    expect(
      curve.GetValue(durationFromSeconds(initial_duration / 2.0)).dy,
      closeTo(
        initial_target_value.dy * halfway_through_default_impulse_curve,
        0.01,
      ),
    );

    // Animate back to 0. This should force the new curve's initial velocity to be
    // 0, so the default curve will be generated.
    final Offset updated_initial_value = Offset(
      0,
      initial_target_value.dy * halfway_through_default_impulse_curve,
    );
    const updated_target = Offset.zero;
    curve.UpdateTarget(
      durationFromSeconds(initial_duration / 2),
      updated_target,
    );

    expect(
      curve.GetValue(durationFromSeconds(initial_duration / 2.0)).dy,
      closeTo(
        initial_target_value.dy * halfway_through_default_impulse_curve,
        0.01,
      ),
    );

    final double updated_duration =
        ScrollOffsetAnimationCurve.ImpulseSegmentDuration(
      updated_initial_value,
      Duration.zero,
    ).InSecondsF();
    expect(
      curve.GetValue(
        durationFromSeconds(initial_duration / 2.0 + updated_duration / 2.0),
      ).dy,
      closeTo(
        updated_initial_value.dy *
            (1.0 - halfway_through_default_impulse_curve),
        0.01,
      ),
    );
    expect(
      curve.GetValue(
        durationFromSeconds(initial_duration / 2.0 + updated_duration),
      ).dy,
      closeTo(0.0, 0.0002),
    );
  });

  test('InverseDeltaDuration', () {
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: const Offset(0.0, 100.0),
      animationType: AnimationType.kEaseInOut,
      durationBehavior: DurationBehavior.kInverseDelta,
    );

    curve.SetInitialValue(Offset.zero, Duration.zero, 0);
    final double smallDeltaDuration = curve.Duration_().InSecondsF();

    curve.UpdateTarget(durationFromSeconds(0.01), const Offset(0.0, 300.0));
    final double mediumDeltaDuration = curve.Duration_().InSecondsF();

    curve.UpdateTarget(durationFromSeconds(0.01), const Offset(0.0, 500.0));
    final double largeDeltaDuration = curve.Duration_().InSecondsF();

    expect(smallDeltaDuration, greaterThan(mediumDeltaDuration));
    expect(mediumDeltaDuration, greaterThan(largeDeltaDuration));

    curve.UpdateTarget(durationFromSeconds(0.01), const Offset(0.0, 5000.0));
    expect(curve.Duration_().InSecondsF(), equals(largeDeltaDuration));
  });

  test('LinearAnimation', () {
    // Testing autoscroll downwards for a scroller of length 1000px.
    Offset current_offset = Offset.zero;
    const target_offset = Offset(0.0, 1000.0);
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: target_offset,
      animationType: AnimationType.kLinear,
    );

    const double autoscroll_velocity = 800.0; // pixels per second.
    curve.SetInitialValue(current_offset, Duration.zero, autoscroll_velocity);
    expect(curve.Duration_().InSecondsF(), equals(1.25));

    // Test scrolling down from half way.
    current_offset = const Offset(0.0, 500.0);
    curve.SetInitialValue(current_offset, Duration.zero, autoscroll_velocity);
    expect(curve.Duration_().InSecondsF(), equals(0.625));

    // Test scrolling down when max_offset is reached.
    current_offset = const Offset(0.0, 1000.0);
    curve.SetInitialValue(current_offset, Duration.zero, autoscroll_velocity);
    expect(curve.Duration_().InSecondsF(), equals(0.0));
  });

  test('ImpulseDuration', () {
    // The duration of an impulse-style curve in milliseconds is simply 1.5x the
    // scroll distance in physical pixels, with a minimum of 200ms and a maximum
    // of 500ms.
    const small_delta = Offset(0.0, 100.0);
    const moderate_delta = Offset(0.0, 250.0);
    const large_delta = Offset(0.0, 400.0);

    Duration duration = ScrollOffsetAnimationCurve.ImpulseSegmentDuration(
      small_delta,
      Duration.zero,
    );
    expect(duration.InMillisecondsF(), equals(200.0));

    duration = ScrollOffsetAnimationCurve.ImpulseSegmentDuration(
      moderate_delta,
      Duration.zero,
    );
    expect(
      duration.InMillisecondsF(),
      closeTo(moderate_delta.dy * 1.5, 0.0002),
    );

    duration = ScrollOffsetAnimationCurve.ImpulseSegmentDuration(
      large_delta,
      Duration.zero,
    );
    expect(duration.InMillisecondsF(), equals(500.0));
  });

  test('CurveWithDelay', () {
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: const Offset(0.0, 100.0),
      animationType: AnimationType.kEaseInOut,
      durationBehavior: DurationBehavior.kInverseDelta,
    );
    const double duration_in_seconds =
        kInverseDeltaMaxDuration / kDurationDivisor;
    const double delay_in_seconds = 0.02;
    const double curve_duration = duration_in_seconds - delay_in_seconds;

    curve.SetInitialValue(
      Offset.zero,
      durationFromSeconds(delay_in_seconds),
      0,
    );
    expect(curve.Duration_().InSecondsF(), closeTo(curve_duration, 0.0002));

    curve.UpdateTarget(durationFromSeconds(0.01), const Offset(0.0, 500.0));
    expect(curve.Duration_().InSecondsF(), lessThan(curve_duration));
    expect(curve.target_value(), equals(const Offset(0.0, 500.0)));
  });

  test('CurveWithLargeDelay', () {
    const duration_hint = DurationBehavior.kInverseDelta;
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: const Offset(0.0, 100.0),
      animationType: AnimationType.kEaseInOut,
      durationBehavior: duration_hint,
    );
    curve.SetInitialValue(Offset.zero, durationFromSeconds(0.2), 0);
    expect(curve.Duration_().InSecondsF(), equals(0.0));

    // Re-targeting when animation duration is 0.
    curve.UpdateTarget(durationFromSeconds(-0.01), const Offset(0.0, 300.0));
    double duration = ScrollOffsetAnimationCurve.EaseInOutSegmentDuration(
      const Offset(0.0, 200.0),
      duration_hint,
      durationFromSeconds(0.01),
    ).InSecondsF();
    expect(curve.Duration_().InSecondsF(), equals(duration));

    // Re-targeting before last_retarget_, the  difference should be accounted for
    // in duration.
    curve.UpdateTarget(durationFromSeconds(-0.01), const Offset(0.0, 500.0));
    duration = ScrollOffsetAnimationCurve.EaseInOutSegmentDuration(
      const Offset(0.0, 500.0),
      duration_hint,
      durationFromSeconds(0.01),
    ).InSecondsF();
    expect(curve.Duration_().InSecondsF(), equals(duration));

    expect(
      curve.GetValue(durationFromSeconds(1.0)),
      equals(const Offset(0.0, 500.0)),
    );
  });

  // This test verifies that if the last segment duration is zero, UpdateTarget
  // simply updates the total animation duration see crbug.com/645317.
  test('UpdateTargetZeroLastSegmentDuration', () {
    const duration_hint = DurationBehavior.kInverseDelta;
    final curve = ScrollOffsetAnimationCurve.withDefaultTimingFunction(
      targetValue: const Offset(0.0, 100.0),
      animationType: AnimationType.kEaseInOut,
      durationBehavior: duration_hint,
    );
    const double duration_in_seconds =
        kInverseDeltaMaxDuration / kDurationDivisor;
    const double delay_in_seconds = 0.02;
    const double curve_duration = duration_in_seconds - delay_in_seconds;

    curve.SetInitialValue(
      Offset.zero,
      durationFromSeconds(delay_in_seconds),
      0,
    );
    expect(curve.Duration_().InSecondsF(), closeTo(curve_duration, 0.0002));

    // Re-target 1, this should set _last_retarget_ to 0.05.
    Offset new_delta =
        const Offset(0.0, 200.0) - curve.GetValue(durationFromSeconds(0.05));
    double expected_duration =
        ScrollOffsetAnimationCurve.EaseInOutSegmentDuration(
              new_delta,
              duration_hint,
              Duration.zero,
            ).InSecondsF() +
            0.05;
    curve.UpdateTarget(durationFromSeconds(0.05), const Offset(0.0, 200.0));
    expect(curve.Duration_().InSecondsF(), closeTo(expected_duration, 0.0002));

    // Re-target 2, this should set _total_animation_duration_ to t, which is
    // _last_retarget_. This is what would cause the assertion failure in
    // crbug.com/645317.
    curve.UpdateTarget(durationFromSeconds(-0.145), const Offset(0.0, 300.0));
    expect(curve.Duration_().InSecondsF(), closeTo(0.05, 0.0002));

    // Re-target 3, this should set _total_animation_duration_ based on new_delta.
    new_delta =
        const Offset(0.0, 500.0) - curve.GetValue(durationFromSeconds(0.05));
    expected_duration = ScrollOffsetAnimationCurve.EaseInOutSegmentDuration(
      new_delta,
      duration_hint,
      durationFromSeconds(0.15),
    ).InSecondsF();
    curve.UpdateTarget(durationFromSeconds(-0.1), const Offset(0.0, 500.0));
    expect(curve.Duration_().InSecondsF(), closeTo(expected_duration, 0.0002));
  });
}
