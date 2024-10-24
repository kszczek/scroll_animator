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

// This library mirrors Chromium's CubicBezier implementation
// to make it easier to integrate future changes from Chromium.
// Some linter rules are disabled to match Chromium's code style.
// Please avoid refactoring to keep the line-by-line similarity.
// ignore_for_file: constant_identifier_names
// ignore_for_file: flutter_style_todos
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: omit_local_variable_types
// ignore_for_file: parameter_assignments
// ignore_for_file: prefer_asserts_with_message
// ignore_for_file: public_member_api_docs

// Based on revision 132.0.6793.1:
// https://source.chromium.org/chromium/chromium/src/+/refs/tags/132.0.6793.1:ui/gfx/geometry/cubic_bezier.cc

import 'dart:math';

const int kCubicBezierSplineSamples = 11;
const int kMaxNewtonIterations = 4;
const double kBezierEpsilon = 1e-7;

class CubicBezier {
  CubicBezier(
    final double p1x,
    final double p1y,
    final double p2x,
    final double p2y,
  ) {
    _InitCoefficients(p1x, p1y, p2x, p2y);
    _InitGradients(p1x, p1y, p2x, p2y);
    _InitRange(p1y, p2y);
    _InitSpline();
  }

  late final double _ax_;
  late final double _bx_;
  late final double _cx_;

  late final double _ay_;
  late final double _by_;
  late final double _cy_;

  late final double _start_gradient_;
  late final double _end_gradient_;

  late double _range_min_;
  late double _range_max_;

  late final List<double> _spline_samples_;

  // Guard against attempted to solve for t given x in the event that the curve
  // may have multiple values for t for some values of x in [0, 1].
  late final bool _monotonically_increasing_;

  // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
  // The x values are in the range [0, 1]. So it isn't needed toFinite
  // clamping.
  // https://drafts.csswg.org/css-easing-1/#funcdef-cubic-bezier-easing-function-cubic-bezier
  double SampleCurveX(final double t) => ((_ax_ * t + _bx_) * t + _cx_) * t;

  double SampleCurveY(final double t) =>
      _ToFinite(((_ay_ * t + _by_) * t + _cy_) * t);

  double SampleCurveDerivativeX(final double t) =>
      (3.0 * _ax_ * t + 2.0 * _bx_) * t + _cx_;

  double SampleCurveDerivativeY(final double t) => _ToFinite(
        _ToFinite(_ToFinite(3.0 * _ay_) * t + _ToFinite(2.0 * _by_)) * t + _cy_,
      );

  static double GetDefaultEpsilon() => kBezierEpsilon;

  // Given an x value, find a parametric value it came from.
  // x must be in [0, 1] range. Doesn't use gradients.
  double SolveCurveX(final double x, final double epsilon) {
    assert(x >= 0.0 && x <= 1.0);
    assert(_monotonically_increasing_);

    double t0 = 0.0;
    double t1 = 0.0;
    double t2 = x;
    double x2 = 0.0;
    double d2 = 0.0;
    int i;

    // Linear interpolation of spline curve for initial guess.
    const double delta_t = 1.0 / (kCubicBezierSplineSamples - 1);
    for (i = 1; i < kCubicBezierSplineSamples; i++) {
      if (x <= _spline_samples_[i]) {
        t1 = delta_t * i;
        t0 = t1 - delta_t;
        t2 = t0 +
            (t1 - t0) *
                (x - _spline_samples_[i - 1]) /
                (_spline_samples_[i] - _spline_samples_[i - 1]);
        break;
      }
    }

    // Perform a few iterations of Newton's method -- normally very fast.
    // See https://en.wikipedia.org/wiki/Newton%27s_method.
    final double newton_epsilon = min(kBezierEpsilon, epsilon);
    for (i = 0; i < kMaxNewtonIterations; i++) {
      x2 = SampleCurveX(t2) - x;
      if (x2.abs() < newton_epsilon) {
        return t2;
      }
      d2 = SampleCurveDerivativeX(t2);
      if (d2.abs() < kBezierEpsilon) {
        break;
      }
      t2 = t2 - x2 / d2;
    }
    if (x2.abs() < epsilon) {
      return t2;
    }

    // Fall back to the bisection method for reliability.
    while (t0 < t1) {
      x2 = SampleCurveX(t2);
      if ((x2 - x).abs() < epsilon) {
        return t2;
      }
      if (x > x2) {
        t0 = t2;
      } else {
        t1 = t2;
      }
      t2 = (t1 + t0) * .5;
    }

    // Failure.
    return t2;
  }

