import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/extensions/widget.dart';

class IntervalRequestButton extends StatefulWidget {
  final String deviceId;

  const IntervalRequestButton(this.deviceId);

  @override
  _IntervalRequestButtonState createState() => _IntervalRequestButtonState();
}

class _IntervalRequestButtonState extends State<IntervalRequestButton> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<BlePackageLatency>(
        dropdownMenuEntries: BlePackageLatency.values
            .map((e) => DropdownMenuEntry(label: e.toString(), value: e))
            .toList(),
        onSelected: (value) {
          if (value != null) {
            QuickBlue.requestLatency(widget.deviceId, value);
          }
        });
  }
}
