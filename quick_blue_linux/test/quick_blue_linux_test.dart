import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_blue_linux/quick_blue_linux.dart';

void main() {
  const MethodChannel channel = MethodChannel('quick_blue_linux');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await QuickBlueLinux.platformVersion, '42');
  });
}