  // Evaluates y at the given x with default epsilon.
  double Solve(final double x) => SolveWithEpsilon(x, kBezierEpsilon);

  // Evaluates y at the given x. The epsilon parameter provides a hint as to the
  // required accuracy and is not guaranteed. Uses gradients if x is
  // out of [0, 1] range.
  double SolveWithEpsilon(final double x, final double epsilon) {
    if (x < 0.0) {
      return _ToFinite(0.0 + _start_gradient_ * x);
    }
    if (x > 1.0) {
      return _ToFinite(1.0 + _end_gradient_ * (x - 1.0));
    }
    return SampleCurveY(SolveCurveX(x, epsilon));
  }

  // Returns an approximation of dy/dx at the given x with default epsilon.
  double Slope(final double x) => SlopeWithEpsilon(x, kBezierEpsilon);

  // Returns an approximation of dy/dx at the given x.
  // Clamps x to range [0, 1].
  double SlopeWithEpsilon(double x, final double epsilon) {
    x = x.clamp(0.0, 1.0);
    final double t = SolveCurveX(x, epsilon);
    final double dx = SampleCurveDerivativeX(t);
    final double dy = SampleCurveDerivativeY(t);
    // TODO(crbug.com/40207101): We should clamp NaN to a proper value.
    // Please see the issue for detail.
    if (dx == 0.0 && dy == 0.0) {
      return 0;
    }
    return _ToFinite(dy / dx);
  }

  // These getters are used rarely. We reverse compute them from coefficients.
  // See CubicBezier.InitCoefficients. The speed has been traded for memory.
  double GetX1() => _cx_ / 3.0;
  double GetY1() => _cy_ / 3.0;
  double GetX2() => (_bx_ + _cx_) / 3.0 + GetX1();
  double GetY2() => (_by_ + _cy_) / 3.0 + GetY1();

  // Gets the bezier's minimum y value in the interval [0, 1].
  double range_min() => _range_min_;

  // Gets the bezier's maximum y value in the interval [0, 1].
  double range_max() => _range_max_;

  void _InitCoefficients(
    final double p1x,
    final double p1y,
    final double p2x,
    final double p2y,
  ) {
    // Calculate the polynomial coefficients, implicit first and last control
    // points are (0,0) and (1,1).
    _cx_ = 3.0 * p1x;
    _bx_ = 3.0 * (p2x - p1x) - _cx_;
    _ax_ = 1.0 - _cx_ - _bx_;

    _cy_ = _ToFinite(3.0 * p1y);
    _by_ = _ToFinite(3.0 * (p2y - p1y) - _cy_);
    _ay_ = _ToFinite(1.0 - _cy_ - _by_);

    // Bezier curves with x-coordinates outside the range [0,1] for internal
    // control points may have multiple values for t for a given value of x.
    // In this case, calls to SolveCurveX may produce ambiguous results.
    _monotonically_increasing_ = p1x >= 0 && p1x <= 1 && p2x >= 0 && p2x <= 1;
  }

