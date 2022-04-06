class BlueConnectionState {
  static const disconnected = BlueConnectionState._('disconnected');
  static const connected = BlueConnectionState._('connected');

  final String value;

  const BlueConnectionState._(this.value);

  static BlueConnectionState parse(String value) {
    if (value == disconnected.value) {
      return disconnected;
    } else if (value == connected.value) {
      return connected;
    }
    throw ArgumentError.value(value);
  }
}

class BleInputProperty {
  static const disabled = BleInputProperty._('disabled');
  static const notification = BleInputProperty._('notification');
  static const indication = BleInputProperty._('indication');

  final String value;

  const BleInputProperty._(this.value);
}

class BleOutputProperty {
  static const withResponse = BleOutputProperty._('withResponse');
  static const withoutResponse = BleOutputProperty._('withoutResponse');

  final String value;

  const BleOutputProperty._(this.value);
}

class BlueServices {
  String serviceId;
  List<BlueCharacteristic> characteristics;
  BlueServices({required this.serviceId, this.characteristics = const []});

  BlueServices.fromMap(map)
      : serviceId = map['serviceId'],
        characteristics = map['characteristics'];

  Map toMap() => {
        'serviceId': serviceId,
        'characteristics': characteristics,
      };
}

class BlueCharacteristic {
  final String characteristicId;
  final String serviceId;
  final bool isReadable;
  final bool isWritableWithResponse;
  final bool isWritableWithoutResponse;
  final bool isNotifiable;
  final bool isIndicatable;

  const BlueCharacteristic({
    required this.characteristicId,
    required this.serviceId,
    required this.isReadable,
    required this.isWritableWithResponse,
    required this.isWritableWithoutResponse,
    required this.isNotifiable,
    required this.isIndicatable,
  });
}
