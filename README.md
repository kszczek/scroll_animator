A Flutter package that provides smooth, animated scrolling for mouse wheels,
trackpads, keyboards and programmatic scrolls. It includes some widely used
scroll animations that can be used out of the box, while also offering
the flexibility to implement custom scroll animations.

![A side-by-side comparison: on the left, the default scroll behavior, and on the right, the scrolling is smoothed using the ChromiumEaseInOut animation.](https://raw.githubusercontent.com/kszczek/scroll_animator/2565cad263190080dc89c7766d1ee0a882ccaed4/doc/ease_in_out.gif)

## Usage

This example application exhaustively demonstrates the features provided by
the package:

```dart
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_animator/scroll_animator.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp(
        // By default, Flutter provides platform-specific scroll shortcuts,
        // defined in WidgetsApp.defaultShortcuts. To customize these shortcuts,
        // use the shortcuts parameter as shown here.
        shortcuts: {
          ...WidgetsApp.defaultShortcuts,
          const SingleActivator(LogicalKeyboardKey.keyW):
              const ScrollIntent(direction: AxisDirection.up),
          const SingleActivator(LogicalKeyboardKey.keyS):
              const ScrollIntent(direction: AxisDirection.down),
          const SingleActivator(LogicalKeyboardKey.keyA):
              const ScrollIntent(direction: AxisDirection.left),
          const SingleActivator(LogicalKeyboardKey.keyD):
              const ScrollIntent(direction: AxisDirection.right),
        },

        // By default, MaterialApp and CupertinoApp map ScrollIntent to
        // ScrollAction, which applies a fixed ease-in-out curve and 100ms
        // duration. To use custom scroll animations with dynamic parameters,
        // which this package provides, map ScrollIntent to
        // AnimatedScrollAction in the actions property as shown here.
        actions: {
          ...WidgetsApp.defaultActions,
          ScrollIntent: AnimatedScrollAction(),
        },

        // This widget provides a default scroll controller for all of its
        // descendants. This has two main advantages.
        //
        //  1. We don't have to instantiate and manage a scroll controller
        //     by ourselves, which usually causes some pain, becuase we have
        //     to create a stateful widget to contain the aforementioned
        //     scroll controller. This wrapper does all of this for us.
        //
        //  2. This is required for keyboard scrolling to work. That's
        //     because the AnimatedScrollAction will be invoked with the
        //     context of the Focus widget which captured the key press
        //     and then that scroll action will go up the tree looking for
        //     the closest scrollable widget or closest primary scroll
        //     controller. Although the MaterialApp and CupertinoApp both
        //     have their own primary scroll controllers, they are backed by
        //     a regular ScrollController and not an AnimatedScrollController.
        //
        // As a rule of thumb you should try to use this widget sparingly.
        // Enclosing entire routes with it is a common pattern, but it might
        // cause an issue if you have multiple scrollable widgets making use
        // of the primary scroll controller on a single page. In that case
        // you might see an error that the AnimatedScrollAction doesn't know
        // which scrollable to deliver the event to. In that case it's
        // recommended to provide a primary scroll controller for each
        // sub-tree which contains a scrollable widget.
        home: AnimatedPrimaryScrollController(
          animationFactory: const ChromiumEaseInOut(),
          child: Builder(
            builder: (final context) => Scaffold(
              appBar: AppBar(title: const Text('Scroll Animator Example')),

              // With an AnimatedScrollController, you don't have to provide
              // neither the curve nor duration of the animation. Both of these
              // parameters will be automatically determined based on the
              // distance to scroll. The AnimatedScrollController also has
              // another advantage over the regular ScrollController. You can
              // see that if you press the button repeatedly, the animation
              // remains smooth even though the target keeps changing.
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.question_mark),
                onPressed: () {
                  final scrollController = PrimaryScrollController.of(context);
                  final offset = lerpDouble(
                    scrollController.position.minScrollExtent,
                    scrollController.position.maxScrollExtent,
                    Random().nextDouble(),
                  );
                  if (scrollController is AnimatedScrollController) {
                    scrollController.animateTo(offset ?? 0.0);
                  } else {
                    scrollController.animateTo(
                      offset ?? 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),

              // We need to enclose our scrollable widget with a focus widget to
              // enable scrolling using keyboard shortcuts. Why do we need it?
              // You could imagine a scenario on a regular web page made using
              // traditional technologies like HTML where you have multiple
              // scrollable elements on a single page. When your user presses the
              // arrow keys, which of them should be scrolled? This question is
              // answered by: well, whichever of them is currently in focus.
              // For example, a user might click a given scrollable element to put
              // focus on it and then use arrows to scroll it, then click another
              // scrollable, thus moving focus to it. We want to implement this
              // behavior, and we do so by wrapping our scrollable widgets in
              // focus widgets.
              body: Focus(
                autofocus: true,
                child: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (final context, final index) => ListTile(
                    title: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
```

## Scroll animations

This package provides two built-in `ScrollAnimation` implementations, ported
directly from Chromium along with their unit tests, so they should behave
*identically* as in Chromium-based browsers.

### `ChromiumEaseInOut`

This is the default scroll animation for most Chromium-based browsers,
which is active when the `#smooth-scrolling` flag is enabled and
`#windows-scrolling-personality` is disabled.

### `ChromiumImpulse`

This is the default scroll animation for Microsoft Edge, but can also be
enabled in other Chromium-based browsers by enabling both `#smooth-scrolling`
and `#windows-scrolling-personality` flags.

## Pointer precision

Trackpads typically provide precise and frequent scroll deltas, which often
leads to the assumption that scroll smoothing isn't necessary. However, some
trackpads can produce larger, less frequent deltas, similar to mouse wheels.
Therefore, this package handles all scroll inputs without making assumptions
based on the pointer type.

See [this Chromium bug](https://issues.chromium.org/41210665) for discussion
on this topic.
