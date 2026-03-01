/// Base exception for all BLE-related errors.
class BleException implements Exception {
  final String message;
  final String? code;

  const BleException(this.message, {this.code});

  @override
  String toString() => 'BleException($code): $message';
}

/// Bluetooth is not available on this device.
class BleUnavailableException extends BleException {
  const BleUnavailableException()
      : super('Bluetooth is not available on this device',
            code: 'BLE_UNAVAILABLE');
}

/// Bluetooth is turned off.
class BleDisabledException extends BleException {
  const BleDisabledException()
      : super('Bluetooth is turned off. Please enable Bluetooth.',
            code: 'BLE_DISABLED');
}

/// Required permissions were not granted.
class BlePermissionDeniedException extends BleException {
  final List<String> missingPermissions;

  const BlePermissionDeniedException({this.missingPermissions = const []})
      : super('Bluetooth permissions not granted', code: 'BLE_PERMISSION_DENIED');
}

/// Failed to connect to a device.
class BleConnectionException extends BleException {
  const BleConnectionException(String message)
      : super(message, code: 'BLE_CONNECTION_FAILED');
}

/// Connection was lost unexpectedly.
class BleDisconnectedException extends BleException {
  const BleDisconnectedException()
      : super('BLE connection was lost', code: 'BLE_DISCONNECTED');
}

/// Failed to send a message.
class BleSendException extends BleException {
  const BleSendException(String message)
      : super(message, code: 'BLE_SEND_FAILED');
}

/// Operation timed out.
class BleTimeoutException extends BleException {
  const BleTimeoutException(String operation)
      : super('$operation timed out', code: 'BLE_TIMEOUT');
}
