import 'package:draughts_engine/draughts_engine.dart';
import 'package:game_framework/game_framework.dart';

/// Game state for a checkers match.
///
/// Wraps a [Draughts] instance from draughts_engine. State is serialized
/// via FEN strings, which the engine supports natively.
class CheckersState extends GameState {
  /// The underlying draughts engine instance.
  final Draughts draughts;

  /// Number of moves applied so far.
  final int _moveCount;

  CheckersState(this.draughts, [this._moveCount = 0]);

  // ---------------------------------------------------------------------------
  // GameState overrides
  // ---------------------------------------------------------------------------

  /// 0 = white (player0 / host), 1 = black (player1 / joiner).
  @override
  int get activePlayerIndex => draughts.turn == 'w' ? 0 : 1;

  @override
  bool get isGameOver => draughts.isGameOver;

  @override
  int? get winnerIndex {
    final w = draughts.getWinner();
    if (w == 'w') return 0;
    if (w == 'b') return 1;
    return null; // draw or game ongoing
  }

  @override
  int get moveCount => _moveCount;

  /// Number of white pieces currently on the board (0–20).
  int get whitePieceCount {
    int n = 0;
    for (int sq = 1; sq <= 50; sq++) {
      final p = draughts.getPiece(sq);
      if (p == 'w' || p == 'W') n++;
    }
    return n;
  }

  /// Number of black pieces currently on the board (0–20).
  int get blackPieceCount {
    int n = 0;
    for (int sq = 1; sq <= 50; sq++) {
      final p = draughts.getPiece(sq);
      if (p == 'b' || p == 'B') n++;
    }
    return n;
  }

  /// White pieces captured by black (0–20).
  int get whiteCaptured => 20 - whitePieceCount;

  /// Black pieces captured by white (0–20).
  int get blackCaptured => 20 - blackPieceCount;

  @override
  Map<String, dynamic> toMap() => {'fen': draughts.fen()};

  // ---------------------------------------------------------------------------
  // Serialization helpers (used by CheckersEngine)
  // ---------------------------------------------------------------------------

  static CheckersState fromMap(Map<String, dynamic> map) {
    final fen = map['fen'] as String;
    final moveCount = (map['n'] as int?) ?? 0;
    return CheckersState(Draughts(fen), moveCount);
  }

  /// Full map including move count, used by engine serialization.
  Map<String, dynamic> toFullMap() => {
        'fen': draughts.fen(),
        'n': _moveCount,
      };
}
