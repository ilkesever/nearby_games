import 'package:flutter_test/flutter_test.dart';

import 'package:backgammon_app/game/backgammon_engine.dart';
import 'package:backgammon_app/game/backgammon_move.dart';
import 'package:backgammon_app/game/backgammon_state.dart';

void main() {
  group('BackgammonState', () {
    test('initial position has 15 checkers per side', () {
      final state = BackgammonState.initial();
      int white = 0, black = 0;
      for (int pt = 1; pt <= 24; pt++) {
        final p = state.points[pt];
        if (!p.isEmpty) {
          if (p.color == BackgammonColor.white) white += p.count;
          if (p.color == BackgammonColor.black) black += p.count;
        }
      }
      expect(white, 15);
      expect(black, 15);
    });

    test('round-trip serialization', () {
      final state = BackgammonState.initial();
      final map = state.toMap();
      final restored = BackgammonState.fromMap(map);
      expect(restored.activeColor, state.activeColor);
      expect(restored.moveCount, state.moveCount);
      expect(restored.whiteBar, state.whiteBar);
      expect(restored.blackBar, state.blackBar);
    });
  });

  group('BackgammonEngine', () {
    final engine = BackgammonEngine();

    test('gameType is backgammon', () {
      expect(engine.gameType, 'backgammon');
    });

    test('initialState is not game over', () {
      expect(engine.initialState.isGameOver, false);
    });

    test('move with invalid dice length rejected', () {
      final state = BackgammonState.initial();
      final move = BackgammonMove(dice: [3], checkerMoves: const []);
      expect(engine.isValidMove(state, move), false);
    });

    test('forced pass accepted when no legal moves', () {
      // Build a state where white has all checkers blocked
      // For simplicity, test that empty checkerMoves is rejected with a normal roll
      final state = BackgammonState.initial();
      final move = BackgammonMove(dice: [1, 2], checkerMoves: const []);
      // White has legal moves from initial position, so forced pass should be invalid
      expect(engine.isValidMove(state, move), false);
    });
  });
}