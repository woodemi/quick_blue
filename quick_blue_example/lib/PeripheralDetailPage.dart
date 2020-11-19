import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';

class PeripheralDetailPage extends StatefulWidget {
  final String deviceId;

  PeripheralDetailPage(this.deviceId);

  @override
  State<StatefulWidget> createState() {
    return _PeripheralDetailPageState();
  }
}

class _PeripheralDetailPageState extends State<PeripheralDetailPage> {
  @override
  void initState() {
    super.initState();
    QuickBlue.setConnectionHandler(_handleConnectionChange);
  }

  @override
  void dispose() {
    super.dispose();
    QuickBlue.setConnectionHandler(null);
  }

  void _handleConnectionChange(String deviceId, BlueConnectionState state) {
    print('_handleConnectionChange $deviceId, $state');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PeripheralDetailPage'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('connect'),
                onPressed: () {
                  QuickBlue.connect(widget.deviceId);
                },
              ),
              RaisedButton(
                child: Text('disconnect'),
                onPressed: () {
                  QuickBlue.disconnect(widget.deviceId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}