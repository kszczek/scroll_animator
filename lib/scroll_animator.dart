/// A Flutter package that provides smooth, animated scrolling for pointer-based
/// input devices, such as mouse wheels and trackpads.
library;

export 'package:scroll_animator/src/animated_scroll_activity.dart'
    show AnimatedScrollActivity;
export 'package:scroll_animator/src/animated_scroll_controller.dart'
    show AnimatedScrollController;
export 'package:scroll_animator/src/animated_scroll_position.dart'
    show AnimatedScrollPosition;
export 'package:scroll_animator/src/scroll_animation.dart'
    show
        ChromiumEaseInOut,
        ChromiumImpulse,
        ScrollAnimation,
        ScrollAnimationFactory;
export 'package:scroll_animator/src/utils/differentiable_curves.dart'
    show DifferentiableCubic, DifferentiableCurve, DifferentiableCurves;
