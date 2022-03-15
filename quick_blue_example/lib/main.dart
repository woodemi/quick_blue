import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';

import 'PeripheralDetailPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<BlueScanResult>? _subscription;
  var _scanResults = <BlueScanResult>[];

  @override
  void initState() {
    super.initState();
    // _subscription = QuickBlue.scanResultStream.listen((result) {
    //   if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
    //     setState(() => _scanResults.add(result));
    //   }
    // });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  startScan() {
    if (kIsWeb) {
      QuickBlue.startScan(optionalServices: [
        '00001800-0000-1000-8000-00805f9b34fb',
        '0000180f-0000-1000-8000-00805f9b34fb',
        '0000180a-0000-1000-8000-00805f9b34fb'
      ]);
    } else {
      QuickBlue.startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Quick Blue'),
        ),
        body: Column(
          children: [
            _buildButtons(),
            Divider(
              color: Colors.blue,
            ),
            _scanResults.isEmpty ? _scanDevice() : _buildListView(),
            _buildPermissionWarning(),
          ],
        ),
      ),
    );
  }

  Widget _scanDevice() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.bluetooth,
              color: Colors.grey,
              size: 100,
            ),
          ),
          Text(
            'Scan For Devices',
            style: TextStyle(color: Colors.grey, fontSize: 22),
          )
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return FittedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          SizedBox(
            width: 10,
          ),
          ElevatedButton(
            child: Text('Start Scan'),
            onPressed: () {
              startScan();
            },
          ),
          FutureBuilder(
            future: QuickBlue.isBluetoothAvailable(),
            builder: (context, snapshot) {
              var available = snapshot.data?.toString() ?? '...';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18.0, vertical: 7),
                child: ElevatedButton(
                  child: Text('Ble Availability : $available'),
                  onPressed: () {
                    QuickBlue.stopScan();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.grey,
                  ),
                ),
              );
            },
          ),
          ElevatedButton(
            child: Text('Stop Scan'),
            onPressed: () {
              QuickBlue.stopScan();
            },
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Card(
            child: ListTile(
              title: Text(_scanResults[index].rssi != 0
                  ? '${_scanResults[index].name} (${_scanResults[index].rssi})'
                  : '${_scanResults[index].name}'),
              subtitle: Text(_scanResults[index].deviceId),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PeripheralDetailPage(_scanResults[index].deviceId),
                    ));
              },
            ),
          ),
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _scanResults.length,
      ),
    );
  }

  Widget _buildPermissionWarning() {
    if (kIsWeb) return Container();
    if (Platform.isAndroid) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text('BLUETOOTH_SCAN/ACCESS_FINE_LOCATION needed'),
      );
    }
    return Container();
  }
}
