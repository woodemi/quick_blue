import 'dart:typed_data';

final _empty = Uint8List.fromList(List.empty());

class BlueScanResult {
  String name;
  String deviceId;
  Uint8List? _manufacturerDataHead;
  Uint8List? _manufacturerData;
  int rssi;

  Uint8List get manufacturerDataHead => _manufacturerDataHead ?? _empty;

  Uint8List get manufacturerData => _manufacturerData ?? manufacturerDataHead;

  BlueScanResult.fromMap(map)
      : name = map['name'],
        deviceId = map['deviceId'],
        _manufacturerDataHead = map['manufacturerDataHead'],
        _manufacturerData = map['manufacturerData'],
        rssi = map['rssi'];

  Map toMap() => {
        'name': name,
        'deviceId': deviceId,
        'manufacturerDataHead': _manufacturerDataHead,
        'manufacturerData': _manufacturerData,
        'rssi': rssi,
      };

  @override
  int get hashCode => _xor(name.codeUnits) ^ _xor(deviceId.codeUnits);

  @override
  bool operator ==(Object other) =>
      other is BlueScanResult &&
      this.name == other.name &&
      this.deviceId == other.deviceId;
}

int _xor(List<int> a) => a.reduce((a, b) => a ^ b);
