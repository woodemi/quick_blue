library quick_blue_web;

// ignore_for_file: override_on_non_overriding_member
import 'dart:async';
import 'dart:typed_data';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlueWeb extends QuickBluePlatform {
  @override
  void connect(String deviceId) {}

  @override
  void disconnect(String deviceId) {}

  @override
  void discoverServices(String deviceId) {
  }

  @override
  Future<bool> isBluetoothAvailable() {
    throw UnimplementedError();
  }

  @override
  Future<void> readValue(
      String deviceId, String service, String characteristic) {
    throw UnimplementedError();
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) {
    throw UnimplementedError();
  }

  @override
  Stream get scanResultStream => throw UnimplementedError();

  @override
  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty) {
    throw UnimplementedError();
  }

  @override
  void startScan({List<Object> optionalServices = const []}) {
  }

  @override
  void stopScan() {
  }

  @override
  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) {
    throw UnimplementedError();
  }
}
