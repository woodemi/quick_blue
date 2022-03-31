#include "include/quick_blue_windows/quick_blue_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Devices.Radios.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>

#include <flutter/method_channel.h>
#include <flutter/basic_message_channel.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <memory>
#include <sstream>
#include <algorithm>
#include <iomanip>

#define GUID_FORMAT "%08x-%04hx-%04hx-%02hhx%02hhx-%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx"
#define GUID_ARG(guid) guid.Data1, guid.Data2, guid.Data3, guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3], guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]

namespace {

using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Foundation::Collections;
using namespace winrt::Windows::Storage::Streams;
using namespace winrt::Windows::Devices::Radios;
using namespace winrt::Windows::Devices::Bluetooth;
using namespace winrt::Windows::Devices::Bluetooth::Advertisement;
using namespace winrt::Windows::Devices::Bluetooth::GenericAttributeProfile;

using flutter::EncodableValue;
using flutter::EncodableMap;

union uint16_t_union {
  uint16_t uint16;
  byte bytes[sizeof(uint16_t)];
};

std::vector<uint8_t> to_bytevc(IBuffer buffer) {
  auto reader = DataReader::FromBuffer(buffer);
  auto result = std::vector<uint8_t>(reader.UnconsumedBufferLength());
  reader.ReadBytes(result);
  return result;
}

IBuffer from_bytevc(std::vector<uint8_t> bytes) {
  auto writer = DataWriter();
  writer.WriteBytes(bytes);
  return writer.DetachBuffer();
}

std::string to_hexstring(std::vector<uint8_t> bytes) {
  auto ss = std::stringstream();
  for (auto b : bytes)
      ss << std::setw(2) << std::setfill('0') << std::hex << static_cast<int>(b);
  return ss.str();
}

std::string to_uuidstr(winrt::guid guid) {
  char chars[36 + 1];
  sprintf_s(chars, GUID_FORMAT, GUID_ARG(guid));
  return std::string{ chars };
}

struct BluetoothDeviceAgent {
  BluetoothLEDevice device;
  winrt::event_token connnectionStatusChangedToken;
  std::map<std::string, GattDeviceService> gattServices;
  std::map<std::string, GattCharacteristic> gattCharacteristics;
  std::map<std::string, winrt::event_token> valueChangedTokens;

  BluetoothDeviceAgent(BluetoothLEDevice device, winrt::event_token connnectionStatusChangedToken)
      : device(device),
        connnectionStatusChangedToken(connnectionStatusChangedToken) {}

  ~BluetoothDeviceAgent() {
    device = nullptr;
  }

  IAsyncOperation<GattDeviceService> GetServiceAsync(std::string service) {
    if (gattServices.count(service) == 0) {
      auto serviceResult = co_await device.GetGattServicesAsync();
      if (serviceResult.Status() != GattCommunicationStatus::Success)
        co_return nullptr;

      for (auto s : serviceResult.Services())
        if (to_uuidstr(s.Uuid()) == service)
          gattServices.insert(std::make_pair(service, s));
    }
    co_return gattServices.at(service);
  }

  IAsyncOperation<GattCharacteristic> GetCharacteristicAsync(std::string service, std::string characteristic) {
    if (gattCharacteristics.count(characteristic) == 0) {
      auto gattService = co_await GetServiceAsync(service);

      auto characteristicResult = co_await gattService.GetCharacteristicsAsync();
      if (characteristicResult.Status() != GattCommunicationStatus::Success)
        co_return nullptr;

      for (auto c : characteristicResult.Characteristics())
        if (to_uuidstr(c.Uuid()) == characteristic)
          gattCharacteristics.insert(std::make_pair(characteristic, c));
    }
    co_return gattCharacteristics.at(characteristic);
  }
};

class QuickBlueWindowsPlugin : public flutter::Plugin, public flutter::StreamHandler<EncodableValue> {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  QuickBlueWindowsPlugin();

  virtual ~QuickBlueWindowsPlugin();

 private:
   winrt::fire_and_forget InitializeAsync();

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::StreamHandlerError<>> OnListenInternal(
      const EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<>>&& events) override;
  std::unique_ptr<flutter::StreamHandlerError<>> OnCancelInternal(
      const EncodableValue* arguments) override;

  std::unique_ptr<flutter::BasicMessageChannel<EncodableValue>> message_connector_;

  std::unique_ptr<flutter::EventSink<EncodableValue>> scan_result_sink_;

  Radio bluetoothRadio{ nullptr };