  void _InitGradients(
    final double p1x,
    final double p1y,
    final double p2x,
    final double p2y,
  ) {
    // End-point gradients are used to calculate timing function results
    // outside the range [0, 1].
    //
    // There are four possibilities for the gradient at each end:
    // (1) the closest control point is not horizontally coincident with regard
    //     to (0, 0) or (1, 1). In this case the line between the end point and
    //     the control point is tangent to the bezier at the end point.
    // (2) the closest control point is coincident with the end point. In
    //     this case the line between the end point and the far control
    //     point is tangent to the bezier at the end point.
    // (3) both internal control points are coincident with an endpoint. There
    //     are two special case that fall into this category:
    //     CubicBezier(0, 0, 0, 0) and CubicBezier(1, 1, 1, 1). Both are
    //     equivalent to linear.
    // (4) the closest control point is horizontally coincident with the end
    //     point, but vertically distinct. In this case the gradient at the
    //     end point is Infinite. However, this causes issues when
    //     interpolating. As a result, we break down to a simple case of
    //     0 gradient under these conditions.

    if (p1x > 0) {
      _start_gradient_ = p1y / p1x;
    } else if (p1y == 0 && p2x > 0) {
      _start_gradient_ = p2y / p2x;
    } else if (p1y == 0 && p2y == 0) {
      _start_gradient_ = 1;
    } else {
      _start_gradient_ = 0;
    }

    if (p2x < 1) {
      _end_gradient_ = (p2y - 1) / (p2x - 1);
    } else if (p2y == 1 && p1x < 1) {
      _end_gradient_ = (p1y - 1) / (p1x - 1);
    } else if (p2y == 1 && p1y == 1) {
      _end_gradient_ = 1;
    } else {
      _end_gradient_ = 0;
    }
  }

  // This works by taking taking the derivative of the cubic bezier, on the y
  // axis. We can then solve for where the derivative is zero to find the min
  // and max distance along the line. We the have to solve those in terms of
  // time rather than distance on the x-axis
  void _InitRange(final double p1y, final double p2y) {
    _range_min_ = 0;
    _range_max_ = 1;
    if (0 <= p1y && p1y < 1 && 0 <= p2y && p2y <= 1) {
      return;
    }

    const double epsilon = kBezierEpsilon;

    // Represent the function's derivative in the form at^2 + bt + c
    // as in sampleCurveDerivativeY.
    // (Technically this is (dy/dt)*(1/3), which is suitable for finding zeros
    // but does not actually give the slope of the curve.)
    final double a = 3.0 * _ay_;
    final double b = 2.0 * _by_;
    final double c = _cy_;

    // Check if the derivative is constant.
    if (a.abs() < epsilon && b.abs() < epsilon) {
      return;
    }

    // Zeros of the function's derivative.
    double t1 = 0;
    double t2 = 0;

    if (a.abs() < epsilon) {
      // The function's derivative is linear.
      t1 = -c / b;
    } else {
      // The function's derivative is a quadratic. We find the zeros of this
      // quadratic using the quadratic formula.
      final double discriminant = b * b - 4 * a * c;
      if (discriminant < 0) {
        return;
      }
      final double discriminant_sqrt = sqrt(discriminant);
      t1 = (-b + discriminant_sqrt) / (2 * a);
      t2 = (-b - discriminant_sqrt) / (2 * a);
    }

    double sol1 = 0;
    double sol2 = 0;

    // If the solution is in the range [0,1] then we include it, otherwise we
    // ignore it.

    // An interesting fact about these beziers is that they are only
    // actually evaluated in [0,1]. After that we take the tangent at that point
    // and linearly project it out.
    if (0 < t1 && t1 < 1) {
      sol1 = SampleCurveY(t1);
    }

    if (0 < t2 && t2 < 1) {
      sol2 = SampleCurveY(t2);
    }

    _range_min_ = min(_range_min_, min(sol1, sol2));
    _range_max_ = max(_range_max_, max(sol1, sol2));
  }

  void _InitSpline() {
    const double delta_t = 1.0 / (kCubicBezierSplineSamples - 1);
    _spline_samples_ = List.generate(
      kCubicBezierSplineSamples,
      (final i) => SampleCurveX(i * delta_t),
      growable: false,
    );
  }

  static double _ToFinite(final double value) {
    // TODO(crbug.com/40808348): We can clamp this in numeric operation helper
    // function like ClampedNumeric.
    if (value.isInfinite) {
      if (value > 0) {
        return double.maxFinite;
      }
      return -double.maxFinite;
    }
    return value;
  }
}
