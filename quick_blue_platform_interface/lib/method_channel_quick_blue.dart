import 'package:flutter/services.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class MethodChannelQuickBlue extends QuickBluePlatform {
  static const MethodChannel _method = const MethodChannel('quick_blue/method');
  static const _event_scanResult = const EventChannel('quick_blue/event.scanResult');

  @override
  void startScan() {
    _method.invokeMethod('startScan')
        .then((_) => print('startScan invokeMethod success'));
  }

  @override
  void stopScan() {
    _method.invokeMethod('stopScan')
        .then((_) => print('stopScan invokeMethod success'));
  }

  Stream<dynamic> _scanResultStream = _event_scanResult.receiveBroadcastStream({'name': 'scanResult'});

  @override
  Stream<dynamic> get scanResultStream => _scanResultStream;
}
