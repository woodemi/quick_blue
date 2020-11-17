import 'dart:async';

import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

import 'models.dart';

export 'models.dart';

class QuickBlue {
  static void startScan() => QuickBluePlatform.instance.startScan();

  static void stopScan() => QuickBluePlatform.instance.stopScan();

  static Stream<BlueScanResult> get scanResultStream {
    return QuickBluePlatform.instance.scanResultStream
      .map((item) => BlueScanResult.fromMap(item));
  }
}
