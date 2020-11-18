import CoreBluetooth
import Flutter
import UIKit

extension CBPeripheral {
  // FIXME https://forums.developer.apple.com/thread/84375
  public var uuid: UUID {
    get {
      value(forKey: "identifier") as! NSUUID as UUID
    }
  }
}

public class SwiftQuickBluePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let method = FlutterMethodChannel(name: "quick_blue/method", binaryMessenger: registrar.messenger())
    let eventScanResult = FlutterEventChannel(name: "quick_blue/event.scanResult", binaryMessenger: registrar.messenger())

    let instance = SwiftQuickBluePlugin()
    registrar.addMethodCallDelegate(instance, channel: method)
    eventScanResult.setStreamHandler(instance)
  }
    
  private var manager: CBCentralManager!
  private var discoveredPeripherals: Dictionary<String, CBPeripheral>!

  private var scanResultSink: FlutterEventSink?

  override init() {
    super.init()
    manager = CBCentralManager(delegate: self, queue: nil)
    discoveredPeripherals = Dictionary()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startScan":
      manager.scanForPeripherals(withServices: nil)
      result(nil)
    case "stopScan":
      manager.stopScan()
      result(nil)
    case "connect":
      guard let arguments = call.arguments as? Dictionary<String, Any>,
          let deviceId = arguments["deviceId"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      manager.connect(peripheral)
      result(nil)
    case "disconnect":
      guard let arguments = call.arguments as? Dictionary<String, Any>,
            let deviceId = arguments["deviceId"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let peripheral = discoveredPeripherals[deviceId] else {
        result(FlutterError(code: "IllegalArgument", message: "Unknown deviceId:\(deviceId)", details: nil))
        return
      }
      manager.cancelPeripheralConnection(peripheral)
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
    print("centralManager:didDiscoverPeripheral \(peripheral.name) \(peripheral.uuid)")
    discoveredPeripherals[peripheral.uuid.uuidString] = peripheral

    let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    scanResultSink?([
      "name": peripheral.name ?? "",
      "deviceId": peripheral.uuid.uuidString,
      "manufacturerData": FlutterStandardTypedData(bytes: manufacturerData ?? Data()),
      "rssi": RSSI,
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
