import 'dart:async';

import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

import 'models.dart';

export 'models.dart';

export 'package:quick_blue_platform_interface/models.dart';

class QuickBlue {
  static void startScan() => QuickBluePlatform.instance.startScan();

  static void stopScan() => QuickBluePlatform.instance.stopScan();

  static Stream<BlueScanResult> get scanResultStream {
    return QuickBluePlatform.instance.scanResultStream
      .map((item) => BlueScanResult.fromMap(item));
  }

  static void connect(String deviceId) => QuickBluePlatform.instance.connect(deviceId);

  static void disconnect(String deviceId) => QuickBluePlatform.instance.disconnect(deviceId);

  static void setConnectionHandler(OnConnectionChanged onConnectionChanged) => QuickBluePlatform.instance.setConnectionHandler(onConnectionChanged);
}
