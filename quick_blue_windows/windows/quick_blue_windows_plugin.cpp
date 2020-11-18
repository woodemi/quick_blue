#include "include/quick_blue_windows/quick_blue_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>
#include <algorithm>

namespace {

using namespace winrt;
using namespace Windows::Foundation;
using namespace Windows::Foundation::Collections;
using namespace Windows::Storage::Streams;
using namespace Windows::Devices::Bluetooth;
using namespace Windows::Devices::Bluetooth::Advertisement;
using namespace Windows::Devices::Bluetooth::GenericAttributeProfile;

using flutter::EncodableValue;
using flutter::EncodableMap;

union uint16_t_union {
  uint16_t uint16;
  byte bytes[sizeof(uint16_t)];
};

std::vector<uint8_t> to_bytevc(IBuffer buffer)
{
  auto reader = DataReader::FromBuffer(buffer);
  auto result = std::vector<uint8_t>(reader.UnconsumedBufferLength());
  reader.ReadBytes(result);
  return result;
}

class QuickBlueWindowsPlugin : public flutter::Plugin, public flutter::StreamHandler<EncodableValue> {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  QuickBlueWindowsPlugin();

  virtual ~QuickBlueWindowsPlugin();

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::StreamHandlerError<>> OnListenInternal(
      const EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<>>&& events) override;
  std::unique_ptr<flutter::StreamHandlerError<>> OnCancelInternal(
      const EncodableValue* arguments) override;

  std::unique_ptr<flutter::EventSink<EncodableValue>> scan_result_sink_;

  BluetoothLEAdvertisementWatcher bluetoothLEWatcher{ nullptr };
  event_token bluetoothLEWatcherReceivedToken;
  void BluetoothLEWatcher_Received(BluetoothLEAdvertisementWatcher sender, BluetoothLEAdvertisementReceivedEventArgs args);

