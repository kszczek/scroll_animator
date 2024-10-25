import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  late final DateTime _startDateTime;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _startDateTime = DateTime.now();
    _scrollController = AnimatedScrollController(
      animationFactory: const ChromiumEaseInOut(),
    );
  }

  void _receivedPointerSignal(final PointerSignalEvent event) {
    if (!kDebugMode) {
      return;
    }

    if (event is PointerScrollEvent) {
      _debugPrint(
        'PointerScrollEvent('
        'dx: ${event.scrollDelta.dx}, '
        'dy: ${event.scrollDelta.dy}'
        ')',
      );
    } else if (event is PointerScrollInertiaCancelEvent) {
      _debugPrint('PointerScrollInertiaCancelEvent()');
    }
  }

  bool _receivedScrollNotification(final ScrollNotification notification) {
    if (!kDebugMode) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _debugPrint('ScrollStartNotification()');
    } else if (notification is ScrollEndNotification) {
      _debugPrint('ScrollEndNotification()');
    } else if (notification is ScrollUpdateNotification) {
      _debugPrint(
        '  ScrollUpdateNotification(delta: ${notification.scrollDelta})',
      );
    } else if (notification is UserScrollNotification) {
      _debugPrint(
        'UserScrollNotification(direction: ${notification.direction})',
      );
    } else {
      _debugPrint(notification.toString());
    }

    return false;
  }

  void _debugPrint(final String message) {
    final elapsed = DateTime.now().difference(_startDateTime);
    final elapsedAsString = (elapsed.inMilliseconds / 1e3).toStringAsFixed(3);
    debugPrint('$elapsedAsString: $message');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Listener(
        onPointerSignal: _receivedPointerSignal,
        child: NotificationListener<ScrollNotification>(
          onNotification: _receivedScrollNotification,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: 100,
            itemBuilder: (final context, final index) => ListTile(
              title: Text('Item $index'),
            ),
          ),
        ),
      );
}
