import 'package:draughts_engine/draughts_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_framework/game_framework.dart';

import 'package:checkers_app/game/checkers_engine.dart';
import 'package:checkers_app/game/checkers_move.dart';
import 'package:checkers_app/game/checkers_state.dart';

void main() {
  late CheckersEngine engine;

  setUp(() => engine = CheckersEngine());

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initialState', () {
    test('white moves first (activePlayerIndex == 0)', () {
      final state = engine.initialState;
      expect(state.activePlayerIndex, 0);
    });

    test('game is not over at start', () {
      expect(engine.initialState.isGameOver, isFalse);
    });

    test('moveCount is 0 at start', () {
      expect(engine.initialState.moveCount, 0);
    });

    test('getValidMoves returns non-empty list at start', () {
      final moves = engine.getValidMoves(engine.initialState);
      expect(moves, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Move application
  // ---------------------------------------------------------------------------

  group('applyMove', () {
    test('applying a valid move increments moveCount', () {
      final state = engine.initialState;
      final move = engine.getValidMoves(state).first;
      final next = engine.applyMove(state, move);
      expect(next.moveCount, 1);
    });

    test('applying a valid move flips activePlayerIndex', () {
      final state = engine.initialState;
      final move = engine.getValidMoves(state).first;
      final next = engine.applyMove(state, move);
      expect(next.activePlayerIndex, 1);
    });

    test('applyMove does not mutate the original state (FEN unchanged)', () {
      final state = engine.initialState;
      final originalFen = state.draughts.fen();
      final move = engine.getValidMoves(state).first;
      engine.applyMove(state, move);
      expect(state.draughts.fen(), originalFen);
    });
  });

  // ---------------------------------------------------------------------------
  // Move validation
  // ---------------------------------------------------------------------------

  group('isValidMove', () {
    test('returns true for a move from getValidMoves', () {
      final state = engine.initialState;
      final move = engine.getValidMoves(state).first;
      expect(engine.isValidMove(state, move), isTrue);
    });

    test('returns false for a move with non-existent source square', () {
      final state = engine.initialState;
      expect(
        engine.isValidMove(state, CheckersMove(from: 1, to: 2)),
        isFalse,
      );
    });

    test('getValidMoves and isValidMove are consistent', () {
      final state = engine.initialState;
      final validMoves = engine.getValidMoves(state);
      for (final move in validMoves) {
        expect(engine.isValidMove(state, move), isTrue,
            reason: 'Move $move should be valid');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // getMovesFromSquare
  // ---------------------------------------------------------------------------

  group('getMovesFromSquare', () {
    test('returns only moves originating from that square', () {
      final state = engine.initialState;
      final allMoves = engine.getValidMoves(state);
      // Pick a square that has moves
      final sourceSquare = allMoves.first.from;
      final fromSquare = engine.getMovesFromSquare(state, sourceSquare);
      expect(fromSquare, isNotEmpty);
      for (final m in fromSquare) {
        expect(m.from, sourceSquare);
      }
    });

    test('returns empty list for a square with no piece', () {
      // Square 25 is typically empty at game start
      final state = engine.initialState;
      final moves = engine.getMovesFromSquare(state, 25);
      expect(moves, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Mandatory capture
  // ---------------------------------------------------------------------------

  group('mandatory capture', () {
    // Set up a position where white has a capture available.
    // White man on sq 28, black man on sq 23 → white must capture to 17.
    // FEN for international draughts: W:W28:B23
    test('only capture moves returned when a capture is available', () {
      final draughts = Draughts('W:W28:B23');
      final state = CheckersState(draughts);
      final moves = engine.getValidMoves(state);
      // All returned moves must be captures (they jump over an opponent piece)
      expect(moves, isNotEmpty);
      for (final m in moves) {
        // In a capture position the only legal moves are captures
        expect(engine.isValidMove(state, m), isTrue);
      }
      // Verify a non-capture move is NOT valid in this position
      expect(
        engine.isValidMove(state, CheckersMove(from: 28, to: 22)),
        isFalse,
        reason: 'Non-capture move should be rejected when capture is possible',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Win detection
  // ---------------------------------------------------------------------------

  group('game over / result', () {
    // In draughts, a player loses when it is THEIR turn and they cannot move.
    // So for white to win: it must be BLACK's turn with no black pieces.
    // FEN: B:W1:B  (black to move, white has piece on sq 1, black has none)
    test('isGameOver true when the active player has no pieces', () {
      final draughts = Draughts('B:W1:B');
      final state = CheckersState(draughts);
      expect(state.isGameOver, isTrue);
    });

    test('winnerIndex 0 when white wins (black has no pieces, black to move)', () {
      final draughts = Draughts('B:W1:B');
      final state = CheckersState(draughts);
      expect(state.winnerIndex, 0);
    });

    test('getResult returns player0Wins when white wins', () {
      final draughts = Draughts('B:W1:B');
      final state = CheckersState(draughts);
      expect(engine.getResult(state), GameResult.player0Wins);
    });

    // For black to win: white to move with no white pieces.
    // FEN: W:W:B1  (white to move, white has none, black has piece on sq 1)
    test('getResult returns player1Wins when black wins', () {
      final draughts = Draughts('W:W:B1');
      final state = CheckersState(draughts);
      expect(engine.getResult(state), GameResult.player1Wins);
    });

    test('getResult returns null when game is ongoing', () {
      expect(engine.getResult(engine.initialState), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Serialization round-trips
  // ---------------------------------------------------------------------------

  group('serialization', () {
    test('state FEN round-trip produces equivalent state', () {
      final state = engine.initialState;
      final map = engine.serializeState(state);
      final restored = engine.deserializeState(map);
      expect(restored.draughts.fen(), state.draughts.fen());
      expect(restored.moveCount, state.moveCount);
      expect(restored.activePlayerIndex, state.activePlayerIndex);
    });

    test('state round-trip after a move', () {
      var state = engine.initialState;
      final move = engine.getValidMoves(state).first;
      state = engine.applyMove(state, move);
      final map = engine.serializeState(state);
      final restored = engine.deserializeState(map);
      expect(restored.draughts.fen(), state.draughts.fen());
      expect(restored.moveCount, 1);
    });

    test('move round-trip preserves from/to and jumps', () {
      final move = CheckersMove(from: 32, to: 28, jumps: [32, 28]);
      final map = engine.serializeMove(move);
      final restored = engine.deserializeMove(map);
      expect(restored.from, 32);
      expect(restored.to, 28);
      expect(restored.jumps, [32, 28]);
    });

    test('move round-trip preserves multi-jump path', () {
      final move = CheckersMove(from: 20, to: 45, jumps: [20, 15, 30, 45]);
      final map = engine.serializeMove(move);
      final restored = engine.deserializeMove(map);
      expect(restored.jumps, [20, 15, 30, 45]);
    });
  });

  // ---------------------------------------------------------------------------
  // gameType
  // ---------------------------------------------------------------------------

  test('gameType is "checkers"', () {
    expect(engine.gameType, 'checkers');
  });
}
