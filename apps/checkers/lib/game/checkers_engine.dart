import 'package:draughts_engine/draughts_engine.dart';
import 'package:game_framework/game_framework.dart';

import 'checkers_move.dart';
import 'checkers_state.dart';

/// GameEngine adapter for international 10×10 draughts using draughts_engine.
///
/// All game logic (mandatory capture, multi-jump, flying kings, etc.) is
/// delegated to the [Draughts] package. This class is a thin adapter that
/// maps between the framework's [GameEngine] interface and draughts_engine's API.
class CheckersEngine extends GameEngine<CheckersState, CheckersMove> {
  @override
  String get gameType => 'checkers';

  @override
  String get gameName => 'Checkers';

  @override
  CheckersState get initialState => CheckersState(Draughts());

  // ---------------------------------------------------------------------------
  // Rules
  // ---------------------------------------------------------------------------

  @override
  CheckersState applyMove(CheckersState state, CheckersMove move) {
    // Clone via FEN round-trip so the original state is never mutated.
    final copy = Draughts(state.draughts.fen());
    copy.move(from: move.from, to: move.to);
    return CheckersState(copy, state.moveCount + 1);
  }

  @override
  bool isValidMove(CheckersState state, CheckersMove move) {
    return state.draughts
        .moves()
        .any((m) => m.from == move.from && m.to == move.to);
  }

  @override
  List<CheckersMove> getValidMoves(CheckersState state) {
    return state.draughts
        .moves()
        .map((m) => CheckersMove(from: m.from, to: m.to, jumps: m.jumps, isCapture: m.takes.isNotEmpty))
        .toList();
  }

  /// Valid moves from a specific square.
  List<CheckersMove> getMovesFromSquare(CheckersState state, int square) {
    return state.draughts
        .moves(square)
        .map((m) => CheckersMove(from: m.from, to: m.to, jumps: m.jumps, isCapture: m.takes.isNotEmpty))
        .toList();
  }

  @override
  bool isGameOver(CheckersState state) => state.isGameOver;

  @override
  GameResult? getResult(CheckersState state) {
    if (!state.isGameOver) return null;
    switch (state.winnerIndex) {
      case 0:
        return GameResult.player0Wins;
      case 1:
        return GameResult.player1Wins;
      default:
        return GameResult.draw;
    }
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  @override
  Map<String, dynamic> serializeMove(CheckersMove move) => move.toMap();

  @override
  CheckersMove deserializeMove(Map<String, dynamic> map) =>
      CheckersMove.fromMap(map);

  @override
  Map<String, dynamic> serializeState(CheckersState state) =>
      state.toFullMap();

  @override
  CheckersState deserializeState(Map<String, dynamic> map) =>
      CheckersState.fromMap(map);
}
