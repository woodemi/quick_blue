import 'dart:async';
import 'dart:typed_data';

import 'package:bluez/bluez.dart';
import 'package:collection/collection.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlueLinux extends QuickBluePlatform {
  bool isInitialized = false;

  final BlueZClient _client = BlueZClient();

  BlueZAdapter? _activeAdapter;

  Future<void> _ensureInitialized() async {
    if (!isInitialized) {
      await _client.connect();

      _activeAdapter ??=
          _client.adapters.firstWhereOrNull((adapter) => adapter.powered);

      _client.deviceAdded.listen(_onDeviceAdd);

      isInitialized = true;
    }
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    await _ensureInitialized();

    return _activeAdapter != null;
  }

  @override
  Future<void> startScan() async {
    await _ensureInitialized();

    _activeAdapter!.startDiscovery();
    _client.devices.forEach(_onDeviceAdd);
  }

  @override
  Future<void> stopScan() async {
    await _ensureInitialized();

    _activeAdapter!.stopDiscovery();
  }

  // FIXME Close
  final StreamController<dynamic> _scanResultController =
      StreamController.broadcast();

  @override
  Stream get scanResultStream => _scanResultController.stream;

  void _onDeviceAdd(BlueZDevice device) {
    _scanResultController.add({
      'deviceId': device.address,
      'name': device.alias,
      'manufacturerDataHead': device.manufacturerDataHead,
      'rssi': device.rssi,
    });
  }

  @override
  Future<void> connect(String deviceId) {
    // TODO: implement connect
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect(String deviceId) {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Future<void> discoverServices(String deviceId) {
    // TODO: implement discoverServices
    throw UnimplementedError();
  }

  @override
  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty) {
    // TODO: implement setNotifiable
    throw UnimplementedError();
  }

  @override
  Future<void> readValue(
      String deviceId, String service, String characteristic) {
    // TODO: implement readValue
    throw UnimplementedError();
  }

  @override
  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) {
    // TODO: implement writeValue
    throw UnimplementedError();
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) {
    // TODO: implement requestMtu
    throw UnimplementedError();
  }
}

extension BlueZDeviceExtension on BlueZDevice {
  Uint8List get manufacturerDataHead {
    if (manufacturerData.isEmpty) return Uint8List(0);

    final sorted = manufacturerData.entries.toList()
      ..sort((a, b) => a.key.id - b.key.id);
    return Uint8List.fromList(sorted.first.value);
  }
}
