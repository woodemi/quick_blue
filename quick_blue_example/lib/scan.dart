import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/buffered_stream_builder.dart';

class Scanner extends StatelessWidget {
  Scanner() {
    QuickBlue.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return BufferedStreamBuilder<BlueScanResult>(
        stream: QuickBlue.scanResultStream,
        builder: (context, elements) => ListView(
              shrinkWrap: true,
              children: [
                for (var e in elements)
                  ListTile(
                      title: Row(children: [
                    Text(e.name),
                    Text(e.deviceId),
                    Text(e.rssi.toString())
                  ]))
              ],
            ));
  }
}
