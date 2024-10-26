import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:scroll_animator/src/scroll_animation.dart';

/// An activity that animates a scroll view based on animation parameters.
///
/// This class is similar to Flutter's [DrivenScrollActivity], but instead of
/// using an [AnimationController], it directly relies on a [Ticker] combined
/// with a [ScrollAnimation].
class AnimatedScrollActivity extends ScrollActivity {
  /// Creates an activity that animates a scroll view based on animation
  /// parameters.
  AnimatedScrollActivity(
    super._delegate, {
    required final ScrollAnimation animation,
    required final TickerProvider vsync,
    final void Function(ScrollDirection)? onDirectionChanged,
  })  : _animation = animation,
        _startTime = DateTime.now(),
        _onDirectionChanged = onDirectionChanged {
    _ticker = vsync.createTicker(_tick)..start();
  }

  final ScrollAnimation _animation;
  final DateTime _startTime;
  final void Function(ScrollDirection)? _onDirectionChanged;
  late final Ticker _ticker;
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;
  bool _isDisposed = false;

  /// Indicates whether the scroll animation has finished.
  ///
  /// This property returns `true` if the time elapsed since the animation
  /// started has exceeded the total duration of the [ScrollAnimation].
  bool get isFinished => _elapsed > _animation.duration;

  /// The current target value of the scroll offset for the animation.
  double get targetValue => _animation.targetValue.dy;
  set targetValue(final double targetValue) =>
      _animation.updateTargetValue(_elapsed, Offset(0.0, targetValue));

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _animation.getVelocity(_elapsed).dy;

  Duration get _elapsed => DateTime.now().difference(_startTime);

  @override
  void dispatchOverscrollNotification(
    final ScrollMetrics metrics,
    final BuildContext context,
    final double overscroll,
  ) {
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: overscroll,
      velocity: velocity,
    ).dispatch(context);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker.dispose();
    super.dispose();
  }

  void _tick(final Duration elapsed) {
    // TODO(kszczek): investigate if this check is really needed here
    if (_isDisposed) {
      return;
    }

    final done = elapsed > _animation.duration;
    final offset = done ? _animation.targetValue : _animation.getValue(elapsed);
    final velocity = _animation.getVelocity(elapsed).dy;
    final scrollDirection = velocity == 0
        ? ScrollDirection.idle
        : (velocity < 0 ? ScrollDirection.forward : ScrollDirection.reverse);
    if (scrollDirection != _lastScrollDirection) {
      _lastScrollDirection = scrollDirection;
      if (scrollDirection != ScrollDirection.idle) {
        _onDirectionChanged?.call(scrollDirection);
      }
    }
    final overscroll = delegate.setPixels(offset.dy);
    if (overscroll != 0.0 || done) {
      delegate.goIdle();
    }
  }
}
