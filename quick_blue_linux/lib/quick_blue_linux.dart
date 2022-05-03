import 'dart:async';
import 'dart:typed_data';

import 'package:bluez/bluez.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlueLinux extends QuickBluePlatform {
  bool isInitialized = false;

  final BlueZClient _client = BlueZClient();

  BlueZAdapter? _activeAdapter;
  OnServiceDiscovered? onServiceDiscovered;

  Future<void> _ensureInitialized() async {
    if (!isInitialized) {
      await _client.connect();

      _activeAdapter ??=
          _client.adapters.firstWhereOrNull((adapter) => adapter.powered);
      if (_activeAdapter == null && _client.adapters.length >= 1) {
        _activeAdapter = _client.adapters[0];
        _activeAdapter?.setPowered(true);
      }

      _client.deviceAdded.listen(_onDeviceAdd);

      isInitialized = true;
    }
  }

  QuickLogger? _logger;

  @override
  void setLogger(QuickLogger logger) {
    _logger = logger;
  }

  void _log(String message, {Level logLevel = Level.INFO}) {
    _logger?.log(logLevel, message);
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    await _ensureInitialized();
    _log('isBluetoothAvailable invoke success');

    return _activeAdapter != null;
  }

  @override
  void startScan() async {
    if (_activeAdapter != null && !_activeAdapter!.discovering) {
      await _ensureInitialized();
      _log('startScan invoke success');

      _activeAdapter!.startDiscovery();
      _client.devices.forEach(_onDeviceAdd);
    }
  }

  @override
  void stopScan() async {
    if (_activeAdapter != null && _activeAdapter!.discovering) {
      await _ensureInitialized();
      _log('stopScan invoke success');

      _activeAdapter!.stopDiscovery();
    }
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
  void connect(String deviceId) {
    var device =
        _client.devices.firstWhere((device) => device.address == deviceId);
    if (!device.paired) {
      device
          .pair()
          .then((voi) => device.connect().then((voi) => {print("Connected!")}));
    } else {
      device.connect().then((voi) => {print("Connected!")});
    }
  }

  @override
  void disconnect(String deviceId) {
    var device =
        _client.devices.firstWhere((device) => device.address == deviceId);
    device.disconnect().then((voi) => {print("Disconnected!")});
  }

  @override
  void discoverServices(String deviceId) {
    var device = _getDeviceById(deviceId);
    if (device != null) {
      print("Services ${device.gattServices.length}");
      for (var gatt_service in device.gattServices) {
        List<String> characteristics = [];
        for (var characteristic in gatt_service.characteristics) {
          characteristics.add(characteristic.uuid.toString());
        }
        this
            .onServiceDiscovered
            ?.call(deviceId, gatt_service.uuid.toString(), characteristics);
      }
    }
  }

  BlueZDevice? _getDeviceById(String deviceId) {
    return _client.devices
        .firstWhere((device) => device.address == deviceId, orElse: null);
  }

  BlueZGattCharacteristic? _getGattCharacteristicById(
      String deviceId, String characteristic) {
    var device = _getDeviceById(deviceId);
    if (device != null) {
      for (var s in device.gattServices) {
        for (var c in s.characteristics) {
          if (c.uuid.toString() == characteristic) {
            return c;
          }
        }
      }
    }
    return null;
  }

  @override
  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty) async {
    var c = _getGattCharacteristicById(deviceId, characteristic);
    if (c != null) {
      if (bleInputProperty == BleInputProperty.disabled) {
        c.stopNotify();
      } else {
        c.startNotify();
      }
    }
  }

  @override
  Future<void> readValue(
      String deviceId, String service, String characteristic) async {
    var c = _getGattCharacteristicById(deviceId, characteristic);
    if (c != null) {
      var data = await c.readValue();
      Uint8List value = Uint8List.fromList(data);
      this.onValueChanged?.call(deviceId, characteristic, value);
    }
  }

  @override
  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) async {
    var c = _getGattCharacteristicById(deviceId, characteristic);
    if (c != null) {
      if (bleOutputProperty == BleOutputProperty.withResponse) {
        await c.writeValue(value,
            type: BlueZGattCharacteristicWriteType.request);
      } else {
        await c.writeValue(value,
            type: BlueZGattCharacteristicWriteType.command);
      }
    }
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    var device = _getDeviceById(deviceId);
    if (device != null) {}
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
