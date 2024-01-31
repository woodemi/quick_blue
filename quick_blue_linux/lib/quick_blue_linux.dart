import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluez/bluez.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class QuickBlueLinux extends QuickBluePlatform {
  bool isInitialized = false;

  final BlueZClient _client = BlueZClient();

  bool _valueReadTriggerActive = false;

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
  void reinit() {}

  @override
  void startScan() async {
    await _ensureInitialized();
    _log('startScan invoke success');

    try {
      await _activeAdapter!.startDiscovery();
    } catch (e) {
      _log('scan was already running');
      if (!e.toString().contains("org.bluez.Error.InProgress")) {
        rethrow;
      }
    }
    _client.devices.where((d) => d.rssi < 0).forEach(_onDeviceAdd);
  }

  @override
  void stopScan() async {
    await _ensureInitialized();
    _log('stopScan invoke success');

    try {
      _activeAdapter!.stopDiscovery();
    } catch (e) {
      _log("no scan was running");
    }
  }

  BlueZDevice? _device(String id) =>
      _client.devices.firstWhereOrNull((e) => e.address == id);

  // FIXME Close
  final StreamController<dynamic> _scanResultController =
      StreamController.broadcast();

  @override
  Stream get scanResultStream => _scanResultController.stream;

  void _onDeviceAdd(BlueZDevice device) => _scanResultController.add({
        'deviceId': device.address,
        'name': device.alias,
        'manufacturerDataHead': device.manufacturerDataHead,
        'rssi': device.rssi,
      });

  @override
  void connect(String deviceId, {bool? auto}) {
    _device(deviceId)!.connect().whenComplete(() {
      if (onConnectionChanged != null) {
        onConnectionChanged!(deviceId, BlueConnectionState.connected);
      }
    });
    _device(deviceId)!.setTrusted(true);
  }

  @override
  void disconnect(String deviceId) {
    _device(deviceId)!.disconnect().whenComplete(() {
      if (onConnectionChanged != null) {
        onConnectionChanged!(deviceId, BlueConnectionState.disconnected);
      }
    });
  }

  @override
  void discoverServices(String deviceId) {
    if (onServiceDiscovered == null) return;
    _device(deviceId)!.gattServices.forEach((e) {
      print("e.uuid: " + e.characteristics.join(" - "));
      onServiceDiscovered!(deviceId, e.uuid.toString(),
          e.characteristics.map((e) => e.uuid.toString()).toList());
    });
  }

  BlueZGattCharacteristic? _findService(
      String deviceId, String service, String characteristic) {
    return _device(deviceId)
        ?.gattServices
        .firstWhereOrNull((s) => s.uuid.toString() == service)
        ?.characteristics
        .firstWhereOrNull((char) => char.uuid.toString() == characteristic);
  }

  @override
  Future<void> setNotifiable(String deviceId, String service,
      String characteristic, BleInputProperty bleInputProperty) async {
    await _findService(deviceId, service, characteristic)!.startNotify();
    _initManualRead(deviceId, service, characteristic);
    /*
    _client.devices
        .firstWhere((e) => e.address == deviceId)
        .gattServices
        .firstWhereOrNull((e) => e == service)
        ?.characteristics
        .firstWhereOrNull((e) => e == characteristic)
        ?.acquireNotify()
        .then((v) => v.socket.forEach((event) {
              if (event == RawSocketEvent.read)
                onValueChanged?.call(service, characteristic, v.socket.read()!);
            }));
        */
  }

  _initManualRead(
      String deviceId, String service, String characteristic) async {
    if (_valueReadTriggerActive) return;
    _valueReadTriggerActive = true;
    while (true) {
      try {
        await readValue(deviceId, service, characteristic);
      } catch (e) {
        if (e.toString().contains("org.bluez.Error.Failed: Not connected")) {
          _valueReadTriggerActive = false;
          return;
        }
      }
    }
  }

  @override
  Future<void> readValue(
          String deviceId, String service, String characteristic) async =>
      onValueChanged?.call(
          service,
          characteristic,
          Uint8List.fromList(
              await _findService(deviceId, service, characteristic)!
                  .readValue()));

  @override
  Future<void> writeValue(
          String deviceId,
          String service,
          String characteristic,
          Uint8List value,
          BleOutputProperty bleOutputProperty) async =>
      await _findService(deviceId, service, characteristic)!
          .writeValue(value, type: bleOutputProperty.toBluez());

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    _log("request mtu is not supported on linux");
    return -1;
  }

  @override
  Future<void> readRssi(String deviceId) async {
    onRssiRead?.call(deviceId, _device(deviceId)!.rssi);
  }

  @override
  void requestLatency(String deviceId, BlePackageLatency priority) {
    _log("request latency is not supported on linux");
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

extension ToBluez on BleOutputProperty {
  BlueZGattCharacteristicWriteType toBluez() =>
      this == BleOutputProperty.withResponse
          ? BlueZGattCharacteristicWriteType.request
          : BlueZGattCharacteristicWriteType.command;
}
