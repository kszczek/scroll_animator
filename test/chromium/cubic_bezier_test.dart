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

// This library mirrors Chromium's CubicBezierTest implementation
// to make it easier to integrate future changes from Chromium.
// Some linter rules are disabled to match Chromium's code style.
// Please avoid refactoring to keep the line-by-line similarity.
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_parenthesis

// Based on revision 132.0.6793.1:
// https://source.chromium.org/chromium/chromium/src/+/refs/tags/132.0.6793.1:ui/gfx/geometry/cubic_bezier_unittest.cc

import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_animator/src/chromium/cubic_bezier.dart';

void main() {
  test('Basic', () {
    final CubicBezier function = CubicBezier(0.25, 0.0, 0.75, 1.0);

    const double epsilon = 0.00015;

    expect(function.Solve(0), closeTo(0, epsilon));
    expect(function.Solve(0.05), closeTo(0.01136, epsilon));
    expect(function.Solve(0.1), closeTo(0.03978, epsilon));
    expect(function.Solve(0.15), closeTo(0.079780, epsilon));
    expect(function.Solve(0.2), closeTo(0.12803, epsilon));
    expect(function.Solve(0.25), closeTo(0.18235, epsilon));
    expect(function.Solve(0.3), closeTo(0.24115, epsilon));
    expect(function.Solve(0.35), closeTo(0.30323, epsilon));
    expect(function.Solve(0.4), closeTo(0.36761, epsilon));
    expect(function.Solve(0.45), closeTo(0.43345, epsilon));
    expect(function.Solve(0.5), closeTo(0.5, epsilon));
    expect(function.Solve(0.6), closeTo(0.63238, epsilon));
    expect(function.Solve(0.65), closeTo(0.69676, epsilon));
    expect(function.Solve(0.7), closeTo(0.75884, epsilon));
    expect(function.Solve(0.75), closeTo(0.81764, epsilon));
    expect(function.Solve(0.8), closeTo(0.87196, epsilon));
    expect(function.Solve(0.85), closeTo(0.92021, epsilon));
    expect(function.Solve(0.9), closeTo(0.96021, epsilon));
    expect(function.Solve(0.95), closeTo(0.98863, epsilon));
    expect(function.Solve(1), closeTo(1, epsilon));

    final CubicBezier basic_use = CubicBezier(0.5, 1.0, 0.5, 1.0);
    expect(basic_use.Solve(0.5), equals(0.875));

    final CubicBezier overshoot = CubicBezier(0.5, 2.0, 0.5, 2.0);
    expect(overshoot.Solve(0.5), equals(1.625));

    final CubicBezier undershoot = CubicBezier(0.5, -1.0, 0.5, -1.0);
    expect(undershoot.Solve(0.5), equals(-0.625));
  });

  // Tests that solving the bezier works with knots with y not in (0, 1).
  test('UnclampedYValues', () {
    final CubicBezier function = CubicBezier(0.5, -1.0, 0.5, 2.0);

    const double epsilon = 0.00015;

    expect(function.Solve(0.0), closeTo(0.0, epsilon));
    expect(function.Solve(0.05), closeTo(-0.08954, epsilon));
    expect(function.Solve(0.1), closeTo(-0.15613, epsilon));
    expect(function.Solve(0.15), closeTo(-0.19641, epsilon));
    expect(function.Solve(0.2), closeTo(-0.20651, epsilon));
    expect(function.Solve(0.25), closeTo(-0.18232, epsilon));
    expect(function.Solve(0.3), closeTo(-0.11992, epsilon));
    expect(function.Solve(0.35), closeTo(-0.01672, epsilon));
    expect(function.Solve(0.4), closeTo(0.12660, epsilon));
    expect(function.Solve(0.45), closeTo(0.30349, epsilon));
    expect(function.Solve(0.5), closeTo(0.50000, epsilon));
    expect(function.Solve(0.55), closeTo(0.69651, epsilon));
    expect(function.Solve(0.6), closeTo(0.87340, epsilon));
    expect(function.Solve(0.65), closeTo(1.01672, epsilon));
    expect(function.Solve(0.7), closeTo(1.11992, epsilon));
    expect(function.Solve(0.75), closeTo(1.18232, epsilon));
    expect(function.Solve(0.8), closeTo(1.20651, epsilon));
    expect(function.Solve(0.85), closeTo(1.19641, epsilon));
    expect(function.Solve(0.9), closeTo(1.15613, epsilon));
    expect(function.Solve(0.95), closeTo(1.08954, epsilon));
    expect(function.Solve(1.0), closeTo(1.0, epsilon));
  });

  void TestBezierFiniteRange(final CubicBezier function) {
    for (double i = 0; i <= 1.01; i += 0.05) {
      expect(function.Solve(i).isFinite, isTrue);
      expect(function.Slope(i).isFinite, isTrue);
      expect(function.GetX2().isFinite, isTrue);
      expect(function.GetY2().isFinite, isTrue);
      expect(function.SampleCurveX(i).isFinite, isTrue);
      expect(function.SampleCurveY(i).isFinite, isTrue);
      expect(function.SampleCurveDerivativeX(i).isFinite, isTrue);
      expect(function.SampleCurveDerivativeY(i).isFinite, isTrue);
    }
  }

  // Tests that solving the bezier works with huge value infinity evaluation
  test('ClampInfinityEvaluation', () {
    [
      CubicBezier(0.5, double.maxFinite, 0.5, double.maxFinite),
      CubicBezier(0.5, -double.maxFinite, 0.5, double.maxFinite),
      CubicBezier(0.5, double.maxFinite, 0.5, -double.maxFinite),
      CubicBezier(0.5, -double.maxFinite, 0.5, -double.maxFinite),
      CubicBezier(0, double.maxFinite, 0, double.maxFinite),
      CubicBezier(0, -double.maxFinite, 0, double.maxFinite),
      CubicBezier(0, double.maxFinite, 0, -double.maxFinite),
      CubicBezier(0, -double.maxFinite, 0, -double.maxFinite),
      CubicBezier(1, double.maxFinite, 1, double.maxFinite),
      CubicBezier(1, -double.maxFinite, 1, double.maxFinite),
      CubicBezier(1, double.maxFinite, 1, -double.maxFinite),
      CubicBezier(1, -double.maxFinite, 1, -double.maxFinite),
      CubicBezier(0, 0, 0, double.maxFinite),
      CubicBezier(0, -double.maxFinite, 0, 0),
      CubicBezier(1, 0, 0, -double.maxFinite),
      CubicBezier(0, -double.maxFinite, 1, 1),
    ].forEach(TestBezierFiniteRange);
  });

  test('Range', () {
    const double epsilon = 0.00015;

    // Derivative is a constant.
    CubicBezier function = CubicBezier(0.25, (1.0 / 3.0), 0.75, (2.0 / 3.0));
    expect(function.range_min(), equals(0));
    expect(function.range_max(), equals(1));

    // Derivative is linear.
    function = CubicBezier(0.25, -0.5, 0.75, (-1.0 / 6.0));
    expect(function.range_min(), closeTo(-0.225, epsilon));
    expect(function.range_max(), equals(1));

    // Derivative has no real roots.
    function = CubicBezier(0.25, 0.25, 0.75, 0.5);
    expect(function.range_min(), equals(0));
    expect(function.range_max(), equals(1));

    // Derivative has exactly one real root.
    function = CubicBezier(0.0, 1.0, 1.0, 0.0);
    expect(function.range_min(), equals(0));
    expect(function.range_max(), equals(1));

    // Derivative has one root < 0 and one root > 1.
    function = CubicBezier(0.25, 0.1, 0.75, 0.9);
    expect(function.range_min(), equals(0));
    expect(function.range_max(), equals(1));

    // Derivative has two roots in [0,1].
    function = CubicBezier(0.25, 2.5, 0.75, 0.5);
    expect(function.range_min(), equals(0));
    expect(function.range_max(), closeTo(1.28818, epsilon));
    function = CubicBezier(0.25, 0.5, 0.75, -1.5);
    expect(function.range_min(), closeTo(-0.28818, epsilon));
    expect(function.range_max(), equals(1));

    // Derivative has one root < 0 and one root in [0,1].
    function = CubicBezier(0.25, 0.1, 0.75, 1.5);
    expect(function.range_min(), equals(0));
    expect(function.range_max(), closeTo(1.10755, epsilon));

    // Derivative has one root in [0,1] and one root > 1.
    function = CubicBezier(0.25, -0.5, 0.75, 0.9);
    expect(function.range_min(), closeTo(-0.10755, epsilon));
    expect(function.range_max(), equals(1));

    // Derivative has two roots < 0.
    function = CubicBezier(0.25, 0.3, 0.75, 0.633);
    expect(function.range_min(), equals(0));
    expect(function.range_max(), equals(1));

    // Derivative has two roots > 1.
    function = CubicBezier(0.25, 0.367, 0.75, 0.7);
    expect(function.range_min(), equals(0.0));
    expect(function.range_max(), equals(1.0));
  });

  test('Slope', () {
    final CubicBezier function = CubicBezier(0.25, 0.0, 0.75, 1.0);

    const double epsilon = 0.00015;

    expect(function.Slope(-0.1), closeTo(0, epsilon));
    expect(function.Slope(0), closeTo(0, epsilon));
    expect(function.Slope(0.05), closeTo(0.42170, epsilon));
    expect(function.Slope(0.1), closeTo(0.69778, epsilon));
    expect(function.Slope(0.15), closeTo(0.89121, epsilon));
    expect(function.Slope(0.2), closeTo(1.03184, epsilon));
    expect(function.Slope(0.25), closeTo(1.13576, epsilon));
    expect(function.Slope(0.3), closeTo(1.21239, epsilon));
    expect(function.Slope(0.35), closeTo(1.26751, epsilon));
    expect(function.Slope(0.4), closeTo(1.30474, epsilon));
    expect(function.Slope(0.45), closeTo(1.32628, epsilon));
    expect(function.Slope(0.5), closeTo(1.33333, epsilon));
    expect(function.Slope(0.55), closeTo(1.32628, epsilon));
    expect(function.Slope(0.6), closeTo(1.30474, epsilon));
    expect(function.Slope(0.65), closeTo(1.26751, epsilon));
    expect(function.Slope(0.7), closeTo(1.21239, epsilon));
    expect(function.Slope(0.75), closeTo(1.13576, epsilon));
    expect(function.Slope(0.8), closeTo(1.03184, epsilon));
    expect(function.Slope(0.85), closeTo(0.89121, epsilon));
    expect(function.Slope(0.9), closeTo(0.69778, epsilon));
    expect(function.Slope(0.95), closeTo(0.42170, epsilon));
    expect(function.Slope(1), closeTo(0, epsilon));
    expect(function.Slope(1.1), closeTo(0, epsilon));
  });

  test('InputOutOfRange', () {
    final CubicBezier simple = CubicBezier(0.5, 1.0, 0.5, 1.0);
    expect(simple.Solve(-1.0), equals(-2.0));
    expect(simple.Solve(2.0), equals(1.0));

    final CubicBezier at_edge_of_range = CubicBezier(0.5, 1.0, 0.5, 1.0);
    expect(at_edge_of_range.Solve(0.0), equals(0.0));
    expect(at_edge_of_range.Solve(1.0), equals(1.0));

    final CubicBezier large_epsilon = CubicBezier(0.5, 1.0, 0.5, 1.0);
    expect(large_epsilon.SolveWithEpsilon(-1.0, 1.0), equals(-2.0));
    expect(large_epsilon.SolveWithEpsilon(2.0, 1.0), equals(1.0));

    final CubicBezier coincident_endpoints = CubicBezier(0.0, 0.0, 1.0, 1.0);
    expect(coincident_endpoints.Solve(-1.0), equals(-1.0));
    expect(coincident_endpoints.Solve(2.0), equals(2.0));

    final CubicBezier vertical_gradient = CubicBezier(0.0, 1.0, 1.0, 0.0);
    expect(vertical_gradient.Solve(-1.0), equals(0.0));
    expect(vertical_gradient.Solve(2.0), equals(1.0));

    final CubicBezier vertical_trailing_gradient =
        CubicBezier(0.5, 0.0, 1.0, 0.5);
    expect(vertical_trailing_gradient.Solve(-1.0), equals(0.0));
    expect(vertical_trailing_gradient.Solve(2.0), equals(1.0));

    final CubicBezier distinct_endpoints = CubicBezier(0.1, 0.2, 0.8, 0.8);
    expect(distinct_endpoints.Solve(-1.0), equals(-2.0));
    expect(distinct_endpoints.Solve(2.0), equals(2.0));

    final CubicBezier coincident_leading_endpoint =
        CubicBezier(0.0, 0.0, 0.5, 1.0);
    expect(coincident_leading_endpoint.Solve(-1.0), equals(-2.0));
    expect(coincident_leading_endpoint.Solve(2.0), equals(1.0));

    final CubicBezier coincident_trailing_endpoint =
        CubicBezier(1.0, 0.5, 1.0, 1.0);
    expect(coincident_trailing_endpoint.Solve(-1.0), equals(-0.5));
    expect(coincident_trailing_endpoint.Solve(2.0), equals(1.0));

    // Two special cases with three coincident points. Both are equivalent to
    // linear.
    final CubicBezier all_zeros = CubicBezier(0.0, 0.0, 0.0, 0.0);
    expect(all_zeros.Solve(-1.0), equals(-1.0));
    expect(all_zeros.Solve(2.0), equals(2.0));

    final CubicBezier all_ones = CubicBezier(1.0, 1.0, 1.0, 1.0);
    expect(all_ones.Solve(-1.0), equals(-1.0));
    expect(all_ones.Solve(2.0), equals(2.0));
  });

  test('GetPoints', () {
    const double epsilon = 0.00015;

    final CubicBezier cubic1 = CubicBezier(0.1, 0.2, 0.8, 0.9);
    expect(cubic1.GetX1(), closeTo(0.1, epsilon));
    expect(cubic1.GetY1(), closeTo(0.2, epsilon));
    expect(cubic1.GetX2(), closeTo(0.8, epsilon));
    expect(cubic1.GetY2(), closeTo(0.9, epsilon));

    final CubicBezier cubic_zero = CubicBezier(0, 0, 0, 0);
    expect(cubic_zero.GetX1(), closeTo(0, epsilon));
    expect(cubic_zero.GetY1(), closeTo(0, epsilon));
    expect(cubic_zero.GetX2(), closeTo(0, epsilon));
    expect(cubic_zero.GetY2(), closeTo(0, epsilon));

    final CubicBezier cubic_one = CubicBezier(1, 1, 1, 1);
    expect(cubic_one.GetX1(), closeTo(1, epsilon));
    expect(cubic_one.GetY1(), closeTo(1, epsilon));
    expect(cubic_one.GetX2(), closeTo(1, epsilon));
    expect(cubic_one.GetY2(), closeTo(1, epsilon));

    final CubicBezier cubic_oor = CubicBezier(-0.5, -1.5, 1.5, -1.6);
    expect(cubic_oor.GetX1(), closeTo(-0.5, epsilon));
    expect(cubic_oor.GetY1(), closeTo(-1.5, epsilon));
    expect(cubic_oor.GetX2(), closeTo(1.5, epsilon));
    expect(cubic_oor.GetY2(), closeTo(-1.6, epsilon));
  });

  void validateSolver(final CubicBezier cubic_bezier) {
    const double epsilon = 1e-7;
    const double precision = 1e-5;
    for (double t = 0; t <= 1; t += 0.05) {
      final double x = cubic_bezier.SampleCurveX(t);
      final double root = cubic_bezier.SolveCurveX(x, epsilon);
      expect(root, closeTo(t, precision));
    }
  }

  test('CommonEasingFunctions', () {
    validateSolver(CubicBezier(0.25, 0.1, 0.25, 1)); // ease
    validateSolver(CubicBezier(0.42, 0, 1, 1)); // ease-in
    validateSolver(CubicBezier(0, 0, 0.58, 1)); // ease-out
    validateSolver(CubicBezier(0.42, 0, 0.58, 1)); // ease-in-out
  });

  test('LinearEquivalentBeziers', () {
    validateSolver(CubicBezier(0.0, 0.0, 0.0, 0.0));
    validateSolver(CubicBezier(1.0, 1.0, 1.0, 1.0));
  });

  test('ControlPointsOutsideUnitSquare', () {
    validateSolver(CubicBezier(0.3, 1.5, 0.8, 1.5));
    validateSolver(CubicBezier(0.4, -0.8, 0.7, 1.7));
    validateSolver(CubicBezier(0.7, -2.0, 1.0, -1.5));
    validateSolver(CubicBezier(0, 4, 1, -3));
  });
}
