/// Represents a discovered nearby BLE device.
class BleDevice {
  /// Unique identifier for this device (platform-specific).
  final String id;

  /// Human-readable name of the device/player.
  final String name;

  /// The game type this device is advertising (e.g., "chess", "backgammon").
  final String gameType;

  /// Signal strength indicator (RSSI). More negative = further away.
  final int? rssi;

  /// Additional metadata advertised by the device.
  final Map<String, String> metadata;

  const BleDevice({
    required this.id,
    required this.name,
    required this.gameType,
    this.rssi,
    this.metadata = const {},
  });

  /// Estimated distance category based on RSSI.
  BleDeviceDistance get estimatedDistance {
    if (rssi == null) return BleDeviceDistance.unknown;
    if (rssi! > -50) return BleDeviceDistance.immediate;
    if (rssi! > -70) return BleDeviceDistance.near;
    return BleDeviceDistance.far;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BleDevice(id: $id, name: $name, gameType: $gameType)';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'gameType': gameType,
        'rssi': rssi,
        'metadata': metadata,
      };

  factory BleDevice.fromMap(Map<String, dynamic> map) => BleDevice(
        id: map['id'] as String,
        name: map['name'] as String,
        gameType: map['gameType'] as String,
        rssi: map['rssi'] as int?,
        metadata: Map<String, String>.from(map['metadata'] as Map? ?? {}),
      );
}

/// Estimated distance categories based on BLE signal strength.
enum BleDeviceDistance {
  /// Very close (< 1 meter).
  immediate,

  /// Nearby (1-3 meters).
  near,

  /// Far away (> 3 meters).
  far,

  /// Cannot determine distance.
  unknown,
}
