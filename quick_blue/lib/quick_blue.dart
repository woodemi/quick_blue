import 'dart:async';

import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlue {
  static Future<String> get platformVersion =>
      QuickBluePlatform.instance.platformVersion;
}
