import 'dart:async';

import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlue {
  static void startScan() => QuickBluePlatform.instance.startScan();

  static void stopScan() => QuickBluePlatform.instance.stopScan();
}
