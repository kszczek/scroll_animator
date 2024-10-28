import 'package:flutter/widgets.dart';
import 'package:scroll_animator/src/animated_scroll_position.dart';
import 'package:scroll_animator/src/scroll_animation.dart';
import 'package:scroll_animator/src/utils/curves.dart';

/// Provides additional static methods for performing animated programmatic
/// scrolls within a [Scrollable] widget.
extension AnimatedScrollable on Scrollable {
  /// Scrolls the scrollables that enclose the given context so as to make the
  /// given context visible.
  ///
  /// This method is similar to [Scrollable.ensureVisible] but does not require
  /// explicit curve or duration parameters. Its behavior varies based on the
  /// type of [ScrollPosition] which manages the [Scrollable] enclosing given
  /// context:
  ///
  ///  * For [AnimatedScrollPosition] instances, duration and curve are sourced
  ///    from the associated [ScrollAnimationFactory].
  ///  * For other [ScrollPosition] types, the position will typically jump
  ///    immediately to the given context.
  static Future<void> ensureVisible(
    final BuildContext context, {
    final double alignment = 0.0,
    final ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
  }) =>
      Scrollable.ensureVisible(
        context,
        alignment: alignment,
        // A non-zero duration is necessary here to prevent
        // Scrollable.ensureVisible from returning an already completed future.
        duration: const Duration(microseconds: 1),
        curve: const ScrollAnimatorCurve(),
        alignmentPolicy: alignmentPolicy,
      );
}