  BluetoothLEAdvertisementWatcher bluetoothLEWatcher{ nullptr };
  winrt::event_token bluetoothLEWatcherReceivedToken;
  void BluetoothLEWatcher_Received(BluetoothLEAdvertisementWatcher sender, BluetoothLEAdvertisementReceivedEventArgs args);
  winrt::fire_and_forget SendScanResultAsync(BluetoothLEAdvertisementReceivedEventArgs args);

  std::map<uint64_t, std::unique_ptr<BluetoothDeviceAgent>> connectedDevices{};

  winrt::fire_and_forget ConnectAsync(uint64_t bluetoothAddress);
  void BluetoothLEDevice_ConnectionStatusChanged(BluetoothLEDevice sender, IInspectable args);
  void CleanConnection(uint64_t bluetoothAddress);

  winrt::fire_and_forget SetNotifiableAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string service, std::string characteristic, std::string bleInputProperty);
  winrt::fire_and_forget RequestMtuAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, uint64_t expectedMtu);
  winrt::fire_and_forget ReadValueAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string service, std::string characteristic);
  winrt::fire_and_forget WriteValueAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string service, std::string characteristic, std::vector<uint8_t> value, std::string bleOutputProperty);
  void QuickBlueWindowsPlugin::GattCharacteristic_ValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args);
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
  auto message_connector_ =
      std::make_unique<flutter::BasicMessageChannel<EncodableValue>>(
          registrar->messenger(), "quick_blue/message.connector",
          &flutter::StandardMessageCodec::GetInstance());

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

  plugin->message_connector_ = std::move(message_connector_);

  registrar->AddPlugin(std::move(plugin));
}

QuickBlueWindowsPlugin::QuickBlueWindowsPlugin() {
  InitializeAsync();
}

QuickBlueWindowsPlugin::~QuickBlueWindowsPlugin() {}

winrt::fire_and_forget QuickBlueWindowsPlugin::InitializeAsync() {
  auto bluetoothAdapter = co_await BluetoothAdapter::GetDefaultAsync();
  bluetoothRadio = co_await bluetoothAdapter.GetRadioAsync();
}

void QuickBlueWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto method_name = method_call.method_name();
  OutputDebugString((L"HandleMethodCall " + winrt::to_hstring(method_name) + L"\n").c_str());
  if (method_name.compare("isBluetoothAvailable") == 0) {
    result->Success(EncodableValue(bluetoothRadio && bluetoothRadio.State() == RadioState::On));
  } else if (method_name.compare("startScan") == 0) {
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
    auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
    ConnectAsync(std::stoull(deviceId));
    result->Success(nullptr);
  } else if (method_name.compare("disconnect") == 0) {
    auto args = std::get<EncodableMap>(*method_call.arguments());
    auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
    CleanConnection(std::stoull(deviceId));
    // TODO send `disconnected` message
    result->Success(nullptr);
  } else if (method_name.compare("discoverServices") == 0) {
    // FIXME Unnecessary for Windows: https://github.com/woodemi/quick_blue/issues/76
    result->NotImplemented();
  } else if (method_name.compare("setNotifiable") == 0) {
    auto args = std::get<EncodableMap>(*method_call.arguments());
    auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
    auto service = std::get<std::string>(args[EncodableValue("service")]);
    auto characteristic = std::get<std::string>(args[EncodableValue("characteristic")]);
    auto bleInputProperty = std::get<std::string>(args[EncodableValue("bleInputProperty")]);
    auto it = connectedDevices.find(std::stoull(deviceId));
    if (it == connectedDevices.end()) {
      result->Error("IllegalArgument", "Unknown devicesId:" + deviceId);
      return;
    }

    SetNotifiableAsync(*it->second, service, characteristic, bleInputProperty);
    result->Success(nullptr);
  } else if (method_name.compare("requestMtu") == 0) {
    auto args = std::get<EncodableMap>(*method_call.arguments());
    auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
    auto expectedMtu = std::get<int32_t>(args[EncodableValue("expectedMtu")]);
    auto it = connectedDevices.find(std::stoull(deviceId));
    if (it == connectedDevices.end()) {
      result->Error("IllegalArgument", "Unknown devicesId:" + deviceId);
      return;
    }

    RequestMtuAsync(*it->second, expectedMtu);
    result->Success(nullptr);
  } else if (method_name.compare("readValue") == 0) {
    auto args = std::get<EncodableMap>(*method_call.arguments());
    auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
    auto service = std::get<std::string>(args[EncodableValue("service")]);
    auto characteristic = std::get<std::string>(args[EncodableValue("characteristic")]);
    auto it = connectedDevices.find(std::stoull(deviceId));
    if (it == connectedDevices.end()) {
      result->Error("IllegalArgument", "Unknown devicesId:" + deviceId);
      return;
    }

    ReadValueAsync(*it->second, service, characteristic);
    result->Success(nullptr);
  } else if (method_name.compare("writeValue") == 0) {
    auto args = std::get<EncodableMap>(*method_call.arguments());
    auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
    auto service = std::get<std::string>(args[EncodableValue("service")]);
    auto characteristic = std::get<std::string>(args[EncodableValue("characteristic")]);
    auto value = std::get<std::vector<uint8_t>>(args[EncodableValue("value")]);
    auto bleOutputProperty = std::get<std::string>(args[EncodableValue("bleOutputProperty")]);
    auto it = connectedDevices.find(std::stoull(deviceId));
    if (it == connectedDevices.end()) {
      result->Error("IllegalArgument", "Unknown devicesId:" + deviceId);
      return;
    }

    WriteValueAsync(*it->second, service, characteristic, value, bleOutputProperty);
    result->Success(nullptr);
  } else {
    result->NotImplemented();
  }
}

