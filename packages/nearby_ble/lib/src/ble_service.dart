import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ble_connection.dart';
import 'ble_device.dart';
import 'ble_exceptions.dart';
import 'ble_message.dart';

/// Main service for BLE-based nearby communication.
///
/// Provides two modes of operation:
/// - **Host mode**: Advertise a game and wait for a player to join.
/// - **Join mode**: Scan for nearby games and connect to one.
///
/// Usage:
/// ```dart
/// final ble = BleService();
///
/// // Host a game
/// await ble.startHosting(gameType: 'chess', playerName: 'Alice');
/// ble.onConnection.listen((conn) => print('Player joined!'));
///
/// // Or join a game
/// ble.startScanning(gameType: 'chess');
/// ble.onDeviceFound.listen((device) async {
///   final conn = await ble.connect(device, playerName: 'Bob');
///   print('Connected to ${conn.remoteDevice.name}!');
/// });
/// ```
class BleService {
  static const MethodChannel _channel = MethodChannel('com.nearbygames/nearby_ble');
  static const EventChannel _eventChannel = EventChannel('com.nearbygames/nearby_ble/events');

  // --- Stream controllers ---
  final _deviceFoundController = StreamController<BleDevice>.broadcast();
  final _deviceLostController = StreamController<BleDevice>.broadcast();
  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  final _connectionController = StreamController<BleConnection>.broadcast();
  final _messageController = StreamController<BleMessage>.broadcast();
  final _errorController = StreamController<BleException>.broadcast();
  final _bleAvailableController = StreamController<bool>.broadcast();

  // --- State ---
  BleConnectionState _state = BleConnectionState.disconnected;
  BleConnection? _activeConnection;
  int _seqCounter = 0;
  StreamSubscription? _eventSubscription;

  /// Current connection state.
  BleConnectionState get state => _state;

  /// The active connection, if any.
  BleConnection? get activeConnection => _activeConnection;

  /// Whether we currently have an active connection.
  bool get isConnected => _state == BleConnectionState.connected;

  // --- Streams ---

  /// Stream of newly discovered devices (while scanning).
  Stream<BleDevice> get onDeviceFound => _deviceFoundController.stream;

  /// Stream of devices that are no longer visible.
  Stream<BleDevice> get onDeviceLost => _deviceLostController.stream;

  /// Stream of connection state changes.
  Stream<BleConnectionState> get onConnectionState =>
      _connectionStateController.stream;

  /// Stream of new connections (for hosts, when a joiner connects).
  Stream<BleConnection> get onConnection => _connectionController.stream;

  /// Stream of incoming messages from the remote device.
  Stream<BleMessage> get onMessage => _messageController.stream;

  /// Stream of BLE errors.
  Stream<BleException> get onError => _errorController.stream;

  /// Fires whenever the Bluetooth adapter becomes available or unavailable.
  ///
  /// On iOS this is called after CoreBluetooth settles its state — including
  /// after the user grants (or denies) the Bluetooth permission prompt for
  /// the first time. Listen to this stream to reactively update UI without
  /// requiring an app restart.
  Stream<bool> get onBleAvailabilityChanged => _bleAvailableController.stream;

  /// Initialize the BLE service.
  ///
  /// Call this once before using any other methods.
  /// Checks Bluetooth availability and requests permissions.
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
      _listenToEvents();
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  /// Check if Bluetooth is available and enabled.
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Request Bluetooth permissions from the user.
  ///
  /// Returns true if all required permissions were granted.
  Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  // ==========================================================================
  // HOST MODE - Advertise a game and accept connections
  // ==========================================================================

