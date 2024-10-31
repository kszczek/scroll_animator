import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:scroll_animator/src/animated_scroll_controller.dart';
import 'package:scroll_animator/src/scroll_animation.dart';

const Set<TargetPlatform> _kAllPlatforms = <TargetPlatform>{
  TargetPlatform.android,
  TargetPlatform.fuchsia,
  TargetPlatform.iOS,
  TargetPlatform.linux,
  TargetPlatform.macOS,
  TargetPlatform.windows,
};

/// Associates an [AnimatedScrollController] with a subtree.
///
/// This widget manages an instance of the [AnimatedScrollController] and
/// associates it with a subtree by wrapping its [child] with a
/// [PrimaryScrollController].
///
/// See also:
///   * [PrimaryScrollController], which is used by this widget to provide the
///     [AnimatedScrollController] to its children.
class AnimatedPrimaryScrollController extends StatefulWidget {
  /// Creates a widget that associates an [AnimatedScrollController] with
  /// a subtree.
  const AnimatedPrimaryScrollController({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.automaticallyInheritForPlatforms = _kAllPlatforms,
    this.animationFactory = const ChromiumEaseInOut(),
    required this.child,
  });

  /// The [Axis] this controller is configured for [ScrollView]s to
  /// automatically inherit.
  ///
  /// Used in conjunction with [automaticallyInheritForPlatforms]. If the
  /// current [TargetPlatform] is not included in
  /// [automaticallyInheritForPlatforms], this is ignored.
  ///
  /// When null, no [ScrollView] in any Axis will automatically inherit this
  /// controller. This is dissimilar to [PrimaryScrollController.none]. When a
  /// PrimaryScrollController is inherited, ScrollView will insert
  /// PrimaryScrollController.none into the tree to prevent further descendant
  /// ScrollViews from inheriting the current PrimaryScrollController.
  ///
  /// For the direction in which active scrolling may be occurring, see
  /// [ScrollDirection].
  ///
  /// Defaults to [Axis.vertical].
  final Axis? scrollDirection;

  /// The [TargetPlatform]s this controller is configured for [ScrollView]s to
  /// automatically inherit.
  ///
  /// Used in conjunction with [scrollDirection]. If the [Axis] provided to
  /// [PrimaryScrollController.shouldInherit] is not [scrollDirection], this is
  /// ignored.
  ///
  /// When empty, no ScrollView in any Axis will automatically inherit this
  /// controller. Defaults to all known [TargetPlatform]s.
  final Set<TargetPlatform> automaticallyInheritForPlatforms;

  /// A factory which produces [ScrollAnimation] instances to be used by the
  /// managed [AnimatedScrollController] for animating scroll delta events.
  ///
  /// Defaults to [ChromiumEaseInOut].
  final ScrollAnimationFactory animationFactory;

  /// The child widget of this [AnimatedPrimaryScrollController].
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<AnimatedPrimaryScrollController> createState() =>
      _AnimatedPrimaryScrollControllerState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('scrollDirection', scrollDirection))
      ..add(
        IterableProperty<String>(
          'automaticallyInheritForPlatforms',
          automaticallyInheritForPlatforms
              .map((final platform) => platform.name),
          ifEmpty: '<none>',
        ),
      )
      ..add(
        DiagnosticsProperty<ScrollAnimationFactory>(
          'animationFactory',
          animationFactory,
        ),
      );
  }
}

class _AnimatedPrimaryScrollControllerState
    extends State<AnimatedPrimaryScrollController> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // TODO(kszczek): add support for dynamically swapping factories
    _scrollController = AnimatedScrollController(
      animationFactory: widget.animationFactory,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => PrimaryScrollController(
        controller: _scrollController,
        automaticallyInheritForPlatforms:
            widget.automaticallyInheritForPlatforms,
        scrollDirection: widget.scrollDirection,
        child: widget.child,
      );
}
