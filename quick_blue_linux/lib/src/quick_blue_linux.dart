library quick_blue_web;

// ignore_for_file: override_on_non_overriding_member
import 'dart:async';
import 'dart:typed_data';
import 'package:bluez/bluez.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlueLinux extends QuickBluePlatform {
  BlueZClient? bluezClient;

  Future<BlueZClient> client() async {
    await initBluez();
    return bluezClient!;
  }

  bool isInitialised = false;

  initBluez() async {
    if (bluezClient == null) {
      bluezClient = BlueZClient();
    }
    if (!isInitialised) {
      await bluezClient!.connect();
      isInitialised = true;
    }
  }

  @override
  void connect(String deviceId) {}

  @override
  void disconnect(String deviceId) {}

  @override
  void discoverServices(String deviceId) {}

  @override
  Future<bool> isBluetoothAvailable() async {
    return true;
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
  void startScan({List<Object> optionalServices = const []}) async {
    ///optional services is for Web implementation
    print('Starting Scan');
    // var devices = await (await client()).devices;
    // for (var device in devices) {
    //   print('Device ${device.address} ${device.alias}');
    // }
    var client = BlueZClient();
    await client.connect();

    for (var device in client.devices) {
      print('Device ${device.address} ${device.alias}');
    }

    await client.close();

    print('Scan Completed');
  }

  @override
  void stopScan() {}

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