std::vector<uint8_t> parseManufacturerDataHead(BluetoothLEAdvertisement advertisement)
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
  SendScanResultAsync(args);
}

winrt::fire_and_forget QuickBlueWindowsPlugin::SendScanResultAsync(BluetoothLEAdvertisementReceivedEventArgs args) {
  auto device = co_await BluetoothLEDevice::FromBluetoothAddressAsync(args.BluetoothAddress());
  auto name = device ? device.Name() : args.Advertisement().LocalName();
  OutputDebugString((L"Received BluetoothAddress:" + winrt::to_hstring(args.BluetoothAddress())
    + L", Name:" + name + L", LocalName:" + args.Advertisement().LocalName() + L"\n").c_str());
  if (scan_result_sink_) {
    scan_result_sink_->Success(EncodableMap{
      {"name", winrt::to_string(name)},
      {"deviceId", std::to_string(args.BluetoothAddress())},
      {"manufacturerDataHead", parseManufacturerDataHead(args.Advertisement())},
      {"rssi", args.RawSignalStrengthInDBm()},
    });
  }
}

std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> QuickBlueWindowsPlugin::OnListenInternal(
    const EncodableValue* arguments, std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
{
  if (arguments == nullptr) {
    return nullptr;
  }
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
  if (arguments == nullptr) {
    return nullptr;
  }
  auto args = std::get<EncodableMap>(*arguments);
  auto name = std::get<std::string>(args[EncodableValue("name")]);
  if (name.compare("scanResult") == 0) {
      scan_result_sink_ = nullptr;
  }
  return nullptr;
}

winrt::fire_and_forget QuickBlueWindowsPlugin::ConnectAsync(uint64_t bluetoothAddress) {
  auto device = co_await BluetoothLEDevice::FromBluetoothAddressAsync(bluetoothAddress);
  auto servicesResult = co_await device.GetGattServicesAsync();
  if (servicesResult.Status() != GattCommunicationStatus::Success) {
    OutputDebugString((L"GetGattServicesAsync error: " + winrt::to_hstring((int32_t)servicesResult.Status()) + L"\n").c_str());
    message_connector_->Send(EncodableMap{
      {"deviceId", std::to_string(bluetoothAddress)},
      {"ConnectionState", "disconnected"},
    });
    co_return;
  }
  auto connnectionStatusChangedToken = device.ConnectionStatusChanged({ this, &QuickBlueWindowsPlugin::BluetoothLEDevice_ConnectionStatusChanged });
  auto deviceAgent = std::make_unique<BluetoothDeviceAgent>(device, connnectionStatusChangedToken);
  auto pair = std::make_pair(bluetoothAddress, std::move(deviceAgent));
  connectedDevices.insert(std::move(pair));

  message_connector_->Send(EncodableMap{
    {"deviceId", std::to_string(bluetoothAddress)},
    {"ConnectionState", "connected"},
  });
}

void QuickBlueWindowsPlugin::BluetoothLEDevice_ConnectionStatusChanged(BluetoothLEDevice sender, IInspectable args) {
  OutputDebugString((L"ConnectionStatusChanged " + winrt::to_hstring((int32_t)sender.ConnectionStatus()) + L"\n").c_str());
  if (sender.ConnectionStatus() == BluetoothConnectionStatus::Disconnected) {
    CleanConnection(sender.BluetoothAddress());
    message_connector_->Send(EncodableMap{
      {"deviceId", std::to_string(sender.BluetoothAddress())},
      {"ConnectionState", "disconnected"},
    });
  }
}

void QuickBlueWindowsPlugin::CleanConnection(uint64_t bluetoothAddress) {
  auto node = connectedDevices.extract(bluetoothAddress);
  if (!node.empty()) {
    auto deviceAgent = std::move(node.mapped());
    deviceAgent->device.ConnectionStatusChanged(deviceAgent->connnectionStatusChangedToken);
    for (auto& tokenPair : deviceAgent->valueChangedTokens) {
      deviceAgent->gattCharacteristics.at(tokenPair.first).ValueChanged(tokenPair.second);
    }
  }
}

winrt::fire_and_forget QuickBlueWindowsPlugin::RequestMtuAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, uint64_t expectedMtu) {
  OutputDebugString(L"RequestMtuAsync expectedMtu");
  auto gattSession = co_await GattSession::FromDeviceIdAsync(bluetoothDeviceAgent.device.BluetoothDeviceId());
  message_connector_->Send(EncodableMap{
    {"mtuConfig", (int64_t)gattSession.MaxPduSize()},
  });
}

