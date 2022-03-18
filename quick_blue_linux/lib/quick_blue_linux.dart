// ignore_for_file: unused_field

import 'dart:typed_data';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';
import 'dart:async';
import 'package:bluez/bluez.dart';

class QuickBlueLinux extends QuickBluePlatform {
  ///`Bluez Client`
  BlueZClient _client = BlueZClient();

  ///`Streams`
  StreamSubscription<BlueZDevice>? _deviceAddedSubscription;
  StreamSubscription<BlueZDevice>? _deviceRemovedSubscription;
  final _scanController = StreamController.broadcast();
  final _charValueUpdateController = StreamController.broadcast();

  ///`Initialise Bluez`
  bool isInitialised = false;
  initBluez() async {
    if (!isInitialised) {
      await _client.connect();
      print('Quick_Ble_Linux_Initialised');

      _deviceAddedSubscription = _client.deviceAdded.listen(_deviceAdded);
      _deviceRemovedSubscription = _client.deviceRemoved.listen(_deviceRemoved);

      _scanController.onListen = () {
        _client.devices.forEach(_sendDeviceState);
      };

      _charValueUpdateController.onListen = () {};
      _charValueUpdateController.onCancel = () {};

      isInitialised = true;
    }
  }

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
      try {
        adapter.startDiscovery();
      } catch (e) {
        print('Start Scan Error : $e');
      }
    }
  }

  @override
  void stopScan() async {
    await initBluez();
    print('Stopped Scanning');
    for (final adapter in _client.adapters) {
      try {
        adapter.stopDiscovery();
      } catch (e) {
        print('Start Scan Error : $e');
      }
    }
  }

  @override
  void connect(String deviceId) async {
    await initBluez();
    print('Try Connecting');
    final device = _getDeviceWithId(deviceId);
    if (device == null) {
      throw 'No such device $deviceId';
    } else {
      await device.connect();
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
        Uint8List data = Uint8List.fromList(value);
        OnCharactersticValue(deviceId, characteristic, data);
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
      if (bleInputProperty.value == 'notification') {
        ///Subscribe to the characteristic
        ///TODO: Add Stream Here ,checkout charactersticStream Method
        var event = await c.readValue();
        Uint8List data = Uint8List.fromList(event);
        OnCharactersticValue(deviceId, characteristic, data);
      } else if (bleInputProperty.value == 'disabled') {
        ///UnSubscribe to the characteristic

      }
    }
  }

  ///`Helper Methods`

  charactersticStream(BlueZGattCharacteristic c, {int autoStop = 5}) {
    // return RepeatStream((int repeatCount) => Stream.value(c.value), autoStop)
    //     .distinctUnique()
    //     .doOnListen(() => c.startNotify())
    //     .doOnDone(() => c.stopNotify());
    //return Stream.periodic(Duration(seconds: 1));
  }

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
      name: device.alias,
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

///`Scan Model`
class BlueScanResultParse {
  String name;
  String deviceId;
  Uint8List manufacturerData;
  int rssi;

  BlueScanResultParse(
      {required this.name,
      required this.deviceId,
      required this.manufacturerData,
      required this.rssi});

  BlueScanResultParse.fromMap(map)
      : name = map['name'],
        deviceId = map['deviceId'],
        manufacturerData = map['manufacturerData'],
        rssi = map['rssi'];

  Map toMap() => {
        'name': name,
        'deviceId': deviceId,
        'manufacturerData': manufacturerData,
        'rssi': rssi,
      };
}
