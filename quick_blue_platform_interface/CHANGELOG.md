## [0.4.0-dev.0] - 2022.6.3

- [BREAKING CHANGE] Add characteristics to OnServiceDiscoverd callback

## [0.3.2] - 2022.3.21

- Use `logging`

## [0.3.1+1] - 2022.3.10

- Fix version typo

## [0.3.1] - 2022.3.10

- Define `readValue` for Android/iOS/macOS/Windows

## [0.3.0-dev.0] - 2022.3.3

- Migerate to Null-Safety

## [0.2.0] - 2020.11.22

**Connect/Disconnect BLE peripheral**
- Define `connect` & `disconnect` for Android/iOS/macOS/Windows
- Define `onConnectionChanged` for Android/iOS/macOS/Windows

**Discover BLE peripheral**
- Define `discoverServices` for Android/iOS/macOS/Windows
- Define `onServiceDiscovered` for Android/iOS/macOS/Windows

**Send data to BLE peripheral**
- Define `writeValue` for Android/iOS/macOS/Windows

**Recieve data from BLE peripheral**
- Define `setNotifiable` for Android/iOS/macOS/Windows
- Define `onValueChanged` for Android/iOS/macOS/Windows

## [0.1.1] - 2020.11.17

### QuickBluePlatform

**Scan BLE peripheral**
- Define `scanResultStream` for Android/iOS/macOS/Windows

## [0.1.0] - 2020.11.11

### QuickBluePlatform

**Scan BLE peripheral**
- Define `startScan`, `stopScan` for Android/iOS/macOS/Windows
