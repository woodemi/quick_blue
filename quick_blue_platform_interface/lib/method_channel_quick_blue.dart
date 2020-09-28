import 'package:flutter/services.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class MethodChannelQuickBlue extends QuickBluePlatform {
  static const MethodChannel _channel = const MethodChannel('quick_blue');

  @override
  Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
