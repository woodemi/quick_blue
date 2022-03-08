import 'dart:async';
import 'dart:typed_data';

import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

import 'models.dart';

export 'models.dart';

export 'package:quick_blue_platform_interface/models.dart';

class QuickBlue {
  static void setLogLevel(QuickBlueLogLevel level) =>
      QuickBluePlatform.instance.setLogLevel(level);

  static Future<bool> isBluetoothAvailable() =>
      QuickBluePlatform.instance.isBluetoothAvailable();

  static void startScan() => QuickBluePlatform.instance.startScan();

  static void stopScan() => QuickBluePlatform.instance.stopScan();

  static Stream<BlueScanResult> get scanResultStream {
    return QuickBluePlatform.instance.scanResultStream
      .map((item) => BlueScanResult.fromMap(item));
  }

  static void connect(String deviceId) => QuickBluePlatform.instance.connect(deviceId);

  static void disconnect(String deviceId) => QuickBluePlatform.instance.disconnect(deviceId);

  static void setConnectionHandler(OnConnectionChanged? onConnectionChanged) {
    QuickBluePlatform.instance.onConnectionChanged = onConnectionChanged;
  }

  static void discoverServices(String deviceId) => QuickBluePlatform.instance.discoverServices(deviceId);

  static void setServiceHandler(OnServiceDiscovered? onServiceDiscovered) {
    QuickBluePlatform.instance.onServiceDiscovered = onServiceDiscovered;
  }

  static Future<void> setNotifiable(String deviceId, String service, String characteristic, BleInputProperty bleInputProperty) {
    return QuickBluePlatform.instance.setNotifiable(deviceId, service, characteristic, bleInputProperty);
  }

  static void setValueHandler(OnValueChanged? onValueChanged) {
    QuickBluePlatform.instance.onValueChanged = onValueChanged;
  }

  static Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) {
    return QuickBluePlatform.instance.writeValue(
        deviceId, service, characteristic, value, bleOutputProperty);
  }

  static Future<Uint8List?> readValue(
      String deviceId, String service, String characteristic) async {
    return await QuickBluePlatform.instance
        .readValue(deviceId, service, characteristic);
  }

  static Future<int> requestMtu(String deviceId, int expectedMtu) => QuickBluePlatform.instance.requestMtu(deviceId, expectedMtu);
}
