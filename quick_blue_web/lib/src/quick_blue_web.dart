// ignore_for_file: override_on_non_overriding_member

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:js_util';
import 'dart:typed_data';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';
import 'package:quick_blue_web/src/model/BlueScanResultParse.dart';
import 'package:web_blue/web_blue.dart';
import 'package:collection/collection.dart';

class QuickBlueWeb extends QuickBluePlatform {
  StreamController controller = StreamController.broadcast();
  Stream? devices;
  List<BlueDevice> blueDevices = [];

  /// `Completed`

  @override
  Future<bool> isBluetoothAvailable() async {
    bool availability = await blue.getAvailability();
    bool canUse = canUseBlue();
    return availability && canUse;
  }

  @override
  Stream get scanResultStream {
    // This feature will only work if the "Experimental Web Platform features" flag is enabled.
    if (devices == null) devices = controller.stream;
    return devices!;
  }

  @override
  void startScan({optionalServices = const <Object>[]}) {
    try {
      blue
          .requestDevice(RequestOptions(
        optionalServices: optionalServices,
        acceptAllDevices: true,
      ))
          .then((value) {
        BlueDevice blueDevice = value;
        String name = blueDevice.getPropertyT('name');
        String id = blueDevice.getPropertyT('id');
        BlueScanResultParse ble = BlueScanResultParse(
            name: name, deviceId: id, manufacturerData: Uint8List(0), rssi: 0);

        ///Maintaining a `Local List of BlueDevices`
        blueDevices.add(blueDevice);

        ///Add this Device To the `Stream`
        controller.add(ble.toMap());
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void stopScan() {
    ///No Implementation for this on Web
  }

  @override
  void connect(String deviceId) {
    BlueDevice? device = getBlueDevice(deviceId);
    if (device == null) throw 'Device not Found , Please Rescan';

    ///get Device From Device ID
    device.gatt.connect().then((value) {
      onConnectionChange(
          value.getPropertyT('id'), BlueConnectionState.connected);
    }).catchError((error) {
      throw 'device.gatt.connect $error';
    });
  }

  @override
  void disconnect(String deviceId) {
    BlueDevice? device = getBlueDevice(deviceId);
    if (device == null) throw 'Device not Found , Please Rescan';

    ///get Device From Device ID
    device.gatt.disconnect();
    onConnectionChanged?.call(
        device.getPropertyT('id'), BlueConnectionState.disconnected);
  }

  Future<void> onConnectionChange(
      String deviceId, BlueConnectionState connectionState) async {
    onConnectionChanged?.call(deviceId, connectionState);
  }

  Future<void> OnServiceDiscovered(
      String deviceId, List<dynamic> services) async {
    for (var s in services) {
      onServiceDiscovered?.call(deviceId, s);
    }
  }

  Future<void> OnCharactersticValue(
      String deviceId, String characteristicId, Uint8List value) async {
    onValueChanged?.call(deviceId, characteristicId, value);
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    ////IMplement Request MTU
    return 0;
  }

  ///`TODO`
  @override
  void discoverServices(String data) async {
    ///pass deviceId , with service Seprating by ,
    try {
      String deviceId = data.split(',')[0];
      String serviceId = data.split(',')[1];

      BlueDevice? device = getBlueDevice(deviceId);
      if (device == null) throw 'Device not Found , Please Rescan';

      //var promise = device.callMethod('getPrimaryServices', [serviceId]);
      // promiseToFuture(promise).then((result) {
      //   print(result);
      // });

      var service =
          await device.gatt.getPrimaryService(BlueUUID.getService(serviceId));

      OnServiceDiscovered(deviceId, [service.getPropertyT('uuid')]);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Future<void> readValue(
      String deviceId, String serviceId, String characteristicId) async {
    BlueRemoteGATTCharacteristic? characteristic =
        await getCharacteristic(deviceId, serviceId, characteristicId);

    ByteData? byteData = await characteristic?.readValue();
    Uint8List? value = byteData?.buffer.asUint8List();

    OnCharactersticValue(deviceId, characteristicId, value ?? Uint8List(0));
  }

  @override
  Future<void> setNotifiable(String deviceId, String serviceId,
      String characteristicId, BleInputProperty bleInputProperty) async {
    BlueRemoteGATTCharacteristic? characteristic =
        await getCharacteristic(deviceId, serviceId, characteristicId);

    characteristic!.subscribeValueChanged(_handleValueChanged);
  }

  @override
  Future<void> writeValue(
      String deviceId,
      String serviceId,
      String characteristicId,
      Uint8List value,
      BleOutputProperty bleOutputProperty) async {
    BlueRemoteGATTCharacteristic? characteristic =
        await getCharacteristic(deviceId, serviceId, characteristicId);

    bleOutputProperty.value == 'withResponse'
        ? characteristic?.writeValueWithResponse(value)
        : characteristic?.writeValueWithoutResponse(value);
  }

  ///`Helper Methods`
  ///
  final EventListener _handleValueChanged = allowInterop((event) {
    print(event);
  });
  BlueDevice? getBlueDevice(String id) => blueDevices
      .firstWhereOrNull((element) => element.getPropertyT('id') == id);

  Future<BlueRemoteGATTCharacteristic?> getCharacteristic(
      String id, String serviceId, String characteristicId) async {
    try {
      BlueDevice? device = getBlueDevice(id);
      if (device == null) throw 'Device not Found , Please Rescan';

      var service =
          await device.gatt.getPrimaryService(BlueUUID.getService(serviceId));
      var characteristic = await service
          .getCharacteristic(BlueUUID.getCharacteristic(characteristicId));

      return characteristic;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
