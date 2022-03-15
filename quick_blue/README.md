# quick_blue

A cross-platform (Android/iOS/macOS/Windows) BluetoothLE plugin for Flutter

# Usage

- Scan BLE peripheral
- Connect BLE peripheral
- Discover services of BLE peripheral
- Transfer data between BLE central & peripheral

## Scan BLE peripheral

Android/iOS/macOS/Windows

```dart
QuickBlue.scanResultStream.listen((result) {
  print('onScanResult $result');
});

QuickBlue.startScan();
// ...
QuickBlue.stopScan();
```

## Connect BLE peripheral

Connect to `deviceId`, received from `QuickBlue.scanResultStream`

```dart
QuickBlue.setConnectionHandler(_handleConnectionChange);

void _handleConnectionChange(String deviceId, BlueConnectionState state) {
  print('_handleConnectionChange $deviceId, $state');
}

QuickBlue.connect(deviceId);
// ...
QuickBlue.disconnect(deviceId);
```

## Discover services of BLE peripheral

Discover services od `deviceId`

```dart
QuickBlue.setServiceHandler(_handleServiceDiscovery);

void _handleServiceDiscovery(String deviceId, String serviceId) {
  print('_handleServiceDiscovery $deviceId, $serviceId');
}

QuickBlue.discoverServices(deviceId);
```

## Transfer data between BLE central & peripheral

- Pull data from peripheral of `deviceId`

> Data would receive within value handler of `QuickBlue.setValueHandler`
> Because it is how [peripheral(_:didUpdateValueFor:error:)](https://developer.apple.com/documentation/corebluetooth/cbperipheraldelegate/1518708-peripheral) work on iOS/macOS

```dart
// Data would receive from value handler of `QuickBlue.setValueHandler`
QuickBlue.readValue(deviceId, serviceId, characteristicId);
```

- Send data to peripheral of `deviceId`

```dart
QuickBlue.writeValue(deviceId, serviceId, characteristicId, value);
```

- Receive data from peripheral of `deviceId`

```dart
QuickBlue.setValueHandler(_handleValueChange);

void _handleValueChange(String deviceId, String characteristicId, Uint8List value) {
  print('_handleValueChange $deviceId, $characteristicId, ${hex.encode(value)}');
}

QuickBlue.setNotifiable(deviceId, serviceId, characteristicId, true);
```

## General useful Bluetooth information

https://www.bluetooth.com/blog/4-essential-tools-for-every-bluetooth-low-energy-developer/

1. Client Emulator Apps

* LightBlue app ([iOS](https://itunes.apple.com/us/app/lightblue-explorer-bluetooth/id557428110), [macOS](https://apps.apple.com/us/app/lightblue/id557428110))
* Nordic nRF Connect app ([iOS](https://itunes.apple.com/us/app/nrf-connect/id1054362403), [Android](https://play.google.com/store/apps/details?id=no.nordicsemi.android.mcp&hl=en), [Desktop](https://www.nordicsemi.com/eng/Products/Bluetooth-low-energy/nRF-Connect-for-desktop))

2. Bluetooth Sniffer

* High-end/commercial: [Ellisys sniffers](http://www.ellisys.com/products/btcompare.php), [Teledyne LeCroy](http://teledynelecroy.com/frontline/) sniffers (formerly Frontline), the [Spanalytics PANalyzr](https://www.spanalytics.com/panalyzr)
* Low-cost: [TI CC2540 USB dongle sniffer](http://www.ti.com/tool/CC2540EMK-USB), [Nordic nRF sniffer](https://www.nordicsemi.com/Software-and-tools/Development-Tools/nRF-Sniffer-for-Bluetooth-LE), [Ubertooth One](http://ubertooth.sourceforge.net/hardware/one/)


### iOS/Mac specific info
On iOS/macOS some common service/characteristic would be shortened. Be careful when comparing the UUID. I haven't finished the refactor of notepad_core to quick_blue yet

On the Dart side you'd better call like: https://github.com/woodemi/notepad_core/blob/b0e329f3d6e02f14f8a0e5e48a6ddb48e026b658/notepad_core/lib/woodemi/WoodemiClient.dart#L245-L256

```dart
const CODE__SERV_BATTERY = "180f";
const CODE__CHAR_BATTERY_LEVEL = "2a19";

const SERV__BATTERY = "0000$CODE__SERV_BATTERY-$GSS_SUFFIX";
const CHAR__BATTERY_LEVEL = "0000$CODE__CHAR_BATTERY_LEVEL-$GSS_SUFFIX";
```

Common service/characteristic list

* Official: https://www.bluetooth.com/specifications/specs/gatt-specification-supplement-5/
* gist: https://gist.github.com/sam016/4abe921b5a9ee27f67b3686910293026


### Windows specific info

Doc of samples: https://github.com/microsoft/windows-universal-samples/tree/main/Samples/BluetoothLE Code of samples: https://github.com/microsoft/windows-universal-samples/tree/main/Samples/BluetoothLE

Some other help

* [Nordic Semiconductor](https://www.nordicsemi.com/): [Dev Zone](https://devzone.nordicsemi.com/), e.g. [this post](https://devzone.nordicsemi.com/f/nordic-q-a/48916/bluetooth-le-windows-10-using-winrt-c-code-works-if-device-not-paired-fails-with-unreachable-if-device-is-paired)
* LightBlue: [Windows tool](https://windowsden.uk/557428110/lightblue), [Docs](https://punchthrough.com/lightblue-features/)

There is a version restriction on `Connection without pairing` with `C++/WinRT` and Windows 10

* https://answers.microsoft.com/en-us/windows/forum/all/reconnecting-a-paired-bluetooth-device-without/90b42dd3-2998-4393-9d89-1624e120502f
* https://stackoverflow.com/questions/55765090/windows-bluetooth-le-require-pairing-before-connection
* https://social.msdn.microsoft.com/Forums/azure/en-US/66d6fb43-e41e-4751-99fe-170b8f63ad22/uwpcc-uwp-bluetooth-communication-without-pairing?forum=wpdevelop