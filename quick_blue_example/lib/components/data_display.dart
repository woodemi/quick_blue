import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';

class DataDisplay extends StatefulWidget {
  final String deviceId;

  const DataDisplay(this.deviceId);

  @override
  State<DataDisplay> createState() => _DataDisplayState();
}

class _DataDisplayState extends State<DataDisplay> {
  Queue<Uint8List> _dataBuffer = Queue<Uint8List>();

  @override
  void initState() {
    QuickBlue.setValueHandler((deviceId, characteristicId, value) {
      setState(() {
        _dataBuffer.add(value);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    QuickBlue.setValueHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [for (var e in _dataBuffer.takeLast(5)) Text(e.toString())],
      );
}

extension TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final skipCount = length - n;
    return skipCount < 0 ? [] : skip(skipCount);
  }
}
