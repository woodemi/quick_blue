library quick_blue_platform_interface;

import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models.dart';

export 'method_channel_quick_blue.dart';
export 'models.dart';

typedef QuickLogger = Logger;

typedef OnConnectionChanged = void Function(
    String deviceId, BlueConnectionState state);

typedef OnServiceDiscovered = void Function(
    String deviceId, String serviceId, List<String> characteristicIds);

typedef OnRssiRead = void Function(String deviceId, int rssi);

typedef OnValueChanged = void Function(
    String deviceId, String characteristicId, Uint8List value);

abstract class QuickBluePlatform extends PlatformInterface {
  QuickBluePlatform() : super(token: _token);

  static final Object _token = Object();

  static late QuickBluePlatform _instance;

  static QuickBluePlatform get instance => _instance;

  static set instance(QuickBluePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void setLogger(QuickLogger logger);

  Future<bool> isBluetoothAvailable();

  void reinit();

  void startScan();

  void stopScan();

  void requestLatency(String deviceId, BlePackageLatency priority);

  Stream<dynamic> get scanResultStream;

  Future<void> connect(String deviceId, {bool? auto});

  Future<void> disconnect(String deviceId);

  OnConnectionChanged? onConnectionChanged;

  void discoverServices(String deviceId);

  OnServiceDiscovered? onServiceDiscovered;

  OnRssiRead? onRssiRead;

  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty);

  OnValueChanged? onValueChanged;

  Future<void> readValue(
      String deviceId, String service, String characteristic);

  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty);

  Future<void> readRssi(String deviceId);

  Future<int> requestMtu(String deviceId, int expectedMtu);
}
