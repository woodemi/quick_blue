import 'dart:typed_data';

import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlueLinux extends QuickBluePlatform {
  @override
  Future<bool> isBluetoothAvailable() {
    // TODO: implement isBluetoothAvailable
    throw UnimplementedError();
  }

  @override
  void startScan() {
    // TODO: implement startScan
    throw UnimplementedError();
  }

  @override
  void stopScan() {
    // TODO: implement stopScan
    throw UnimplementedError();
  }

  @override
  // TODO: implement scanResultStream
  Stream get scanResultStream => throw UnimplementedError();

  @override
  void connect(String deviceId) {
    // TODO: implement connect
    throw UnimplementedError();
  }

  @override
  void disconnect(String deviceId) {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  void discoverServices(String deviceId) {
    // TODO: implement discoverServices
    throw UnimplementedError();
  }

  @override
  Future<void> setNotifiable(String deviceId, String service, String characteristic, BleInputProperty bleInputProperty) {
    // TODO: implement setNotifiable
    throw UnimplementedError();
  }

  @override
  Future<void> readValue(String deviceId, String service, String characteristic) {
    // TODO: implement readValue
    throw UnimplementedError();
  }

  @override
  Future<void> writeValue(String deviceId, String service, String characteristic, Uint8List value, BleOutputProperty bleOutputProperty) {
    // TODO: implement writeValue
    throw UnimplementedError();
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) {
    // TODO: implement requestMtu
    throw UnimplementedError();
  }
}
