import 'package:nearby_ble/nearby_ble.dart';
import 'game_state.dart';

/// Represents a player in a game session.
class GamePlayer {
  /// Display name of the player.
  final String name;

  /// Which side this player is on (player0 = host, player1 = joiner).
  final PlayerSide side;

  /// Whether this is the local player.
  final bool isLocal;

  /// The BLE device for remote players.
  final BleDevice? bleDevice;

  const GamePlayer({
    required this.name,
    required this.side,
    required this.isLocal,
    this.bleDevice,
  });

  /// Player index (0 or 1).
  int get index => side == PlayerSide.player0 ? 0 : 1;

  @override
  String toString() => 'GamePlayer($name, $side, local: $isLocal)';
}
