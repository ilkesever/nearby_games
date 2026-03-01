import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nearby_ble_platform_interface.dart';

/// An implementation of [NearbyBlePlatform] that uses method channels.
class MethodChannelNearbyBle extends NearbyBlePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nearby_ble');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
