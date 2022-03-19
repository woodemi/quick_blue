import CoreBluetooth
import Flutter
import UIKit

let GATT_HEADER_LENGTH = 3

let GSS_SUFFIX = "0000-1000-8000-00805f9b34fb"

extension CBUUID {
  public var uuidStr: String {
    get {
      uuidString.lowercased()
    }
  }
}

extension CBPeripheral {
  // FIXME https://forums.developer.apple.com/thread/84375
  public var uuid: UUID {
    get {
      value(forKey: "identifier") as! NSUUID as UUID
    }
  }

  public func getCharacteristic(_ characteristic: String, of service: String) -> CBCharacteristic {
    let s = self.services?.first {
      $0.uuid.uuidStr == service || "0000\($0.uuid.uuidStr)-\(GSS_SUFFIX)" == service
    }
    let c = s?.characteristics?.first {
      $0.uuid.uuidStr == characteristic || "0000\($0.uuid.uuidStr)-\(GSS_SUFFIX)" == characteristic
    }
    return c!
  }

  public func setNotifiable(_ bleInputProperty: String, for characteristic: String, of service: String) {
    setNotifyValue(bleInputProperty != "disabled", for: getCharacteristic(characteristic, of: service))
  }
}

public class SwiftQuickBluePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let method = FlutterMethodChannel(name: "quick_blue/method", binaryMessenger: registrar.messenger())
    let eventScanResult = FlutterEventChannel(name: "quick_blue/event.scanResult", binaryMessenger: registrar.messenger())
    let messageConnector = FlutterBasicMessageChannel(name: "quick_blue/message.connector", binaryMessenger: registrar.messenger())

    let instance = SwiftQuickBluePlugin()
    registrar.addMethodCallDelegate(instance, channel: method)
    eventScanResult.setStreamHandler(instance)
    instance.messageConnector = messageConnector
  }
    
  private var manager: CBCentralManager!
  private var discoveredPeripherals: Dictionary<String, CBPeripheral>!

  private var scanResultSink: FlutterEventSink?
  private var messageConnector: FlutterBasicMessageChannel!

  override init() {
    super.init()
    manager = CBCentralManager(delegate: self, queue: nil)
    discoveredPeripherals = Dictionary()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isBluetoothAvailable":
      result(manager.state == .poweredOn)
    case "startScan":
      manager.scanForPeripherals(withServices: nil)
      result(nil)
    case "stopScan":
      manager.stopScan()
      result(nil)
    case "connect":
      let arguments = call.arguments as! Dictionary<String, Any>
      let deviceId = arguments["deviceId"] as! String
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      peripheral.delegate = self
      manager.connect(peripheral)
      result(nil)
    case "disconnect":
      let arguments = call.arguments as! Dictionary<String, Any>
      let deviceId = arguments["deviceId"] as! String
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      if (peripheral.state != .disconnected) {
        manager.cancelPeripheralConnection(peripheral)
      }
      result(nil)
    case "discoverServices":
      let arguments = call.arguments as! Dictionary<String, Any>
      let deviceId = arguments["deviceId"] as! String
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      peripheral.discoverServices(nil)
      result(nil)
    case "setNotifiable":
      let arguments = call.arguments as! Dictionary<String, Any>
      let deviceId = arguments["deviceId"] as! String
      let service = arguments["service"] as! String
      let characteristic = arguments["characteristic"] as! String
      let bleInputProperty = arguments["bleInputProperty"] as! String
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      peripheral.setNotifiable(bleInputProperty, for: characteristic, of: service)
      result(nil)
    case "requestMtu":
      let arguments = call.arguments as! Dictionary<String, Any>
      let deviceId = arguments["deviceId"] as! String
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      result(nil)
      let mtu = peripheral.maximumWriteValueLength(for: .withoutResponse)
      print("peripheral.maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse \(mtu)")
      messageConnector.sendMessage(["mtuConfig": mtu + GATT_HEADER_LENGTH])
    case "readValue":
      let arguments = call.arguments as! Dictionary<String, Any>
      let deviceId = arguments["deviceId"] as! String
      let service = arguments["service"] as! String
      let characteristic = arguments["characteristic"] as! String
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      peripheral.readValue(for: peripheral.getCharacteristic(characteristic, of: service))
      result(nil)
    case "writeValue":
      let arguments = call.arguments as! Dictionary<String, Any>
      let deviceId = arguments["deviceId"] as! String
      let service = arguments["service"] as! String
      let characteristic = arguments["characteristic"] as! String
      let value = arguments["value"] as! FlutterStandardTypedData
      let bleOutputProperty = arguments["bleOutputProperty"] as! String
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      let type = bleOutputProperty == "withoutResponse" ? CBCharacteristicWriteType.withoutResponse : CBCharacteristicWriteType.withResponse
      peripheral.writeValue(value.data, for: peripheral.getCharacteristic(characteristic, of: service), type: type)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension SwiftQuickBluePlugin: CBCentralManagerDelegate {
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    print("centralManagerDidUpdateState \(central.state.rawValue)")
  }

  public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
    print("centralManager:didDiscoverPeripheral \(peripheral.name) \(peripheral.uuid.uuidString)")
    discoveredPeripherals[peripheral.uuid.uuidString] = peripheral

    let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    scanResultSink?([
      "name": peripheral.name ?? "",
      "deviceId": peripheral.uuid.uuidString,
      "manufacturerData": FlutterStandardTypedData(bytes: manufacturerData ?? Data()),
      "rssi": RSSI,
    ])
  }

  public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("centralManager:didConnect \(peripheral.uuid.uuidString)")
    messageConnector.sendMessage([
      "deviceId": peripheral.uuid.uuidString,
      "ConnectionState": "connected",
    ])
  }
  
  public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    print("centralManager:didDisconnectPeripheral: \(peripheral.uuid.uuidString) error: \(error)")
    messageConnector.sendMessage([
      "deviceId": peripheral.uuid.uuidString,
      "ConnectionState": "disconnected",
    ])
  }
}

