import 'dart:typed_data';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';
import 'dart:async';
import 'package:bluez/bluez.dart';
import 'package:collection/collection.dart';

class QuickBlueLinux extends QuickBluePlatform {
  BlueZClient _client = BlueZClient();
  BlueZAdapter? adapter;
  final _scanController = StreamController.broadcast();
  List<DeviceStreamModel> conectedDeviceStreamList = [];
  bool isInitialised = false;

  _ensureInitialized() async {
    if (!isInitialised) {
      await _client.connect();
      _client.deviceAdded.listen((device) {
        device.manufacturerData;
        _scanController.add({
          'deviceId': device.address,
          'name': device.alias,
          'manufacturerData': _getManufatureData(device.manufacturerData),
          'rssi': device.rssi,
        });
      });
      _client.deviceRemoved.listen(_checkDeviceConnectionState);
      isInitialised = true;
    }
    if (adapter == null)
      adapter = _client.adapters.firstWhereOrNull((element) => element.powered);
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    await _ensureInitialized();
    return adapter != null;
  }

  @override
  Stream get scanResultStream => _scanController.stream;

  @override
  void startScan() async {
    await _ensureInitialized();
    print('Started Scanning');
    adapter?.startDiscovery();
    _client.devices.forEach((device) {
      _scanController.add({
        'deviceId': device.address,
        'name': device.alias,
        'manufacturerData': _getManufatureData(device.manufacturerData),
        'rssi': device.rssi,
      });
    });
  }

  @override
  void stopScan() async {
    await _ensureInitialized();
    print('Stopped Scanning');
    adapter?.stopDiscovery();
  }

  @override
  void connect(String deviceId) async {
    await _ensureInitialized();
    print('Try Connecting');
    final device = _getDeviceWithId(deviceId);
    if (device == null) {
      throw 'No such device $deviceId';
    }
    await device.connect();
    _managePropertyStream(device);
  }

  @override
  void disconnect(String deviceId) async {
    await _ensureInitialized();
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
    device.gattServices.forEach((s) {
      onServiceDiscovered?.call(deviceId, s.uuid.toString());
    });
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) =>
      throw UnimplementedError();

  @override
  Future<void> writeValue(
      String deviceId,
      String service,
      String characteristic,
      Uint8List value,
      BleOutputProperty bleOutputProperty) async {
    BlueZGattCharacteristic c =
        _getCharacteristic(deviceId, service, characteristic);
    await c.writeValue(value);
  }

  @override
  Future<void> readValue(
      String deviceId, String service, String characteristic) async {
    BlueZGattCharacteristic c =
        _getCharacteristic(deviceId, service, characteristic);
    final value = await c.readValue();
    onValueChanged?.call(deviceId, characteristic, Uint8List.fromList(value));
  }

  @override
  Future<void> setNotifiable(String deviceId, String service,
          String characteristic, BleInputProperty bleInputProperty) async =>
      throw UnimplementedError();

  ///`Helper Methods`

  BlueZDevice? _getDeviceWithId(String id) =>
      _client.devices.firstWhereOrNull((e) => e.address == id);

  _managePropertyStream(BlueZDevice device) {
    ///We Might Improve Logic , open for Suggestions
    ///When we Connect to a Device , Store Its Value to list
    ///because a connected Device update its status (To auto Update Disconnection Handle) in a stream
    ///of `device.propertiesChanged ` , so to get rid of running multiple Streams
    ///we can try out something like this
    ///
    DeviceStreamModel? streamModel = conectedDeviceStreamList
        .firstWhereOrNull((element) => element.deviceId == device.address);
    if (streamModel != null) {
      streamModel.devicePropertyStream.cancel();
      conectedDeviceStreamList.remove(streamModel);
    }

    late StreamSubscription deviceProperties;

    ///this propertiseChanged gives us a list of Strings
    ///like this [ServicesResolved] , [ServicesResolved,Connected] , [Connected]
    ///if this list contains connected , means this device is disconnected , so we can
    ///close its stream
    deviceProperties = device.propertiesChanged.listen((event) {
      _checkDeviceConnectionState(device);
      if (event.contains('Connected')) {
        deviceProperties.cancel();
      }
    });

    ///Scaving this model to a list to cancel streamSubscription when this method will be called again
    conectedDeviceStreamList
        .add(DeviceStreamModel(device.address, deviceProperties));
  }

  BlueZGattCharacteristic _getCharacteristic(
      String deviceId, String serviceID, String characteristicId) {
    BlueZDevice? device = _getDeviceWithId(deviceId);
    if (device == null) throw 'No device Found with Id : $deviceId';
    for (final service in device.gattServices) {
      if (service.uuid.toString() == serviceID) {
        for (final c in service.characteristics) {
          if (c.uuid.toString() == characteristicId) {
            return c;
          }
        }
      }
    }
    throw Exception('No such characteristic : $characteristicId');
  }

  void _checkDeviceConnectionState(
          BlueZDevice device) =>
      onConnectionChanged?.call(
          device.address,
          device.connected
              ? BlueConnectionState.connected
              : BlueConnectionState.disconnected);

  Uint8List _getManufatureData(
      Map<BlueZManufacturerId, List<int>> manufacturerData) {
    if (manufacturerData.isEmpty) return Uint8List(0);
    final sorted = manufacturerData.entries.toList()
      ..sort((a, b) => a.key.id - b.key.id);
    return Uint8List.fromList(sorted.first.value);
  }
}

class DeviceStreamModel {
  String deviceId;
  StreamSubscription devicePropertyStream;
  DeviceStreamModel(this.deviceId, this.devicePropertyStream);
}
