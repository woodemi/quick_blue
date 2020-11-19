library quick_blue_platform_interface;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_quick_blue.dart';

import 'models.dart';

export 'models.dart';

typedef OnConnectionChanged = void Function(String deviceId, BlueConnectionState state);

abstract class QuickBluePlatform extends PlatformInterface {
  QuickBluePlatform() : super(token: _token);

  static final Object _token = Object();

  static QuickBluePlatform _instance = MethodChannelQuickBlue();

  static QuickBluePlatform get instance => _instance;

  static set instance(QuickBluePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void startScan();

  void stopScan();

  Stream<dynamic> get scanResultStream;

  void connect(String deviceId);

  void disconnect(String deviceId);

  OnConnectionChanged onConnectionChanged;

  void setConnectionHandler(OnConnectionChanged onConnectionChanged) {
    this.onConnectionChanged = onConnectionChanged;
  }
}
