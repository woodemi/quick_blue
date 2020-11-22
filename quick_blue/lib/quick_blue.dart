import 'dart:async';
import 'dart:typed_data';

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

  static void setConnectionHandler(OnConnectionChanged onConnectionChanged) {
    QuickBluePlatform.instance.onConnectionChanged = onConnectionChanged;
  }

  static void discoverServices(String deviceId) => QuickBluePlatform.instance.discoverServices(deviceId);

  static void setServiceHandler(OnServiceDiscovered onServiceDiscovered) {
    QuickBluePlatform.instance.onServiceDiscovered = onServiceDiscovered;
  }

  static Future<void> setNotifiable(String deviceId, String service, String characteristic, bool notifiable) {
    return QuickBluePlatform.instance.setNotifiable(deviceId, service, characteristic, notifiable);
  }

  static void setValueHandler(OnValueChanged onValueChanged) {
    QuickBluePlatform.instance.onValueChanged = onValueChanged;
  }

  static Future<void> writeValue(String deviceId, String service, String characteristic, Uint8List value) {
    return QuickBluePlatform.instance.writeValue(deviceId, service, characteristic, value);
  }
}
