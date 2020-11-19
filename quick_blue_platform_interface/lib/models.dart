class BlueConnectionState {
  static const disconnected = BlueConnectionState._('disconnected');
  static const connecting = BlueConnectionState._('connecting');
  static const awaitConfirm = BlueConnectionState._('awaitConfirm');
  static const connected = BlueConnectionState._('connected');

  final String value;

  const BlueConnectionState._(this.value);

  static BlueConnectionState parse(String value) {
    if (value == disconnected.value) {
      return disconnected;
    } else if (value == connecting.value) {
      return connecting;
    } else if (value == connected.value) {
      return connected;
    }
    throw ArgumentError.value(value);
  }
}
