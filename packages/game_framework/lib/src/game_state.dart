/// Abstract base class for game state.
///
/// Each game (chess, backgammon, etc.) implements this with its own
/// state representation. The framework uses serialization to sync
/// state between devices.
///
/// Example:
/// ```dart
/// class ChessState extends GameState {
///   final List<List<ChessPiece?>> board;
///   final PlayerColor activePlayer;
///   // ...
/// }
/// ```
abstract class GameState {
  /// Which player's turn it is (0-indexed).
  int get activePlayerIndex;

  /// Whether the game has ended.
  bool get isGameOver;

  /// The index of the winning player, or null if draw/ongoing.
  int? get winnerIndex;

  /// Serialize the game state to a JSON-compatible map.
  Map<String, dynamic> toMap();

  /// The number of moves that have been made.
  int get moveCount;
}

/// The result of a completed game.
enum GameResult {
  /// Player 0 (host) wins.
  player0Wins,

  /// Player 1 (joiner) wins.
  player1Wins,

  /// The game ended in a draw.
  draw,

  /// The game was abandoned.
  abandoned,
}

/// Represents a player's role/color/side in the game.
enum PlayerSide {
  /// First player (typically white in chess, etc.).
  player0,

  /// Second player (typically black in chess, etc.).
  player1,
}
