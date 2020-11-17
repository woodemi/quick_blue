# quick_blue

A cross-platform (Android/iOS/macOS/Windows) BluetoothLE plugin for Flutter

# Usage

- Scan BLE peripheral

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
