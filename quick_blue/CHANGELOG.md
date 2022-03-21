## [0.4.1+1] - 2022.3.22

- Add `manufacturerDataHead` & Refactor `manufacturerData` in BlueScanResult

## [0.4.1] - 2022.3.21

- Add `setLogger`

## [0.4.0+1] - 2022.3.21

- Add API compatibility table to README

## [0.4.0] - 2022.3.21

- Add limited Linux support via quick_blue_linux
- Workaround empty device name on Windows

## [0.3.1+3] - 2022.3.20

- Fix missing `deviceId` in `characteristicValue` message on iOS/macOS

## [0.3.1+2] - 2022.3.10

- Fix README with `readValue`

## [0.3.1+1] - 2022.3.10

- Add `readValue` for Android/iOS/macOS/Windows
- Fix missing writeOptions on Windows

## [0.3.0-dev.0] - 2022.3.3

- Migerate to Null-Safety

## [0.2.0] - 2020.11.22

Add for Android/iOS/macOS/Windows
- `connect` & `disconnect`
- `onConnectionChanged`
- `discoverServices`
- `onServiceDiscovered`
- `writeValue`
- `setNotifiable`
- `onValueChanged`

## 0.1.1+1 - 2020.11.18

* Add `scanResultStream` to README.md

## 0.1.1 - 2020.11.17

* Add `scanResultStream` for Android/iOS/macOS/Windows

## 0.1.0 - 2020.11.11

* Add `startScan` & `stopScan` for Android/iOS/macOS/Windows
