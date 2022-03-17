import 'dart:typed_data';

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
