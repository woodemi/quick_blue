import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';

class RssiReader extends StatefulWidget {
  final String deviceId;

  RssiReader(this.deviceId);

  @override
  State<RssiReader> createState() => _RssiReaderState();
}

class _RssiReaderState extends State<RssiReader> {
  int? _rssi;

  initState() {
    super.initState();

    QuickBlue.setRssiHandler((_, rssi) {
      setState(() {
        _rssi = rssi;
      });
    });
  }

  _readRssi() async {
    await QuickBlue.readRssi(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(onPressed: _readRssi, child: Text("read rssi")),
        SizedBox(width: 12),
        Text("${_rssi}")
      ],
    );
  }
}
