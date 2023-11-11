import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/components/mtu_request_button.dart';
import 'package:quick_blue_example/components/service_display.dart';
import 'package:quick_blue_example/extensions/widget.dart';

class DevicePage extends StatefulWidget {
  final String deviceId;
  final String name;

  DevicePage(this.deviceId, this.name);

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  bool _isConnected = false;
  bool _discoverServices = false;

  @override
  void initState() {
    QuickBlue.setConnectionHandler((deviceId, state) {
      if (deviceId == widget.deviceId) {
        setState(() {
          _discoverServices = false;
          _isConnected = state == BlueConnectionState.connected;
        });
      }
    });
    super.initState();
  }

  void _toggleConnection() {
    _isConnected
        ? QuickBlue.disconnect(widget.deviceId)
        : QuickBlue.connect(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(title: Text("Device: ${widget.name}")),
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                      child: OutlinedButton(
                          onPressed: _toggleConnection,
                          child:
                              Text(_isConnected ? "disconnect" : "connect"))),
                  if (_isConnected)
                    SizedBox(
                        height: 100,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              !_discoverServices
                                  ? OutlinedButton(
                                      onPressed: () => setState(
                                          () => _discoverServices = true),
                                      child: Text("discover services"))
                                  : Container(),
                              MtuRequestWidget(widget.deviceId),
                            ].spacedWith(spacing: 20))),
                  if (_isConnected && _discoverServices)
                    ServiceDisplay(widget.deviceId),
                ].padded())));
  }
}