  /// Start hosting a game (BLE Peripheral mode).
  ///
  /// This advertises a BLE service with the given [gameType] so nearby
  /// devices can discover and connect to us.
  ///
  /// [gameType] - Unique identifier for the game (e.g., "chess", "backgammon").
  /// [playerName] - Display name for this player.
  /// [metadata] - Additional data to advertise (e.g., time control, variant).
  Future<void> startHosting({
    required String gameType,
    required String playerName,
    Map<String, String> metadata = const {},
  }) async {
    try {
      await _channel.invokeMethod('startHosting', {
        'gameType': gameType,
        'playerName': playerName,
        'metadata': metadata,
      });
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  /// Stop hosting (stop advertising).
  Future<void> stopHosting() async {
    try {
      await _channel.invokeMethod('stopHosting');
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  // ==========================================================================
  // JOIN MODE - Scan for games and connect
  // ==========================================================================

  /// Start scanning for nearby hosted games (BLE Central mode).
  ///
  /// Discovered devices will be emitted on [onDeviceFound].
  ///
  /// [gameType] - Only discover games of this type.
  Future<void> startScanning({required String gameType}) async {
    try {
      await _channel.invokeMethod('startScanning', {
        'gameType': gameType,
      });
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  /// Stop scanning for devices.
  Future<void> stopScanning() async {
    try {
      await _channel.invokeMethod('stopScanning');
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  /// Connect to a discovered device.
  ///
  /// Returns the [BleConnection] once established.
  Future<BleConnection> connect(
    BleDevice device, {
    required String playerName,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      _updateState(BleConnectionState.connecting);

      final result = await _channel
          .invokeMethod<Map>('connect', {
            'deviceId': device.id,
            'playerName': playerName,
          })
          .timeout(timeout, onTimeout: () {
            _updateState(BleConnectionState.failed);
            throw const BleTimeoutException('Connection');
          });

      final connection = BleConnection.fromMap(
        Map<String, dynamic>.from(result!),
      );
      _activeConnection = connection;
      _updateState(BleConnectionState.connected);

      return connection;
    } on PlatformException catch (e) {
      _updateState(BleConnectionState.failed);
      throw _mapPlatformException(e);
    }
  }

  // ==========================================================================
  // MESSAGING - Send and receive messages
  // ==========================================================================

  /// Send a message to the connected remote device.
  Future<void> send(BleMessage message) async {
    if (!isConnected) {
      throw const BleDisconnectedException();
    }
    try {
      final json = message.toJson();
      await _channel.invokeMethod('sendMessage', {
        'data': json,
      });
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  /// Send a game move to the remote device.
  ///
  /// This is a convenience method that wraps the payload in a [BleMessage]
  /// with type [BleMessageType.move].
  Future<void> sendMove(Map<String, dynamic> movePayload) async {
    final message = BleMessage.create(
      type: BleMessageType.move,
      seq: _nextSeq(),
      payload: movePayload,
    );
    await send(message);
  }

  /// Send a game state sync to the remote device.
  Future<void> sendStateSync(Map<String, dynamic> statePayload) async {
    final message = BleMessage.create(
      type: BleMessageType.stateSync,
      seq: _nextSeq(),
      payload: statePayload,
    );
    await send(message);
  }

  /// Send a typed message with payload.
  Future<void> sendTyped(
    BleMessageType type, [
    Map<String, dynamic> payload = const {},
  ]) async {
    final message = BleMessage.create(
      type: type,
      seq: _nextSeq(),
      payload: payload,
    );
    await send(message);
  }

  // ==========================================================================
  // CONNECTION MANAGEMENT
  // ==========================================================================

  /// Disconnect from the remote device.
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _activeConnection = null;
      _updateState(BleConnectionState.disconnected);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  /// Clean up all resources.
  ///
  /// Call this when the BLE service is no longer needed.
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await stopScanning().catchError((_) {});
    await stopHosting().catchError((_) {});
    await disconnect().catchError((_) {});

    _deviceFoundController.close();
    _deviceLostController.close();
    _connectionStateController.close();
    _connectionController.close();
    _messageController.close();
    _errorController.close();
    _bleAvailableController.close();
  }

  // ==========================================================================
  // PRIVATE METHODS
  // ==========================================================================

  int _nextSeq() => ++_seqCounter;

  void _updateState(BleConnectionState newState) {
    _state = newState;
    _connectionStateController.add(newState);
  }

  void _listenToEvents() {
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleEvent, onError: _handleError);
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;

    final map = Map<String, dynamic>.from(event);
    final eventType = map['event'] as String?;

    switch (eventType) {
      case 'deviceFound':
        final device = BleDevice.fromMap(
          Map<String, dynamic>.from(map['device'] as Map),
        );
        _deviceFoundController.add(device);

      case 'deviceLost':
        final device = BleDevice.fromMap(
          Map<String, dynamic>.from(map['device'] as Map),
        );
        _deviceLostController.add(device);

      case 'connected':
        final connection = BleConnection.fromMap(
          Map<String, dynamic>.from(map['connection'] as Map),
        );
        _activeConnection = connection;
        _updateState(BleConnectionState.connected);
        _connectionController.add(connection);

      case 'disconnected':
        _activeConnection = null;
        _updateState(BleConnectionState.disconnected);

      case 'message':
        final data = map['data'] as String;
        try {
          final message = BleMessage.fromJson(data);
          _messageController.add(message);
        } catch (e) {
          debugPrint('❌ [BLE] Failed to parse message: $e');
        }

      case 'bleStateChanged':
        final available = map['available'] as bool? ?? false;
        _bleAvailableController.add(available);

      case 'error':
        final code = map['code'] as String?;
        final msg = map['message'] as String? ?? 'Unknown error';
        _errorController.add(BleException(msg, code: code));
    }
  }

  void _handleError(dynamic error) {
    _errorController.add(BleException('Event stream error: $error'));
  }

  BleException _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'BLE_UNAVAILABLE':
        return const BleUnavailableException();
      case 'BLE_DISABLED':
        return const BleDisabledException();
      case 'BLE_PERMISSION_DENIED':
        return const BlePermissionDeniedException();
      case 'BLE_CONNECTION_FAILED':
        return BleConnectionException(e.message ?? 'Connection failed');
      case 'BLE_DISCONNECTED':
        return const BleDisconnectedException();
      case 'BLE_SEND_FAILED':
        return BleSendException(e.message ?? 'Send failed');
      case 'BLE_TIMEOUT':
        return BleTimeoutException(e.message ?? 'Operation');
      default:
        return BleException(e.message ?? 'Unknown error', code: e.code);
    }
  }
}
