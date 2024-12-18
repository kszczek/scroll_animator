/// A Flutter package that provides smooth, animated scrolling for mouse wheels,
/// trackpads, keyboards and programmatic scrolls.
library;

export 'package:scroll_animator/src/animated_primary_scroll_controller.dart'
    show AnimatedPrimaryScrollController;
export 'package:scroll_animator/src/animated_scroll_action.dart'
    show AnimatedScrollAction;
export 'package:scroll_animator/src/animated_scroll_activity.dart'
    show AnimatedScrollActivity;
export 'package:scroll_animator/src/animated_scroll_controller.dart'
    show AnimatedScrollController;
export 'package:scroll_animator/src/animated_scroll_position.dart'
    show AnimatedScrollPosition;
export 'package:scroll_animator/src/extensions/scrollable.dart'
    show AnimatedScrollable;
export 'package:scroll_animator/src/scroll_animation.dart'
    show
        ChromiumEaseInOut,
        ChromiumImpulse,
        ScrollAnimation,
        ScrollAnimationFactory;
export 'package:scroll_animator/src/utils/differentiable_curves.dart'
    show DifferentiableCubic, DifferentiableCurve, DifferentiableCurves;
