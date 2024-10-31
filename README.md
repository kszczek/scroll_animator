A Flutter package that provides smooth, animated scrolling for mouse wheels,
trackpads, keyboards and programmatic scrolls. It includes some widely used
scroll animations that can be used out of the box, while also offering
the flexibility to implement custom scroll animations.

![A side-by-side comparison: on the left, the default scroll behavior, and on the right, the scrolling is smoothed using the ChromiumEaseInOut animation.](https://raw.githubusercontent.com/kszczek/scroll_animator/2565cad263190080dc89c7766d1ee0a882ccaed4/doc/ease_in_out.gif)

## Usage

To use this package, create an instance of `AnimatedScrollController` with your
preferred `ScrollAnimation` factory, and pass it to your scrollable widget.

```dart
import 'package:flutter/material.dart';
import 'package:scroll_animator/scroll_animator.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Scroll Animator Example')),
          body: _ScrollAnimatorExample(),
        ),
      );
}

class _ScrollAnimatorExample extends StatefulWidget {
  @override
  _ScrollAnimatorExampleState createState() => _ScrollAnimatorExampleState();
}

class _ScrollAnimatorExampleState extends State<_ScrollAnimatorExample> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => ListView.builder(
        controller: _scrollController,
        itemCount: 100,
        itemBuilder: (final context, final index) => ListTile(
          title: Text('Item $index'),
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
