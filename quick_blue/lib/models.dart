import 'dart:typed_data';

class BlueScanResult {
  String name;
  String deviceId;
  Uint8List manufacturerData;
  int rssi;

  BlueScanResult.fromMap(map)
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