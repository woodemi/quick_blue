import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:quick_blue_linux/quick_blue_linux.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

import 'models.dart';

export 'package:quick_blue_platform_interface/models.dart';

export 'models.dart';

bool _manualDartRegistrationNeeded = true;

QuickBluePlatform get _instance {
  // This is to manually endorse Dart implementations until automatic
  // registration of Dart plugins is implemented. For details see
  // https://github.com/flutter/flutter/issues/52267.
  if (_manualDartRegistrationNeeded) {
    // Only do the initial registration if it hasn't already been overridden
    // with a non-default instance.
    QuickBluePlatform.instance =
        Platform.isLinux ? QuickBlueLinux() : MethodChannelQuickBlue();
    _manualDartRegistrationNeeded = false;
  }

  return QuickBluePlatform.instance;
}

class QuickBlue {
  static QuickBluePlatform _platform = _instance;

  static setInstance(QuickBluePlatform platform) {
    QuickBluePlatform.instance = platform;
    _platform = QuickBluePlatform.instance;
  }

  static void setLogger(QuickLogger logger) => _platform.setLogger(logger);

  static Future<bool> isBluetoothAvailable() =>
      _platform.isBluetoothAvailable();

  static reinit() => _platform.reinit();

  static void startScan() => _platform.startScan();

  static void stopScan() => _platform.stopScan();

  static Stream<BlueScanResult> get scanResultStream =>
      _platform.scanResultStream.map((item) => BlueScanResult.fromMap(item));

  static Future<void> connect(String deviceId, {bool? auto}) {
    return _platform.connect(deviceId, auto: auto);
  }

  static Future<void> disconnect(String deviceId) =>
      _platform.disconnect(deviceId);

  static void setConnectionHandler(OnConnectionChanged? onConnectionChanged) =>
      _platform.onConnectionChanged = onConnectionChanged;

  static void discoverServices(String deviceId) =>
      _platform.discoverServices(deviceId);

  static void setServiceHandler(OnServiceDiscovered? onServiceDiscovered) =>
      _platform.onServiceDiscovered = onServiceDiscovered;

  static void setRssiHandler(OnRssiRead? onRssiRead) {
    _platform.onRssiRead = onRssiRead;
  }

  static Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty) {
    return _platform.setNotifiable(
        deviceId, service, characteristic, bleInputProperty);
  }

  static void setValueHandler(OnValueChanged? onValueChanged) {
    _platform.onValueChanged = onValueChanged;
  }

  static Future<void> readValue(
      String deviceId, String service, String characteristic) {
    return _platform.readValue(deviceId, service, characteristic);
  }

  static Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) {
    return _platform.writeValue(
        deviceId, service, characteristic, value, bleOutputProperty);
  }

  static Future<int> requestMtu(String deviceId, int expectedMtu) =>
      _platform.requestMtu(deviceId, expectedMtu);

  static Future<void> readRssi(String deviceId) => _platform.readRssi(deviceId);

  /// set the interval between ble packages
  /// The behaviour can vary from platfrom to platform
  static void requestLatency(String deviceId, BlePackageLatency latency) =>
      _platform.requestLatency(deviceId, latency);
}
