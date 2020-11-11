import Cocoa
import CoreBluetooth
import FlutterMacOS

public class QuickBlueMacosPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "quick_blue", binaryMessenger: registrar.messenger)
    let instance = QuickBlueMacosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private var manager: CBCentralManager!

  override init() {
    super.init()
    manager = CBCentralManager(delegate: self, queue: nil)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startScan":
      manager.scanForPeripherals(withServices: nil)
      result(nil)
    case "stopScan":
      manager.stopScan()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension QuickBlueMacosPlugin: CBCentralManagerDelegate {
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    print("centralManagerDidUpdateState \(central.state.rawValue)")
  }

  public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
    print("centralManager:didDiscoverPeripheral")
  }
}
