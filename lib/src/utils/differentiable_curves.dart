import 'package:flutter/animation.dart';
import 'package:scroll_animator/src/chromium/cubic_bezier.dart';

/// A [Curve] that also provides the derivative ([slope]) of the curve at a
/// given point.
///
/// This abstract class extends [Curve] by adding the [slope] method, which
/// returns the rate of change (or derivative) of the curve at a specific point.
/// The slope can be used to understand the speed at which the animation is
/// progressing at any given moment.
///
/// A [DifferentiableCurve] must satisfy the same requirements as [Curve],
/// mapping t=0.0 to 0.0 and t=1.0 to 1.0 when using [transform], but the
/// same does not apply to the [slope].
///
/// See also:
///
///  * [Curve], the base class for non-differentiable curves.
abstract class DifferentiableCurve extends Curve {
  /// Abstract const constructor to enable subclasses to provide const
  /// constructors so that they can be used in const expressions.
  const DifferentiableCurve();

  /// Returns the slope of the curve at point [t].
  double slope(final double t);
}

/// A cubic polynomial mapping of the unit interval.
///
/// The [DifferentiableCurves] class contains some commonly used cubic curves:
///
///  * [DifferentiableCurves.easeInOut]
///
/// The [DifferentiableCubic] class provides an efficient and precise
/// implementation of a third-degree Bézier curve, ported from Chromium. The
/// Flutter's built-in [Cubic] class uses an epsilon of 1e-3, whereas Chromium's
/// solver uses an epsilon of 1e-7, resulting in much higher precision. Using
/// the [Cubic] implementation leads to unit test failures due to insufficient
/// precision.
///
/// See also:
///
///  * [DifferentiableCurves], where more predefined curves are available.
///  * [Cubic], the built-in third-degree Bézier curve implementation.
class DifferentiableCubic extends DifferentiableCurve {
  /// Creates a differentiable cubic curve.
  ///
  /// In this implementation, the curve is defined by four points, where the
  /// first point is fixed at (0, 0) and the last point is fixed at (1, 1).
  /// The two control points (a, b) and (c, d) shape the curve between these
  /// fixed points:
  ///
  ///  * (a, b) - The first control point. The line through the point (0, 0)
  ///    and this control point is tangent to the curve at the start (0, 0).
  ///  * (c, d) - The second control point. The line through the point (1, 1)
  ///    and this control point is tangent to the curve at the end (1, 1).
  ///
  /// Rather than creating a new instance, consider using one of the common
  /// cubic curves in [DifferentiableCurves].
  DifferentiableCubic(
    final double a,
    final double b,
    final double c,
    final double d,
  ) : _curve = CubicBezier(a, b, c, d);

  final CubicBezier _curve;

  @override
  double transform(final double t) => _curve.Solve(t);

  @override
  double slope(final double t) => _curve.Slope(t);
}

/// The identity map over the unit interval.
///
/// See [DifferentiableCurves.linear] for an instance of this class.
class _DifferentiableLinear extends DifferentiableCurve {
  const _DifferentiableLinear._();

  @override
  double transform(final double t) => t;

  @override
  double slope(final double t) => 1;
}

// This class is intended to act as a namespace for grouping related
// differentiable animation curves. While Dart discourages classes with only
// static members, in this case, it provides better structure and organization
// by keeping related curves together under a single umbrella. This approach
// is consistent with other collections of constants, like Flutter's Curves.
// ignore: avoid_classes_with_only_static_members
/// A collection of common differentiable animation curves.
///
/// See also:
///
///  * [DifferentiableCurve], the interface implemented by the constants
///    available from the [DifferentiableCurves] class.
///  * [Curves], a collection of common non-differentiable easing curves.
abstract final class DifferentiableCurves {
  /// A linear animation curve.
  ///
  /// This is the identity map over the unit interval: its
  /// [DifferentiableCurve.transform] method returns its input unmodified. The
  /// derivative (slope) of the curve is always `1`, as it represents a constant
  /// rate of change. This is useful as a default curve for cases where a
  /// [DifferentiableCurve] is required but no actual curve is desired.
  static const DifferentiableCurve linear = _DifferentiableLinear._();

  /// A cubic animation curve that starts slowly, speeds up, and then ends
  /// slowly.
  ///
  /// This is the same as the CSS easing function `ease-in-out`.
  static final DifferentiableCubic easeInOut =
      DifferentiableCubic(0.42, 0.0, 0.58, 1.0);
}
