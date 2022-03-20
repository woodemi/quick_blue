import 'dart:async';
import 'dart:typed_data';

import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';
import 'package:bluez/bluez.dart';
import 'package:collection/collection.dart';

class QuickBlueLinux extends QuickBluePlatform {
  bool isInitialized = false;

  final BlueZClient _client = BlueZClient();

  BlueZAdapter? _activeAdapter;

  Future<void> _ensureInitialized() async {
    if (!isInitialized) {
      await _client.connect();

      _activeAdapter ??= _client.adapters.firstWhereOrNull((adapter) => adapter.powered);

      isInitialized = true;
    }
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    await _ensureInitialized();
    print('isBluetoothAvailable invoke success');

    return _activeAdapter != null;
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

  // FIXME Close
  final StreamController<dynamic> _scanResultController = StreamController.broadcast();

  @override
  Stream get scanResultStream => _scanResultController.stream;

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
