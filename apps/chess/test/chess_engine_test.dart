import 'package:flutter_test/flutter_test.dart';
import 'package:game_framework/game_framework.dart';
import 'package:chess_app/game/chess_engine.dart';
import 'package:chess_app/game/chess_move.dart';
import 'package:chess_app/game/chess_state.dart';

void main() {
  late ChessEngine engine;
  late ChessState state;

  setUp(() {
    engine = ChessEngine();
    state = engine.initialState;
  });

  group('Initial state', () {
    test('should start with white to move', () {
      expect(state.activeColor, ChessColor.white);
      expect(state.activePlayerIndex, 0);
    });

    test('should have all 32 pieces', () {
      final pieces = state.board.where((p) => p != null).toList();
      expect(pieces.length, 32);
      expect(pieces.where((p) => p!.color == ChessColor.white).length, 16);
      expect(pieces.where((p) => p!.color == ChessColor.black).length, 16);
    });

    test('should not be game over', () {
      expect(state.isGameOver, false);
      expect(engine.isGameOver(state), false);
    });

    test('white should have 20 valid opening moves', () {
      final moves = engine.getValidMoves(state);
      // 16 pawn moves (8 single + 8 double) + 4 knight moves
      expect(moves.length, 20);
    });
  });

  group('Pawn moves', () {
    test('e2-e4 should be valid', () {
      final move = ChessMove.fromAlgebraic('e2', 'e4');
      expect(engine.isValidMove(state, move), true);
    });

    test('e2-e3 should be valid', () {
      final move = ChessMove.fromAlgebraic('e2', 'e3');
      expect(engine.isValidMove(state, move), true);
    });

    test('e2-e5 should be invalid (too far)', () {
      final move = ChessMove.fromAlgebraic('e2', 'e5');
      expect(engine.isValidMove(state, move), false);
    });

    test('applying e2-e4 should switch to black', () {
      final move = ChessMove.fromAlgebraic('e2', 'e4');
      final newState = engine.applyMove(state, move);
      expect(newState.activeColor, ChessColor.black);
      expect(newState.pieceAt(36), isNotNull); // e4
      expect(newState.pieceAt(52), isNull); // e2 is now empty
    });

    test('pawn double push should set en passant target', () {
      final move = ChessMove.fromAlgebraic('e2', 'e4');
      final newState = engine.applyMove(state, move);
      expect(newState.enPassantTarget, isNotNull);
      // en passant target should be e3 (index 44)
      expect(newState.enPassantTarget, 44);
    });
  });

  group('Knight moves', () {
    test('Nf3 should be valid', () {
      final move = ChessMove.fromAlgebraic('g1', 'f3');
      expect(engine.isValidMove(state, move), true);
    });

    test('Nc3 should be valid', () {
      final move = ChessMove.fromAlgebraic('b1', 'c3');
      expect(engine.isValidMove(state, move), true);
    });
  });

  group('Turn enforcement', () {
    test('black cannot move on white turn', () {
      final move = ChessMove.fromAlgebraic('e7', 'e5');
      expect(engine.isValidMove(state, move), false);
    });

    test('after white moves, black can move', () {
      final whiteMove = ChessMove.fromAlgebraic('e2', 'e4');
      final newState = engine.applyMove(state, whiteMove);

      final blackMove = ChessMove.fromAlgebraic('e7', 'e5');
      expect(engine.isValidMove(newState, blackMove), true);
    });
  });

  group('Check detection', () {
    test('scholar\'s mate should result in checkmate', () {
      // 1. e4 e5  2. Bc4 Nc6  3. Qh5 Nf6  4. Qxf7#
      var s = state;
      s = engine.applyMove(s, ChessMove.fromAlgebraic('e2', 'e4'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('e7', 'e5'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('f1', 'c4'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('b8', 'c6'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('d1', 'h5'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('g8', 'f6'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('h5', 'f7'));

      expect(s.isGameOver, true);
      expect(s.winner, ChessColor.white);
      expect(s.isInCheck, true);
      expect(engine.getResult(s), GameResult.player0Wins);
    });
  });

  group('Castling', () {
    test('cannot castle through pieces', () {
      // King-side castle not valid at start
      final move = ChessMove.fromAlgebraic('e1', 'g1');
      expect(engine.isValidMove(state, move), false);
    });

    test('king-side castle works when path is clear', () {
      // Clear the path: 1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5
      var s = state;
      s = engine.applyMove(s, ChessMove.fromAlgebraic('e2', 'e4'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('e7', 'e5'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('g1', 'f3'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('b8', 'c6'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('f1', 'c4'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('f8', 'c5'));

      // Now O-O should be valid
      final castle = ChessMove.fromAlgebraic('e1', 'g1');
      expect(engine.isValidMove(s, castle), true);

      // Apply it
      final afterCastle = engine.applyMove(s, castle);
      // King should be on g1 (index 62)
      expect(afterCastle.pieceAt(62)?.type, ChessPieceType.king);
      // Rook should be on f1 (index 61)
      expect(afterCastle.pieceAt(61)?.type, ChessPieceType.rook);
      // Original squares empty
      expect(afterCastle.pieceAt(60), isNull); // e1
      expect(afterCastle.pieceAt(63), isNull); // h1
    });
  });

  group('Serialization', () {
    test('move round-trips through serialization', () {
      final move = ChessMove.fromAlgebraic('e2', 'e4');
      final map = engine.serializeMove(move);
      final restored = engine.deserializeMove(map);
      expect(restored.from, move.from);
      expect(restored.to, move.to);
    });

    test('state round-trips through serialization', () {
      final map = engine.serializeState(state);
      final restored = engine.deserializeState(map);
      expect(restored.activeColor, state.activeColor);
      expect(restored.board.length, 64);
      expect(restored.castlingRights.whiteKingSide, true);
    });

    test('move algebraic notation works', () {
      final move = ChessMove.fromAlgebraic('e2', 'e4');
      expect(move.fromAlgebraic, 'e2');
      expect(move.toAlgebraic, 'e4');
    });
  });

  group('En passant', () {
    test('en passant capture works', () {
      // 1. e4 d5 2. e5 f5 3. exf6 (en passant)
      var s = state;
      s = engine.applyMove(s, ChessMove.fromAlgebraic('e2', 'e4'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('d7', 'd5'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('e4', 'e5'));
      s = engine.applyMove(s, ChessMove.fromAlgebraic('f7', 'f5'));

      // en passant should be available
      expect(s.enPassantTarget, isNotNull);

      // exf6 en passant
      final epMove = ChessMove.fromAlgebraic('e5', 'f6');
      expect(engine.isValidMove(s, epMove), true);

      final afterEp = engine.applyMove(s, epMove);
      // Pawn should be on f6
      expect(afterEp.pieceAt(21)?.type, ChessPieceType.pawn); // f6
      // f5 should be empty (captured pawn removed)
      expect(afterEp.pieceAt(29), isNull); // f5
    });
  });
}
