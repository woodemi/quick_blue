import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

class BufferedStreamBuilder<T> extends StatefulWidget {
  Stream<T> stream;
  Widget Function(BuildContext context, Queue<T> elements) builder;

  BufferedStreamBuilder({required this.stream, required this.builder});

  @override
  State<BufferedStreamBuilder> createState() => _BufferedStreamBuilderState();
}

class _BufferedStreamBuilderState<T> extends State<BufferedStreamBuilder> {
  final _elementQueue = Queue<T>();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream
        .listen((event) => setState(() => _elementQueue.add(event)));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _elementQueue);
  }
}
