import 'ble_device.dart';

/// Represents an active BLE connection between two devices.
class BleConnection {
  /// Unique identifier for this connection session.
  final String sessionId;

  /// The remote device we're connected to.
  final BleDevice remoteDevice;

  /// Our role in this connection.
  final BleRole localRole;

  /// When the connection was established.
  final DateTime connectedAt;

  const BleConnection({
    required this.sessionId,
    required this.remoteDevice,
    required this.localRole,
    required this.connectedAt,
  });

  @override
  String toString() =>
      'BleConnection(session: $sessionId, remote: ${remoteDevice.name}, role: $localRole)';

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'remoteDevice': remoteDevice.toMap(),
        'localRole': localRole.name,
        'connectedAt': connectedAt.toIso8601String(),
      };

  factory BleConnection.fromMap(Map<String, dynamic> map) => BleConnection(
        sessionId: map['sessionId'] as String,
        remoteDevice:
            BleDevice.fromMap(map['remoteDevice'] as Map<String, dynamic>),
        localRole: BleRole.values.byName(map['localRole'] as String),
        connectedAt: DateTime.parse(map['connectedAt'] as String),
      );
}

/// Our role in the BLE connection.
enum BleRole {
  /// We are the host (BLE Peripheral / advertiser).
  /// The host created the game and is waiting for someone to join.
  host,

  /// We are the joiner (BLE Central / scanner).
  /// The joiner discovered a game and connected to it.
  joiner,
}

/// Connection state lifecycle.
enum BleConnectionState {
  /// Not connected.
  disconnected,

  /// Attempting to connect.
  connecting,

  /// Connected and ready to exchange messages.
  connected,

  /// Connection lost, attempting to reconnect.
  reconnecting,

  /// Connection failed.
  failed,
}
