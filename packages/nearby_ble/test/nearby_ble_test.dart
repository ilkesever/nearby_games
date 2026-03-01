import 'package:flutter_test/flutter_test.dart';
import 'package:nearby_ble/nearby_ble.dart';
import 'package:nearby_ble/nearby_ble_platform_interface.dart';
import 'package:nearby_ble/nearby_ble_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNearbyBlePlatform
    with MockPlatformInterfaceMixin
    implements NearbyBlePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NearbyBlePlatform initialPlatform = NearbyBlePlatform.instance;

  test('$MethodChannelNearbyBle is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNearbyBle>());
  });

  test('getPlatformVersion', () async {
    NearbyBle nearbyBlePlugin = NearbyBle();
    MockNearbyBlePlatform fakePlatform = MockNearbyBlePlatform();
    NearbyBlePlatform.instance = fakePlatform;

    expect(await nearbyBlePlugin.getPlatformVersion(), '42');
  });
}
