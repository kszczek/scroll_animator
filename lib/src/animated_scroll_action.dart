import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:scroll_animator/src/animated_scroll_position.dart';
import 'package:scroll_animator/src/scroll_animation.dart';

/// An [Action] that scrolls the relevant [Scrollable] by the amount configured
/// in the [ScrollIntent] given to it.
///
/// This action behaves exactly like the [ScrollAction], except that it calls
/// [AnimatedScrollPosition.keyboardScroll] instead of [ScrollPosition.moveTo]
/// for [Scrollable]s managed by an [AnimatedScrollPosition]. This allows the
/// animation parameters to be defined by the [ScrollAnimationFactory]
/// associated with the aforementioned [AnimatedScrollPosition].
class AnimatedScrollAction extends ScrollAction {
  @override
  void invoke(final ScrollIntent intent, [final BuildContext? context]) {
    assert(context != null, 'Cannot scroll without a context.');

    var state = Scrollable.maybeOf(context!);
    if (state == null) {
      final primaryScrollController = PrimaryScrollController.of(context);

      // This assertion has an indirect message via the FlutterError
      // ignore: prefer_asserts_with_message
      assert(() {
        if (primaryScrollController.positions.length != 1) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
              'An $AnimatedScrollAction was invoked with the '
              '$PrimaryScrollController, but more than one $ScrollPosition is '
              'attached.',
            ),
            ErrorDescription(
              'Only one $ScrollPosition can be manipulated by an '
              '$AnimatedScrollAction at a time.',
            ),
            ErrorHint(
              'The $PrimaryScrollController can be inherited automatically by '
              'descendant ${ScrollView}s based on the $TargetPlatform and '
              'scroll direction. By default, the $PrimaryScrollController is '
              'automatically inherited on mobile platforms for vertical '
              '${ScrollView}s. $ScrollView.primary can also override this '
              'behavior.',
            ),
          ]);
        }
        return true;
      }());

      final notificationContext =
          primaryScrollController.position.context.notificationContext;
      if (notificationContext != null) {
        state = Scrollable.maybeOf(notificationContext);
      }

      if (state == null) {
        return;
      }
    }

    assert(
      state.position.hasPixels,
      '$Scrollable must be laid out before it can be scrolled via an '
      '$AnimatedScrollAction',
    );

    // Don't do anything if the user isn't allowed to scroll.
    if (state.resolvedPhysics != null &&
        !state.resolvedPhysics!.shouldAcceptUserOffset(state.position)) {
      return;
    }

    final increment = ScrollAction.getDirectionalIncrement(state, intent);
    if (increment == 0.0) {
      return;
    }

    if (state.position is AnimatedScrollPosition) {
      (state.position as AnimatedScrollPosition).keyboardScroll(increment);
    } else {
      unawaited(
        state.position.moveTo(
          state.position.pixels + increment,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        ),
      );
    }
  }
}
