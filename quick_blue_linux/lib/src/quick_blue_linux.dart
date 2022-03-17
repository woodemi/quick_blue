// ignore_for_file: unused_field
// ignore_for_file: override_on_non_overriding_member

library quick_blue_linux;

import 'dart:async';
import 'dart:typed_data';
import 'package:bluez/bluez.dart';
import 'package:quick_blue_linux/src/model/BlueScanResultParse.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlueLinux extends QuickBluePlatform {
  bool isInitialised = false;
  BlueZClient _client = BlueZClient();

  initBluez() async {
    if (!isInitialised) {
      await _client.connect();
      QuickBlueLinux();
      isInitialised = true;
    }
  }

  StreamSubscription<BlueZDevice>? _deviceAddedSubscription;
  StreamSubscription<BlueZDevice>? _deviceRemovedSubscription;

  final _scanController = StreamController.broadcast();
  final _charValueUpdateController = StreamController.broadcast();

  QuickBlueLinux() {
    _deviceAddedSubscription = _client.deviceAdded.listen(_deviceAdded);
    _deviceRemovedSubscription = _client.deviceRemoved.listen(_deviceRemoved);

    _scanController.onListen = () {
      _client.devices.forEach(_sendDeviceState);
    };
  }

  ///`Completed`

  @override
  Future<bool> isBluetoothAvailable() async {
    await initBluez();
    if (_client.adapters.isEmpty) {
      return false;
    }

    for (final adapter in _client.adapters) {
      if (adapter.powered) {
        return true;
      }
    }

    return false;
  }

  @override
  Stream get scanResultStream => _scanController.stream;

  @override
  void startScan({List<Object> optionalServices = const []}) async {
    await initBluez();
    print('Started Scanning');
    for (final adapter in _client.adapters) {
      adapter
        ..setDiscoveryFilter(
            uuids: optionalServices.map((uuid) => uuid.toString()).toList())
        ..startDiscovery();
    }
  }

  @override
  void stopScan() async {
    await initBluez();
    print('Stopped Scanning');
    for (final adapter in _client.adapters) {
      adapter.stopDiscovery();
    }
  }

  @override
  void connect(String deviceId) async {
    await initBluez();
    final device = _getDeviceWithId(deviceId);
    if (device == null) {
      throw 'No such device $deviceId';
    } else {
      device.connect();
      _checkDeviceConnectionState(device);
    }
  }

  @override
  void disconnect(String deviceId) async {
    await initBluez();
    final device = _getDeviceWithId(deviceId);
    if (device == null) {
      throw Exception('No such device $deviceId');
    }
    await device.disconnect();
    _checkDeviceConnectionState(device);
  }

  @override
  void discoverServices(String deviceId) {
    final device = _getDeviceWithId(deviceId);
    if (device == null) {
      throw Exception('No such device $deviceId');
    }

    OnServiceDiscovered(deviceId, device.gattServices);
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    BlueZDevice? device = _getDeviceWithId(deviceId);
    if (device == null) {
      throw Exception('No such device $deviceId');
    }

    ///Not implemented yet
    return expectedMtu;
  }

  @override
  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) async {
    BlueZGattCharacteristic? c =
        _getCharacteristic(deviceId, service, characteristic);

    if (c == null) {
      throw Exception('No such characteristic');
    }

    await c.writeValue(value);
  }

  @override
  Future<void> readValue(
      String deviceId, String service, String characteristic) async {
    BlueZGattCharacteristic? c =
        _getCharacteristic(deviceId, service, characteristic);

    if (c == null) {
      throw 'No such characteristic';
    } else {
      c.readValue().then((value) {
        OnCharactersticValue(deviceId, characteristic, value as Uint8List);
      }).catchError((Object error) {
        throw error.toString();
      });
    }
  }

  ///`Work In Progress`

  @override
  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty) async {
    BlueZGattCharacteristic? c =
        _getCharacteristic(deviceId, service, characteristic);

    if (c == null) {
      throw 'No such characteristic';
    } else {
      ///TODO: Convert This To Stream
      c.readValue().then((value) {
        OnCharactersticValue(deviceId, characteristic, value as Uint8List);
      }).catchError((Object error) {
        throw error.toString();
      });
    }
  }

  ///`Helper Methods`

  BlueZDevice? _getDeviceWithId(String id) {
    for (final device in _client.devices) {
      if (device.address == id) {
        return device;
      }
    }
    return null;
  }

  Future<void> onConnectionChange(
      String deviceId, BlueConnectionState connectionState) async {
    onConnectionChanged?.call(deviceId, connectionState);
  }

  Future<void> OnServiceDiscovered(
      String deviceId, List<BlueZGattService> services) async {
    for (var s in services) {
      onServiceDiscovered?.call(deviceId, s.uuid.toString());
    }
  }

  Future<void> OnCharactersticValue(
      String deviceId, String characteristicId, Uint8List value) async {
    onValueChanged?.call(deviceId, characteristicId, value);
  }

  BlueZGattCharacteristic? _getCharacteristic(
      String deviceId, String serviceID, String charID) {
    final device = _getDeviceWithId(deviceId);
    if (device == null) {
      return null;
    }

    for (final service in device.gattServices) {
      if (service.uuid.toString() == serviceID) {
        for (final c in service.characteristics) {
          if (c.uuid.toString() == charID) {
            return c;
          }
        }
      }
    }

    return null;
  }

  void _deviceAdded(BlueZDevice device) {
    device.propertiesChanged
        .listen((properties) => _deviceChanged(device, properties));
    _deviceChanged(device, []);
  }

  void _deviceChanged(BlueZDevice device, List<String> properties) {
    _checkDeviceConnectionState(device);
    _sendDeviceState(device);
  }

  void _sendDeviceState(BlueZDevice device) {
    BlueScanResultParse result = BlueScanResultParse(
      deviceId: device.address,
      name: device.alias != '' ? device.alias : device.name,
      manufacturerData: Uint8List(0),
      rssi: device.rssi,
    );
    _scanController.add(result.toMap());
  }

  void _deviceRemoved(BlueZDevice device) {}

  void _checkDeviceConnectionState(BlueZDevice device) {
    BlueConnectionState connectionState = device.connected
        ? BlueConnectionState.connected
        : BlueConnectionState.disconnected;
    onConnectionChange(device.address, connectionState);
  }
}
