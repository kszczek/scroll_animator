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
