import 'package:flutter/services.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class MethodChannelQuickBlue extends QuickBluePlatform {
  static const MethodChannel _channel = const MethodChannel('quick_blue');

  @override
  void startScan() {
    _channel.invokeMethod('startScan')
        .then((_) => print('startScan invokeMethod success'));
  }

  @override
  void stopScan() {
    _channel.invokeMethod('stopScan')
        .then((_) => print('stopScan invokeMethod success'));
  }
}