winrt::fire_and_forget QuickBlueWindowsPlugin::SetNotifiableAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string service, std::string characteristic, std::string bleInputProperty) {
  auto gattCharacteristic = co_await bluetoothDeviceAgent.GetCharacteristicAsync(service, characteristic);
  auto descriptorValue = bleInputProperty == "notification" ? GattClientCharacteristicConfigurationDescriptorValue::Notify
    : bleInputProperty == "indication" ? GattClientCharacteristicConfigurationDescriptorValue::Indicate
    : GattClientCharacteristicConfigurationDescriptorValue::None;
  auto writeDescriptorStatus = co_await gattCharacteristic.WriteClientCharacteristicConfigurationDescriptorAsync(descriptorValue);
  if (writeDescriptorStatus != GattCommunicationStatus::Success)
    OutputDebugString((L"WriteClientCharacteristicConfigurationDescriptorAsync " + winrt::to_hstring((int32_t)writeDescriptorStatus) + L"\n").c_str());

  if (bleInputProperty != "disabled") {
    bluetoothDeviceAgent.valueChangedTokens[characteristic] = gattCharacteristic.ValueChanged({ this, &QuickBlueWindowsPlugin::GattCharacteristic_ValueChanged });
  } else {
    gattCharacteristic.ValueChanged(std::exchange(bluetoothDeviceAgent.valueChangedTokens[characteristic], {}));
  }
}

winrt::fire_and_forget QuickBlueWindowsPlugin::ReadValueAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string service, std::string characteristic) {
  auto gattCharacteristic = co_await bluetoothDeviceAgent.GetCharacteristicAsync(service, characteristic);
  auto readValueResult = co_await gattCharacteristic.ReadValueAsync();
  auto bytes = to_bytevc(readValueResult.Value());
  OutputDebugString((L"ReadValueAsync " + winrt::to_hstring(characteristic) + L", " + winrt::to_hstring(to_hexstring(bytes)) + L"\n").c_str());
  message_connector_->Send(EncodableMap{
    {"deviceId", std::to_string(gattCharacteristic.Service().Device().BluetoothAddress())},
    {"characteristicValue", EncodableMap{
      {"characteristic", characteristic},
      {"value", bytes},
    }},
  });
}

winrt::fire_and_forget QuickBlueWindowsPlugin::WriteValueAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string service, std::string characteristic, std::vector<uint8_t> value, std::string bleOutputProperty) {
  auto gattCharacteristic = co_await bluetoothDeviceAgent.GetCharacteristicAsync(service, characteristic);
  auto writeOption = bleOutputProperty.compare("withoutResponse") == 0 ? GattWriteOption::WriteWithoutResponse : GattWriteOption::WriteWithResponse;
  auto writeValueStatus = co_await gattCharacteristic.WriteValueAsync(from_bytevc(value), writeOption);
  OutputDebugString((L"WriteValueAsync " + winrt::to_hstring(characteristic) + L", " + winrt::to_hstring(to_hexstring(value)) + L", " + winrt::to_hstring((int32_t)writeValueStatus) + L"\n").c_str());
}

void QuickBlueWindowsPlugin::GattCharacteristic_ValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args) {
  auto uuid = to_uuidstr(sender.Uuid());
  auto bytes = to_bytevc(args.CharacteristicValue());
  OutputDebugString((L"GattCharacteristic_ValueChanged " + winrt::to_hstring(uuid) + L", " + winrt::to_hstring(to_hexstring(bytes)) + L"\n").c_str());
  message_connector_->Send(EncodableMap{
    {"deviceId", std::to_string(sender.Service().Device().BluetoothAddress())},
    {"characteristicValue", EncodableMap{
      {"characteristic", uuid},
      {"value", bytes},
    }},
  });
}

}  // namespace

void QuickBlueWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  QuickBlueWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
