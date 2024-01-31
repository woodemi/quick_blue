import 'dart:math' as math;
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/components/buffered_stream_builder.dart';
import 'package:quick_blue_example/components/button_card.dart';
import 'package:quick_blue_example/device_page.dart';
import 'package:quick_blue_example/extensions/widget.dart';

class ScanResultList extends StatelessWidget {
  ScanResultList();

  @override
  Widget build(BuildContext context) => BufferedStreamBuilder<BlueScanResult>(
      stream: QuickBlue.scanResultStream, builder: _resultListBuilder);

  Widget _resultListBuilder(BuildContext context, Queue<BlueScanResult> elem) {
    Set<String> foundIds = {};
    Queue<BlueScanResult> filteredDevices = Queue();
    for (var e in elem) {
      if (!foundIds.contains(e.deviceId)) {
        filteredDevices.add(e);
        foundIds.add(e.deviceId);
      }
    }

    var sorted = filteredDevices.toList();
    sorted.sort((a, b) => b.rssi.compareTo(a.rssi));
    return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
            width: math.min(500, constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  [for (var e in sorted) _ResultButtonCard(e: e)].padded(),
            )));
  }
}

class _ResultButtonCard extends StatelessWidget {
  const _ResultButtonCard({required this.e});

  final BlueScanResult e;

  @override
  Widget build(BuildContext context) {
    return ButtonCard(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DevicePage(e.deviceId, e.name))),
        child: SizedBox(
            height: 130,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(children: [
                    Row(children: [Text("name:"), Text(e.name)].padded()),
                    Row(
                      children: [
                        Text("deviceId:"),
                        Text(e.deviceId),
                      ].padded(),
                    ),
                    Row(
                        children: [
                      Text("rssi:"),
                      Text(e.rssi.toString()),
                    ].padded()),
                  ]),
                  OutlinedButton(onPressed: () {}, child: Text("show details")),
                ])));
  }
}