extension SwiftQuickBluePlugin: FlutterStreamHandler {
  open func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard let args = arguments as? Dictionary<String, Any>, let name = args["name"] as? String else {
      return nil
    }
    print("QuickBlueMacosPlugin onListenWithArguments：\(name)")
    if name == "scanResult" {
      scanResultSink = events
    }
    return nil
  }

  open func onCancel(withArguments arguments: Any?) -> FlutterError? {
    guard let args = arguments as? Dictionary<String, Any>, let name = args["name"] as? String else {
      return nil
    }
    print("QuickBlueMacosPlugin onCancelWithArguments：\(name)")
    if name == "scanResult" {
      scanResultSink = nil
    }
    return nil
  }
}

extension SwiftQuickBluePlugin: CBPeripheralDelegate {
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    print("peripheral: \(peripheral.uuid.uuidString) didDiscoverServices: \(error)")
    for service in peripheral.services! {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
    
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    for characteristic in service.characteristics! {
      print("peripheral:didDiscoverCharacteristicsForService (\(service.uuid.uuidStr), \(characteristic.uuid.uuidStr)")
    }
    self.messageConnector.sendMessage([
      "deviceId": peripheral.uuid.uuidString,
      "ServiceState": "discovered",
      "services": [service.uuid.uuidStr],
    ])
  }
    
  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    print("peripheral:didWriteValueForCharacteristic \(characteristic.uuid.uuidStr) \(characteristic.value as? NSData) error: \(error)")
  }
    
  public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    print("peripheral:didUpdateValueForForCharacteristic \(characteristic.uuid) \(characteristic.value as! NSData) error: \(error)")
    self.messageConnector.sendMessage([
      "deviceId": peripheral.uuid.uuidString,
      "characteristicValue": [
        "characteristic": characteristic.uuid.uuidStr,
        "value": FlutterStandardTypedData(bytes: characteristic.value!)
      ]
    ])
  }
}
