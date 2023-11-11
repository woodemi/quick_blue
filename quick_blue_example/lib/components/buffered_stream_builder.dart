import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

typedef StreamQueueBuilder<T> = Widget Function(
    BuildContext context, Queue<T> elements);

class BufferedStreamBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final StreamQueueBuilder<T> builder;

  BufferedStreamBuilder({required this.stream, required this.builder});

  @override
  State<BufferedStreamBuilder> createState() =>
      _BufferedStreamBuilderState<T>();
}

class _BufferedStreamBuilderState<T> extends State<BufferedStreamBuilder<T>> {
  final _elementQueue = Queue<T>();
  StreamSubscription<T>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen((T event) {
      setState(() => _elementQueue.add(event));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _elementQueue);
}
