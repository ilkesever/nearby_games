#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nearby_ble.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'nearby_ble'
  s.version          = '0.1.0'
  s.summary          = 'BLE-based nearby P2P communication for multiplayer games.'
  s.description      = <<-DESC
Cross-platform BLE plugin for peer-to-peer nearby communication.
Uses CoreBluetooth for iOS↔Android multiplayer gaming without internet.
                       DESC
  s.homepage         = 'https://github.com/nearbygames/nearby_games'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nearby Games' => 'dev@nearbygames.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.frameworks = 'CoreBluetooth'

  # Flutter.framework does not contain a i386 slice.
  # FRAMEWORK_SEARCH_PATHS ensures the Flutter module is found during VerifyModule
  # in Release builds for device (Release-iphoneos), where FLUTTER_FRAMEWORK_DIR
  # and the pod build dir must both be on the search path.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_CONFIGURATION_BUILD_DIR)/Flutter $(FLUTTER_FRAMEWORK_DIR)'
  }
  s.swift_version = '5.0'

  # Privacy manifest — required for CoreBluetooth usage on iOS 17+ / iOS 26+.
  # See https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'nearby_ble_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
