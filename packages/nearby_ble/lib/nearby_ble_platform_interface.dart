import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nearby_ble_method_channel.dart';

abstract class NearbyBlePlatform extends PlatformInterface {
  /// Constructs a NearbyBlePlatform.
  NearbyBlePlatform() : super(token: _token);

  static final Object _token = Object();

  static NearbyBlePlatform _instance = MethodChannelNearbyBle();

  /// The default instance of [NearbyBlePlatform] to use.
  ///
  /// Defaults to [MethodChannelNearbyBle].
  static NearbyBlePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NearbyBlePlatform] when
  /// they register themselves.
  static set instance(NearbyBlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
