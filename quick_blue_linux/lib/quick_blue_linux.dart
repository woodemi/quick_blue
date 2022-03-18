
import 'dart:async';

import 'package:flutter/services.dart';

class QuickBlueLinux {
  static const MethodChannel _channel =
      const MethodChannel('quick_blue_linux');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