  std::vector<BluetoothLEDevice> connected_devices_{};
  fire_and_forget ConnectAsync(uint64_t bluetoothAddress);
  fire_and_forget DisconnectAsync(uint64_t bluetoothAddress);
};

// static
void QuickBlueWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto method =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          registrar->messenger(), "quick_blue/method",
          &flutter::StandardMethodCodec::GetInstance());
  auto event_scan_result =
      std::make_unique<flutter::EventChannel<EncodableValue>>(
          registrar->messenger(), "quick_blue/event.scanResult",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<QuickBlueWindowsPlugin>();

  method->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  auto handler = std::make_unique<
      flutter::StreamHandlerFunctions<>>(
      [plugin_pointer = plugin.get()](
          const EncodableValue* arguments,
          std::unique_ptr<flutter::EventSink<>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<>> {
        return plugin_pointer->OnListen(arguments, std::move(events));
      },
      [plugin_pointer = plugin.get()](const EncodableValue* arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<>> {
        return plugin_pointer->OnCancel(arguments);
      });
  event_scan_result->SetStreamHandler(std::move(handler));

  registrar->AddPlugin(std::move(plugin));
}

QuickBlueWindowsPlugin::QuickBlueWindowsPlugin() {}

QuickBlueWindowsPlugin::~QuickBlueWindowsPlugin() {}

void QuickBlueWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto method_name = method_call.method_name();
  if (method_name.compare("startScan") == 0) {
    if (!bluetoothLEWatcher) {
      bluetoothLEWatcher = BluetoothLEAdvertisementWatcher();
      bluetoothLEWatcherReceivedToken = bluetoothLEWatcher.Received({ this, &QuickBlueWindowsPlugin::BluetoothLEWatcher_Received });
    }
    bluetoothLEWatcher.Start();
    result->Success(nullptr);
  } else if (method_name.compare("stopScan") == 0) {
    if (bluetoothLEWatcher) {
      bluetoothLEWatcher.Stop();
      bluetoothLEWatcher.Received(bluetoothLEWatcherReceivedToken);
    }
    bluetoothLEWatcher = nullptr;
    result->Success(nullptr);
  } else if (method_name.compare("connect") == 0) {
    auto args = std::get<EncodableMap>(*method_call.arguments());
    auto deviceId = std::stoll(std::get<std::string>(args[EncodableValue("deviceId")]));
    ConnectAsync(deviceId);
    result->Success(nullptr);
  } else if (method_name.compare("disconnect") == 0) {
    auto args = std::get<EncodableMap>(*method_call.arguments());
    auto deviceId = std::stoll(std::get<std::string>(args[EncodableValue("deviceId")]));
    DisconnectAsync(deviceId);
    result->Success(nullptr);
  } else {
    result->NotImplemented();
  }
}

std::vector<uint8_t> parseManufacturerData(BluetoothLEAdvertisement advertisement)
{
  if (advertisement.ManufacturerData().Size() == 0)
    return std::vector<uint8_t>();

  auto manufacturerData = advertisement.ManufacturerData().GetAt(0);
  // FIXME Compat with REG_DWORD_BIG_ENDIAN
  uint8_t* prefix = uint16_t_union{ manufacturerData.CompanyId() }.bytes;
  auto result = std::vector<uint8_t>{ prefix, prefix + sizeof(uint16_t_union) };

  auto data = to_bytevc(manufacturerData.Data());
  result.insert(result.end(), data.begin(), data.end());
  return result;
}

void QuickBlueWindowsPlugin::BluetoothLEWatcher_Received(
    BluetoothLEAdvertisementWatcher sender,
    BluetoothLEAdvertisementReceivedEventArgs args) {
  OutputDebugString((L"Received " + to_hstring(args.BluetoothAddress()) + L"\n").c_str());
  auto manufacturer_data = parseManufacturerData(args.Advertisement());
  if (scan_result_sink_) {
    scan_result_sink_->Success(EncodableMap{
      {"name", winrt::to_string(args.Advertisement().LocalName())},
      {"deviceId", std::to_string(args.BluetoothAddress())},
      {"manufacturerData", manufacturer_data},
      {"rssi", args.RawSignalStrengthInDBm()},
    });
  }
}

std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> QuickBlueWindowsPlugin::OnListenInternal(
    const EncodableValue* arguments, std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
{
  auto args = std::get<EncodableMap>(*arguments);
  auto name = std::get<std::string>(args[EncodableValue("name")]);
  if (name.compare("scanResult") == 0) {
    scan_result_sink_ = std::move(events);
  }
  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> QuickBlueWindowsPlugin::OnCancelInternal(
    const EncodableValue* arguments)
{
  auto args = std::get<EncodableMap>(*arguments);
  auto name = std::get<std::string>(args[EncodableValue("name")]);
  if (name.compare("scanResult") == 0) {
      scan_result_sink_ = nullptr;
  }
  return nullptr;
}

fire_and_forget QuickBlueWindowsPlugin::ConnectAsync(uint64_t bluetoothAddress) {
  auto device = co_await BluetoothLEDevice::FromBluetoothAddressAsync(bluetoothAddress);
  auto servicesResult = co_await device.GetGattServicesAsync();
  if (servicesResult.Status() != GattCommunicationStatus::Success) {
    OutputDebugString((L"GetGattServicesAsync error: " + winrt::to_hstring((int32_t)servicesResult.Status()) + L"\n").c_str());
    co_return;
  }
  connected_devices_.push_back(device);
}

fire_and_forget QuickBlueWindowsPlugin::DisconnectAsync(uint64_t bluetoothAddress) {
  auto it = std::find_if(connected_devices_.begin(), connected_devices_.end(), [=](const BluetoothLEDevice& d) {
    return d.BluetoothAddress() == bluetoothAddress;
  });
  if (it != connected_devices_.end()) {
    connected_devices_.erase(it);
  }
  co_return;
}

}  // namespace

void QuickBlueWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  QuickBlueWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
