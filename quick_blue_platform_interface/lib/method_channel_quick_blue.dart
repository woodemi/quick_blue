import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quick_blue_platform_interface/quick_blue_platform_interface.dart';

class MethodChannelQuickBlue extends QuickBluePlatform {
  static const MethodChannel _method = const MethodChannel('quick_blue/method');
  static const _event_scanResult = const EventChannel('quick_blue/event.scanResult');
  static const _message_connector = const BasicMessageChannel('quick_blue/message.connector', StandardMessageCodec());

  MethodChannelQuickBlue() {
    _message_connector.setMessageHandler(_handleConnectorMessage);
  }

  QuickBlueLogLevel _logLevel = QuickBlueLogLevel.debug;

  @override
  void setLogLevel(QuickBlueLogLevel level) {
    _logLevel = level;
  }

  void _log(String message,
      {QuickBlueLogLevel level = QuickBlueLogLevel.info}) {
    if (level.index <= _logLevel.index) {
      debugPrint(message);
    }
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    bool result = await _method.invokeMethod('isBluetoothAvailable');
    return result;
  }

  @override
  void startScan() {
    _method
        .invokeMethod('startScan')
        .then((_) => _log('startScan invokeMethod success'));
  }

  @override
  void stopScan() {
    _method
        .invokeMethod('stopScan')
        .then((_) => _log('stopScan invokeMethod success'));
  }

  Stream<dynamic> _scanResultStream = _event_scanResult.receiveBroadcastStream({'name': 'scanResult'});

  @override
  Stream<dynamic> get scanResultStream => _scanResultStream;

  @override
  void connect(String deviceId) {
    _method.invokeMethod('connect', {
      'deviceId': deviceId,
    }).then((_) => _log('connect invokeMethod success'));
  }

  @override
  void disconnect(String deviceId) {
    _method.invokeMethod('disconnect', {
      'deviceId': deviceId,
    }).then((_) => _log('disconnect invokeMethod success'));
  }

  @override
  void discoverServices(String deviceId) {
    _method.invokeMethod('discoverServices', {
      'deviceId': deviceId,
    }).then((_) => _log('discoverServices invokeMethod success'));
  }

  Future<void> _handleConnectorMessage(dynamic message) async {
    _log('_handleConnectorMessage $message', level: QuickBlueLogLevel.debug);
    if (message['ConnectionState'] != null) {
      String deviceId = message['deviceId'];
      BlueConnectionState connectionState = BlueConnectionState.parse(message['ConnectionState']);
      onConnectionChanged?.call(deviceId, connectionState);
    } else if (message['ServiceState'] != null) {
      if (message['ServiceState'] == 'discovered') {
        String deviceId = message['deviceId'];
        List<dynamic> services = message['services'];
        for (var s in services) {
          onServiceDiscovered?.call(deviceId, s);
        }
      }
    } else if (message['characteristicValue'] != null) {
      String deviceId = message['deviceId'];
      var characteristicValue = message['characteristicValue'];
      String characteristic = characteristicValue['characteristic'];
      Uint8List value = Uint8List.fromList(characteristicValue['value']); // In case of _Uint8ArrayView
      onValueChanged?.call(deviceId, characteristic, value);
    } else if (message['mtuConfig'] != null) {
      _mtuConfigController.add(message['mtuConfig']);
    }
  }

  @override
  Future<void> setNotifiable(String deviceId, String service, String characteristic, BleInputProperty bleInputProperty) async {
    _method.invokeMethod('setNotifiable', {
      'deviceId': deviceId,
      'service': service,
      'characteristic': characteristic,
      'bleInputProperty': bleInputProperty.value,
    }).then((_) => _log('setNotifiable invokeMethod success'));
  }

  @override
  Future<void> writeValue(String deviceId, String service, String characteristic, Uint8List value, BleOutputProperty bleOutputProperty) async {
    _method.invokeMethod('writeValue', {
      'deviceId': deviceId,
      'service': service,
      'characteristic': characteristic,
      'value': value,
      'bleOutputProperty': bleOutputProperty.value,
    }).then((_) {
      _log('writeValue invokeMethod success', level: QuickBlueLogLevel.debug);
    }).catchError((onError) {
      // Characteristic sometimes unavailable on Android
      throw onError;
    });
  }

  @override
  Future<Uint8List?> readValue(
      String deviceId, String service, String characteristic) async {
    try {
      final bytes = await _method.invokeMethod('readValue', {
        'deviceId': deviceId,
        'service': service,
        'characteristic': characteristic
      });
      _log('readValue, ret=$bytes');
      return bytes;
    } catch (e) {
      _log('readValue, e=$e', level: QuickBlueLogLevel.error);
    }
  }

  // FIXME Close
  final _mtuConfigController = StreamController<int>.broadcast();

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    _method.invokeMethod('requestMtu', {
      'deviceId': deviceId,
      'expectedMtu': expectedMtu,
    }).then((_) => _log('requestMtu invokeMethod success'));
    return await _mtuConfigController.stream.first;
  }
}
