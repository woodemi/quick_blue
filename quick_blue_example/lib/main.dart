import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:quick_blue_example/scan.dart';

void main() {
  Logger.root.onRecord.listen((r) {
    print(r.loggerName + ' ' + r.level.name + ' ' + r.message);
  });
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      QuickBlue.setLogger(Logger('quick_blue_example'));
    }
  }

  void _toggleScan() {
    _isScanning ? QuickBlue.stopScan() : QuickBlue.startScan();
    setState(() => _isScanning = !_isScanning);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        themeMode: ThemeMode.dark,
        home: SafeArea(
            child: Scaffold(
                appBar: AppBar(
                  title: const Text('Quick Blue Example'),
                ),
                body: SingleChildScrollView(
                    child: Column(children: [
                  Center(
                      child: OutlinedButton(
                          onPressed: _toggleScan,
                          child:
                              Text(_isScanning ? 'Stop Scan' : 'Start Scan'))),
                  if (_isScanning) ScanResultList()
                ])))));
  }

  Widget _buildPermissionWarning() {
    if (Platform.isAndroid) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Text('BLUETOOTH_SCAN/ACCESS_FINE_LOCATION needed'),
      );
    }
    return Container();
  }
}
