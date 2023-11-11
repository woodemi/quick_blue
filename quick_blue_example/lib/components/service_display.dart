import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/components/data_display.dart';
import 'package:quick_blue_example/extensions/widget.dart';

typedef BleService = (String, List<String>);

class ServiceDisplay extends StatefulWidget {
  final String deviceId;

  ServiceDisplay(this.deviceId);

  @override
  State<ServiceDisplay> createState() => _ServiceDisplayState();
}

class _ServiceDisplayState extends State<ServiceDisplay> {
  StreamController<BleService>? _discoverServicesController =
      StreamController.broadcast();

  Queue<BleService> _discoveredServices = Queue<BleService>();

  @override
  void initState() {
    QuickBlue.setServiceHandler(
        (String deviceId, String serviceId, List<String> characteristicIds) {
      print("characteristicIds: $characteristicIds");
      setState(() {
        _discoveredServices.add((serviceId, characteristicIds));
      });
    });
    QuickBlue.discoverServices(widget.deviceId);
    super.initState();
  }

  @override
  void dispose() {
    _discoverServicesController?.close();
    QuickBlue.setServiceHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(children: [
        Column(children: [
          for (var e in _discoveredServices)
            SizedBox(
                width: min(constraints.maxWidth, 1000),
                height: 100 + e.$2.length * 125,
                child: _DiscoveredServiceCard(e: e, widget: widget))
        ])
      ]);
    });
  }
}

class _DiscoveredServiceCard extends StatefulWidget {
  _DiscoveredServiceCard({
    super.key,
    required this.e,
    required this.widget,
  });

  final BleService e;
  final ServiceDisplay widget;

  @override
  State<_DiscoveredServiceCard> createState() => _DiscoveredServiceCardState();
}

class _DiscoveredServiceCardState extends State<_DiscoveredServiceCard> {
  final _controller = TextEditingController();

  Uint8List _commandBytes = Uint8List.fromList([0x00, 0x01, 0x00]);

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Row(
            children: [
      Column(children: [
        Expanded(child: Text(widget.e.$1)),
        Expanded(flex: 3, child: DataDisplay(widget.widget.deviceId))
      ]),
      Column(
          children: [
        for (var c in widget.e.$2)
          Column(
            children: [
              Text(c),
              Row(
                  children: [
                OutlinedButton(
                    onPressed: () => QuickBlue.writeValue(
                        widget.widget.deviceId,
                        widget.e.$1,
                        c,
                        _commandBytes,
                        BleOutputProperty.withoutResponse),
                    child: Text("write value")),
                OutlinedButton(
                    onPressed: () => QuickBlue.setNotifiable(
                        widget.widget.deviceId,
                        widget.e.$1,
                        c,
                        BleInputProperty.notification),
                    child: Text("set notifiable"))
              ].spacedWith()),
            ].spaced(),
          ),
        Row(
            children: [
          TextField(
            controller: _controller,
            onChanged: (value) {
              setState(() {
                _commandBytes = Uint8List.fromList(value
                    .split(RegExp(r'[ ,]'))
                    .where((s) => s.isNotEmpty)
                    .map(int.parse)
                    .toList());
                // Now you can use intList
              });
            },
          ),
          Text("command bytes: ${_commandBytes.toString()}")
        ].spaced()),
      ].spacedWith())
    ].spacedWith()));
  }
}
