import 'package:flutter/material.dart';

import 'package:quick_blue/quick_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            RaisedButton(
              child: Text('startScan'),
              onPressed: () {
                QuickBlue.startScan();
              },
            ),
            RaisedButton(
              child: Text('stopScan'),
              onPressed: () {
                QuickBlue.stopScan();
              },
            ),
          ],
        ),
      ),
    );
  }
}
