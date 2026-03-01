import 'game_state.dart';

/// Abstract game engine that each game must implement.
///
/// The engine defines the rules, move validation, and state transitions
/// for a specific game. The framework handles communication — the engine
/// handles game logic.
///
/// Type parameters:
/// - [TState] — The game state type (e.g., `ChessState`).
/// - [TMove] — The move type (e.g., `ChessMove`).
///
/// Example implementation:
/// ```dart
/// class ChessEngine extends GameEngine<ChessState, ChessMove> {
///   @override
///   String get gameType => 'chess';
///
///   @override
///   ChessState get initialState => ChessState.newGame();
///
///   @override
///   ChessState applyMove(ChessState state, ChessMove move) {
///     // Apply the move and return new state
///   }
///
///   @override
///   bool isValidMove(ChessState state, ChessMove move) {
///     // Validate the move against current state
///   }
/// }
/// ```
abstract class GameEngine<TState extends GameState, TMove> {
  /// Unique identifier for this game type.
  /// Used for BLE service discovery filtering.
  /// Examples: "chess", "backgammon", "checkers"
  String get gameType;

  /// Human-readable name of the game.
  String get gameName;

  /// The initial state when a new game starts.
  TState get initialState;

  /// Apply a move to the current state, returning the new state.
  ///
  /// This should be a pure function — same inputs always produce same outputs.
  /// The framework calls this on both devices to keep state in sync.
  TState applyMove(TState state, TMove move);

  /// Check if a move is valid in the current state.
  ///
  /// Called before applying a move. If this returns false, the move is
  /// rejected and not sent to the opponent.
  bool isValidMove(TState state, TMove move);

  /// Get all valid moves for the current active player.
  ///
  /// Used by the UI to highlight available moves.
  List<TMove> getValidMoves(TState state);

  /// Check if the game is over.
  bool isGameOver(TState state);

  /// Get the game result if the game is over.
  GameResult? getResult(TState state);

  /// Serialize a move to a JSON-compatible map for BLE transmission.
  Map<String, dynamic> serializeMove(TMove move);

  /// Deserialize a move from a JSON map received via BLE.
  TMove deserializeMove(Map<String, dynamic> map);

  /// Serialize a state to a JSON-compatible map for state sync.
  Map<String, dynamic> serializeState(TState state);

  /// Deserialize a state from a JSON map.
  TState deserializeState(Map<String, dynamic> map);
}
