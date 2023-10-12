import 'dart:async';

import 'package:flutter/services.dart';

import 'quick_blue_platform_interface.dart';

class MethodChannelQuickBlue extends QuickBluePlatform {
  static const MethodChannel _method = const MethodChannel('quick_blue/method');
  static const _event_scanResult = const EventChannel(
    'quick_blue/event.scanResult',
  );
  static const _message_connector = const BasicMessageChannel(
    'quick_blue/message.connector',
    StandardMessageCodec(),
  );

  static final _l2CapEventController =
      StreamController<BleL2CapSocketEvent>.broadcast();

  MethodChannelQuickBlue() {
    _message_connector.setMessageHandler(_handleConnectorMessage);
  }

  @override
  Future<bool> isBluetoothAvailable() async {
    bool result = await _method.invokeMethod('isBluetoothAvailable');
    return result;
  }

  @override
  Future<void> startScan() {
    return _method.invokeMethod('startScan');
  }

  @override
  Future<void> stopScan() {
    return _method.invokeMethod('stopScan');
  }

  Stream<dynamic> _scanResultStream =
      _event_scanResult.receiveBroadcastStream({'name': 'scanResult'});

  @override
  Stream<dynamic> get scanResultStream => _scanResultStream;

  @override
  Future<void> connect(String deviceId) {
    return _method.invokeMethod('connect', {
      'deviceId': deviceId,
    });
  }

  @override
  Future<void> disconnect(String deviceId) {
    return _method.invokeMethod('disconnect', {
      'deviceId': deviceId,
    });
  }

  @override
  Future<void> discoverServices(String deviceId) {
    return _method.invokeMethod('discoverServices', {
      'deviceId': deviceId,
    });
  }

  Future<void> _handleConnectorMessage(dynamic message) async {
    if (message['ConnectionState'] != null) {
      final deviceId = message['deviceId'];
      final connectionState = BlueConnectionState.parse(
        message['ConnectionState'],
      );
      final status = switch (message['status']) {
        'success' => BleStatus.success,
        _ => BleStatus.failure,
      };
      onConnectionChanged?.call(deviceId, connectionState, status);
    } else if (message['ServiceState'] != null) {
      if (message['ServiceState'] == 'discovered') {
        String deviceId = message['deviceId'];
        String service = message['service'];
        List<String> characteristics =
            (message['characteristics'] as List).cast();
        onServiceDiscovered?.call(deviceId, service, characteristics);
      }
    } else if (message['characteristicValue'] != null) {
      String deviceId = message['deviceId'];
      var characteristicValue = message['characteristicValue'];
      String characteristic = characteristicValue['characteristic'];
      Uint8List value = Uint8List.fromList(
          characteristicValue['value']); // In case of _Uint8ArrayView
      onValueChanged?.call(deviceId, characteristic, value);
    } else if (message['mtuConfig'] != null) {
      _mtuConfigController.add(message['mtuConfig']);
    } else if (message['l2capStatus'] != null) {
      final String deviceId = message['deviceId'];
      final String l2CapStatus = message['l2capStatus'];
      final Uint8List? data = message['data'];

      final event = switch (l2CapStatus) {
        'opened' => BleL2CapSocketEventOpened(deviceId: deviceId),
        'closed' => BleL2CapSocketEventClosed(deviceId: deviceId),
        'stream' => BleL2CapSocketEventData(deviceId: deviceId, data: data!),
        _ => throw 'Unknown L2Cap event $l2CapStatus',
      };

      _l2CapEventController.add(event);
    }
  }

  @override
  Future<void> setNotifiable(
    String deviceId,
    String service,
    String characteristic,
    BleInputProperty bleInputProperty,
  ) {
    return _method.invokeMethod('setNotifiable', {
      'deviceId': deviceId,
      'service': service,
      'characteristic': characteristic,
      'bleInputProperty': bleInputProperty.value,
    });
  }

  @override
  Future<void> readValue(
    String deviceId,
    String service,
    String characteristic,
  ) {
    return _method.invokeMethod('readValue', {
      'deviceId': deviceId,
      'service': service,
      'characteristic': characteristic,
    });
  }

  @override
  Future<void> writeValue(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
    BleOutputProperty bleOutputProperty,
  ) {
    return _method.invokeMethod('writeValue', {
      'deviceId': deviceId,
      'service': service,
      'characteristic': characteristic,
      'value': value,
      'bleOutputProperty': bleOutputProperty.value,
    });
  }

  // FIXME Close
  final _mtuConfigController = StreamController<int>.broadcast();

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async {
    await _method.invokeMethod('requestMtu', {
      'deviceId': deviceId,
      'expectedMtu': expectedMtu,
    });
    return await _mtuConfigController.stream.first;
  }

  @override
  Future<BleL2capSocket> openL2cap(String deviceId, String psm) async {
    await _method.invokeMethod('openL2cap', {
      'deviceId': deviceId,
      'psm': psm,
    });

    return BleL2capSocket(
      sink: _L2capSink(
        channel: _method,
        deviceId: deviceId,
      ),
      stream: _l2CapEventController.stream
          .where((event) => event.deviceId == deviceId)
          .where((event) => event is BleL2CapSocketEventData)
          .map((event) => (event as BleL2CapSocketEventData).data),
    );
  }
}

class _L2capSink implements EventSink<Uint8List> {
  _L2capSink({
    required this.channel,
    required this.deviceId,
  });

  final MethodChannel channel;
  final String deviceId;

  @override
  void add(Uint8List event) {
    channel.invokeMethod('l2cap', {
      'deviceId': deviceId,
      'data': event,
    });
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future close() async {}
}
