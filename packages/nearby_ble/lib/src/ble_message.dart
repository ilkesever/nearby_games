import 'dart:convert';
import 'dart:typed_data';

/// A message sent over BLE between connected devices.
///
/// Messages are serialized to JSON, then to bytes for BLE transport.
/// The native platform plugins (iOS/Android) handle chunking and reassembly
/// for messages that exceed the negotiated BLE MTU size using a 4-byte
/// chunk header protocol: [0xAA magic, messageId, chunkIndex, totalChunks].
class BleMessage {
  /// Protocol version for forward compatibility.
  static const int protocolVersion = 1;

  /// Message type identifier.
  final BleMessageType type;

  /// Monotonically increasing sequence number for ordering.
  final int seq;

  /// Timestamp when the message was created.
  final DateTime timestamp;

  /// The message payload (game-specific data).
  final Map<String, dynamic> payload;

  const BleMessage({
    required this.type,
    required this.seq,
    required this.timestamp,
    required this.payload,
  });

  /// Create a new message with the current timestamp.
  factory BleMessage.create({
    required BleMessageType type,
    required int seq,
    Map<String, dynamic> payload = const {},
  }) =>
      BleMessage(
        type: type,
        seq: seq,
        timestamp: DateTime.now(),
        payload: payload,
      );

  /// Serialize to JSON map.
  Map<String, dynamic> toMap() => {
        'v': protocolVersion,
        'type': type.name,
        'seq': seq,
        'ts': timestamp.millisecondsSinceEpoch,
        'payload': payload,
      };

  /// Serialize to JSON string.
  String toJson() => jsonEncode(toMap());

  /// Serialize to bytes for BLE transport.
  Uint8List toBytes() => Uint8List.fromList(utf8.encode(toJson()));

  /// Deserialize from JSON map.
  factory BleMessage.fromMap(Map<String, dynamic> map) => BleMessage(
        type: BleMessageType.values.byName(map['type'] as String),
        seq: map['seq'] as int,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['ts'] as int),
        payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
      );

  /// Deserialize from JSON string.
  factory BleMessage.fromJson(String json) =>
      BleMessage.fromMap(jsonDecode(json) as Map<String, dynamic>);

  /// Deserialize from bytes.
  factory BleMessage.fromBytes(Uint8List bytes) =>
      BleMessage.fromJson(utf8.decode(bytes));

  @override
  String toString() =>
      'BleMessage(type: ${type.name}, seq: $seq, payload: $payload)';
}

/// Types of messages in the BLE game protocol.
enum BleMessageType {
  /// A game move (e.g., chess piece moved from e2 to e4).
  move,

  /// Full state synchronization (used on connect/reconnect).
  stateSync,

  /// Game start signal with initial configuration.
  gameStart,

  /// Game over with result.
  gameOver,

  /// Player resigned.
  resign,

  /// Draw offered.
  drawOffer,

  /// Draw accepted.
  drawAccept,

  /// Draw declined.
  drawDecline,

  /// Keep-alive ping.
  ping,

  /// Ping response.
  pong,

  /// Chat message.
  chat,

  /// Custom message type for game-specific extensions.
  custom,

  /// Rematch request — start a new game in the same session.
  rematch,
}
