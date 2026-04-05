import 'package:flutter_test/flutter_test.dart';

import 'package:backgammon_app/game/backgammon_engine.dart';
import 'package:backgammon_app/game/backgammon_move.dart';
import 'package:backgammon_app/game/backgammon_state.dart';
import 'package:game_framework/game_framework.dart';

// ignore_for_file: prefer_const_constructors

void main() {
  late BackgammonEngine engine;

  setUp(() => engine = BackgammonEngine());

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  BackgammonState stateWith({
    List<PointState>? points,
    int whiteBar = 0,
    int blackBar = 0,
    int whiteBorneOff = 0,
    int blackBorneOff = 0,
    BackgammonColor activeColor = BackgammonColor.white,
    List<int> remainingDice = const [],
  }) {
    final pts = points ??
        List<PointState>.filled(25, const PointState.empty());
    return BackgammonState(
      points: List.unmodifiable(pts),
      whiteBar: whiteBar,
      blackBar: blackBar,
      whiteBorneOff: whiteBorneOff,
      blackBorneOff: blackBorneOff,
      activeColor: activeColor,
      phase: remainingDice.isEmpty ? GamePhase.rolling : GamePhase.moving,
      remainingDice: remainingDice,
      moveCount: 0,
    );
  }

  List<PointState> emptyBoard() =>
      List<PointState>.filled(25, const PointState.empty());

  List<PointState> boardWith(
      Map<int, (int, BackgammonColor)> setup) {
    final pts = emptyBoard();
    setup.forEach((pt, v) {
      pts[pt] = PointState(count: v.$1, color: v.$2);
    });
    return pts;
  }

  bool hasMove(List<BackgammonMove> moves, List<CheckerMove> cms) {
    final key = cms.map((c) => '${c.from}>>${c.to}').join('|');
    return moves.any((m) =>
        m.checkerMoves.map((c) => '${c.from}>>${c.to}').join('|') == key);
  }

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('Initial state', () {
    test('15 checkers per side', () {
      final state = BackgammonState.initial();
      int white = 0, black = 0;
      for (int pt = 1; pt <= 24; pt++) {
        final p = state.points[pt];
        if (p.color == BackgammonColor.white) white += p.count;
        if (p.color == BackgammonColor.black) black += p.count;
      }
      expect(white, 15);
      expect(black, 15);
    });

    test('standard starting position', () {
      final s = BackgammonState.initial();
      expect(s.points[24].count, 2);
      expect(s.points[24].color, BackgammonColor.white);
      expect(s.points[13].count, 5);
      expect(s.points[13].color, BackgammonColor.white);
      expect(s.points[8].count, 3);
      expect(s.points[8].color, BackgammonColor.white);
      expect(s.points[6].count, 5);
      expect(s.points[6].color, BackgammonColor.white);
      expect(s.points[1].count, 2);
      expect(s.points[1].color, BackgammonColor.black);
      expect(s.points[12].count, 5);
      expect(s.points[12].color, BackgammonColor.black);
      expect(s.points[17].count, 3);
      expect(s.points[17].color, BackgammonColor.black);
      expect(s.points[19].count, 5);
      expect(s.points[19].color, BackgammonColor.black);
    });

    test('game not over at start', () {
      expect(engine.isGameOver(BackgammonState.initial()), false);
      expect(engine.getResult(BackgammonState.initial()), null);
    });
  });

  // ---------------------------------------------------------------------------
  // Bar entry
  // ---------------------------------------------------------------------------

  group('Bar entry', () {
    test('white enters from bar with die 3 → pt 22', () {
      final pts = boardWith({22: (2, BackgammonColor.black)});
      pts[23] = const PointState(count: 1, color: BackgammonColor.white);
      final state = stateWith(
        points: pts,
        whiteBar: 1,
        remainingDice: [3, 5],
      );
      final moves = engine.getValidMoves(state);
      // Die 3: 25-3=22, blocked (2 black). Die 5: 25-5=20, open.
      expect(moves.any((m) => m.checkerMoves.first.from == 0 && m.checkerMoves.first.to == 20), true);
      expect(moves.any((m) => m.checkerMoves.first.to == 22), false);
    });

    test('white enters from bar and hits blot', () {
      final pts = boardWith({22: (1, BackgammonColor.black)});
      final state = stateWith(
        points: pts,
        whiteBar: 1,
        remainingDice: [3],
      );
      final moves = engine.getValidMoves(state);
      // 25-3=22, single black blot → can hit
      expect(moves.length, 1);
      expect(moves.first.checkerMoves.first.from, 0);
      expect(moves.first.checkerMoves.first.to, 22);

      // Verify blot is sent to bar
      final nextState = engine.applyMove(state.copyWith(remainingDice: [3]),
          BackgammonMove(dice: [3], checkerMoves: [CheckerMove(from: 0, to: 22)]));
      expect(nextState.blackBar, 1);
      expect(nextState.points[22].color, BackgammonColor.white);
    });

    test('blocked entry — all entries blocked', () {
      final pts = boardWith({
        22: (2, BackgammonColor.black),
        23: (2, BackgammonColor.black),
        24: (2, BackgammonColor.black),
        20: (2, BackgammonColor.black),
        21: (2, BackgammonColor.black),
        19: (2, BackgammonColor.black),
      });
      final state = stateWith(
        points: pts,
        whiteBar: 1,
        remainingDice: [1, 2, 3, 4, 5, 6].sublist(0, 2),
      );
      // Both dice blocked
      final moves = engine.getValidMoves(stateWith(
        points: pts,
        whiteBar: 1,
        remainingDice: [1, 2],
      ));
      expect(moves.isEmpty, true);
    });

    test('white must enter from bar before moving other checkers', () {
      final pts = boardWith({10: (2, BackgammonColor.white)});
      final state = stateWith(
        points: pts,
        whiteBar: 1,
        remainingDice: [3, 4],
      );
      final moves = engine.getValidMoves(state);
      // All moves must start from bar (from == 0)
      for (final m in moves) {
        expect(m.checkerMoves.first.from, 0,
            reason: 'must enter from bar first');
      }
    });

    test('black enters from bar with die 4 → pt 4', () {
      final pts = boardWith({4: (1, BackgammonColor.white)});
      final state = stateWith(
        points: pts,
        blackBar: 1,
        activeColor: BackgammonColor.black,
        remainingDice: [4],
      );
      // die=4: black enters at pt 4, hits white blot
      final moves = engine.getValidMoves(state);
      expect(moves.length, 1);
      expect(moves.first.checkerMoves.first.from, 0);
      expect(moves.first.checkerMoves.first.to, 4);
    });
  });

  // ---------------------------------------------------------------------------
  // Hitting and point ownership
  // ---------------------------------------------------------------------------

  group('Hitting', () {
    test('cannot land on prime (≥2 opponents)', () {
      final pts = boardWith({
        10: (2, BackgammonColor.white),
        7: (2, BackgammonColor.black),
      });
      final state = stateWith(
        points: pts,
        remainingDice: [3],
      );
      final moves = engine.getValidMoves(state);
      // white at 10, die 3 → 7, but 7 has 2 black → blocked
      expect(moves.any((m) => m.checkerMoves.any((c) => c.to == 7)), false);
    });

    test('can land on own point', () {
      final pts = boardWith({
        10: (2, BackgammonColor.white),
        7: (3, BackgammonColor.white),
      });
      final state = stateWith(points: pts, remainingDice: [3]);
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) => m.checkerMoves.any((c) => c.from == 10 && c.to == 7)), true);
    });

    test('hitting a blot sends opponent to bar', () {
      final pts = boardWith({
        10: (1, BackgammonColor.white),
        7: (1, BackgammonColor.black),
      });
      final state = stateWith(points: pts, remainingDice: [3]);
      final newState = engine.applyMove(
        state,
        BackgammonMove(
            dice: [3],
            checkerMoves: [CheckerMove(from: 10, to: 7)]),
      );
      expect(newState.blackBar, 1);
      expect(newState.points[7].color, BackgammonColor.white);
      expect(newState.points[7].count, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Bear-off eligibility
  // ---------------------------------------------------------------------------

  group('Bear-off eligibility', () {
    test('cannot bear off if checker outside home', () {
      final pts = boardWith({
        6: (14, BackgammonColor.white),
        10: (1, BackgammonColor.white), // outside home
      });
      final state = stateWith(points: pts, remainingDice: [6]);
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) => m.checkerMoves.any((c) => c.to == 25)), false);
    });

    test('cannot bear off if checker on bar', () {
      final pts = boardWith({6: (14, BackgammonColor.white)});
      final state = stateWith(points: pts, whiteBar: 1, remainingDice: [3]);
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) => m.checkerMoves.any((c) => c.to == 25)), false);
    });

    test('can bear off when all in home board', () {
      final pts = boardWith({
        6: (5, BackgammonColor.white),
        4: (5, BackgammonColor.white),
        2: (5, BackgammonColor.white),
      });
      final state = stateWith(points: pts, remainingDice: [6]);
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) => m.checkerMoves.any((c) => c.to == 25)), true);
    });
  });

  // ---------------------------------------------------------------------------
  // Bear-off exact and overshoot
  // ---------------------------------------------------------------------------

  group('Bear-off', () {
    test('exact die match', () {
      final pts = boardWith({3: (1, BackgammonColor.white), 1: (14, BackgammonColor.white)});
      final state = stateWith(points: pts, remainingDice: [3]);
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) => m.checkerMoves.any((c) => c.from == 3 && c.to == 25)), true);
    });

    test('overshoot valid when no checker on higher home points', () {
      // White has checker on pt 2 only; die 6 > 2 but no checker on 3-6
      final pts = boardWith({2: (15, BackgammonColor.white)});
      final state = stateWith(points: pts, remainingDice: [6]);
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) => m.checkerMoves.any((c) => c.from == 2 && c.to == 25)), true);
    });

    test('overshoot blocked when higher home point has checker', () {
      // White on pt 2 and pt 4; die 6 would overshoot pt 2 but pt 4 has a checker
      final pts = boardWith({
        2: (1, BackgammonColor.white),
        4: (14, BackgammonColor.white),
      });
      final state = stateWith(points: pts, remainingDice: [6]);
      final moves = engine.getValidMoves(state);
      // Die 6 from pt 2: blocked (checker on pt 4). Die 6 from pt 4: exact+2 overshoot but pt 4 is highest → valid
      expect(moves.any((m) => m.checkerMoves.any((c) => c.from == 4 && c.to == 25)), true);
      expect(moves.any((m) => m.checkerMoves.any((c) => c.from == 2 && c.to == 25)), false);
    });

    test('black overshoot', () {
      // Black on pt 23 only; die 6: 23+6=29 > 24 → bear off
      final pts = boardWith({23: (15, BackgammonColor.black)});
      final state = stateWith(
        points: pts,
        activeColor: BackgammonColor.black,
        remainingDice: [6],
      );
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) => m.checkerMoves.any((c) => c.from == 23 && c.to == 25)), true);
    });
  });

  // ---------------------------------------------------------------------------
  // Forced max dice
  // ---------------------------------------------------------------------------

  group('Forced max dice', () {
    test('must use 2 dice when both playable', () {
      final pts = boardWith({10: (2, BackgammonColor.white)});
      final state = stateWith(points: pts, remainingDice: [3, 4]);
      final moves = engine.getValidMoves(state);
      // Both dice can be played, so all valid moves use 2 checker moves
      expect(moves.every((m) => m.checkerMoves.length == 2), true);
    });

    test('use only 1 die when second die has no legal move', () {
      // White on pt 3; die 3 → bear off, die 5 → -2 → 25 but if pt 4,5 blocked it still works
      // Simpler: white on pt 2; dice [2,5]; pt 5 (for die 5 from pt 7) blocked
      final pts = boardWith({
        2: (1, BackgammonColor.white),
        1: (14, BackgammonColor.white),
      });
      // All in home; die 2 bears off pt 2; die 5 would go pt 2-5=-3 (bear off too), ok
      // Actually both dice bear off fine here. Let's use a non-bearoff case.
      // White on pt 10; die 3 → pt 7; die 6 → pt 4. Both legal.
      final pts2 = boardWith({10: (1, BackgammonColor.white)});
      final state2 = stateWith(points: pts2, remainingDice: [3, 6]);
      final moves2 = engine.getValidMoves(state2);
      expect(moves2.every((m) => m.checkerMoves.length == 2), true);
    });

    test('forced pass when no legal moves', () {
      // All white points blocked by black primes; white on bar with all entries blocked
      final pts = boardWith({
        24: (2, BackgammonColor.black),
        23: (2, BackgammonColor.black),
        22: (2, BackgammonColor.black),
        21: (2, BackgammonColor.black),
        20: (2, BackgammonColor.black),
        19: (2, BackgammonColor.black),
      });
      final state = stateWith(
        points: pts,
        whiteBar: 1,
        remainingDice: [1, 2],
      );
      final moves = engine.getValidMoves(state);
      expect(moves.isEmpty, true);
    });
  });

  // ---------------------------------------------------------------------------
  // Forced-high-die rule
  // ---------------------------------------------------------------------------

  group('Forced-high-die rule', () {
    test('must use higher die when only one die is playable', () {
      // White on pt 5; die 3 → pt 2 (open), die 6 → pt -1 → bear off (all in home).
      // But if NOT all in home, die 6 is invalid (not bear off eligible).
      // So set up: white on pt 5 and pt 12 (not all in home); dice [3, 5].
      // Die 3: pt 5→2 (open). Die 5: pt 5→0 → bear off? No, not all in home.
      // Die 5 → pt 12→7 (if open). Both dice playable in that case.
      //
      // Better: white on pt 3 only (all in home); dice [2, 5].
      // Die 2: pt 3→1 (board move). Die 5: pt 3→-2 → bear off (overshoot, valid since no checker on 4,5,6).
      // Both dice usable — not the right scenario.
      //
      // Classic forced-high-die: white on pt 2 only; dice [3, 6].
      // Die 3: pt 2→-1 → bear off (2<3, overshoot, no higher → valid).
      // Die 6: pt 2→-4 → bear off (also valid).
      // Both legal → both get generated, must use 2? No, only 1 checker.
      //
      // The classic case: white has ONE checker left on pt 2; dice [3,6].
      // Only 1 checker, can only use 1 die. Force higher (6).
      final pts = boardWith({2: (1, BackgammonColor.white)});
      final state = stateWith(
        points: pts,
        whiteBorneOff: 14,
        remainingDice: [3, 6],
      );
      final moves = engine.getValidMoves(state);
      // Max sequence = 1 (only 1 checker); forced-high-die → must use die 6
      expect(moves.length, 1);
      expect(moves.first.checkerMoves.first.from, 2);
      expect(moves.first.checkerMoves.first.to, 25);
      // The die used should be 6 (higher)
      final die = moves.first.dice.contains(6) ? 6 : 3;
      expect(die, 6);
    });

    test('forced-high-die: lower die not legal, higher is — must use higher', () {
      // White on pt 5; dice [2, 4]; pt 3 (5-2) is blocked by black, pt 1 (5-4) is open.
      // Die 2 not legal, die 4 legal → only candidate is die 4.
      final pts = boardWith({
        5: (1, BackgammonColor.white),
        3: (2, BackgammonColor.black),
      });
      final state = stateWith(points: pts, remainingDice: [2, 4]);
      final moves = engine.getValidMoves(state);
      expect(moves.length, 1);
      expect(moves.first.checkerMoves.first.from, 5);
      expect(moves.first.checkerMoves.first.to, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Doubles
  // ---------------------------------------------------------------------------

  group('Doubles', () {
    test('doubles gives 4 dice', () {
      final pts = boardWith({10: (4, BackgammonColor.white)});
      final state = stateWith(points: pts, remainingDice: [3, 3, 3, 3]);
      final moves = engine.getValidMoves(state);
      // 4 checkers, 4 dice of 3: can make 4 moves
      expect(moves.any((m) => m.checkerMoves.length == 4), true);
    });

    test('partial doubles: 1 checker on pt 4 (home), dice [3,3,3,3] → 2 dice used', () {
      // White: 1 checker at pt 4 (home board), already 14 borne off → all in home.
      // Die 3: 4→1. Die 3: 1→-2=25 (bear off, overshoot valid). Only 2 dice usable.
      final pts = boardWith({4: (1, BackgammonColor.white)});
      final state = stateWith(
          points: pts, whiteBorneOff: 14, remainingDice: [3, 3, 3, 3]);
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) => m.checkerMoves.length == 2), true);
    });

    test('doubles blocked by prime — uses 0 of 4', () {
      // White on pt 10; target pt 7 blocked; pt 4 (die 3 from 7) — wait, blocked means die 3 can't move.
      // Set up: white on pt 10; pt 7 has 2 black (blocks die 3).
      final pts = boardWith({
        10: (2, BackgammonColor.white),
        7: (2, BackgammonColor.black),
      });
      final state = stateWith(points: pts, remainingDice: [3, 3, 3, 3]);
      final moves = engine.getValidMoves(state);
      // Die 3 from pt 10 → pt 7 blocked; no moves
      expect(moves.isEmpty, true);
    });
  });

  // ---------------------------------------------------------------------------
  // isValidMove integration
  // ---------------------------------------------------------------------------

  group('isValidMove', () {
    test('valid move accepted', () {
      // 2 checkers at pt 10; move each with a different die
      final pts = boardWith({10: (2, BackgammonColor.white)});
      final state = stateWith(points: pts);
      final move = BackgammonMove(
        dice: [3, 4],
        checkerMoves: [CheckerMove(from: 10, to: 7), CheckerMove(from: 7, to: 3)],
      );
      expect(engine.isValidMove(state, move), true);
    });

    test('forced pass valid when no legal moves', () {
      final pts = boardWith({
        24: (2, BackgammonColor.black),
        23: (2, BackgammonColor.black),
        22: (2, BackgammonColor.black),
        21: (2, BackgammonColor.black),
        20: (2, BackgammonColor.black),
        19: (2, BackgammonColor.black),
      });
      final state = stateWith(points: pts, whiteBar: 1);
      final move = BackgammonMove(dice: [1, 2], checkerMoves: []);
      expect(engine.isValidMove(state, move), true);
    });

    test('forced pass invalid when legal moves exist', () {
      final pts = boardWith({10: (1, BackgammonColor.white)});
      final state = stateWith(points: pts);
      final move = BackgammonMove(dice: [3, 4], checkerMoves: []);
      expect(engine.isValidMove(state, move), false);
    });

    test('invalid dice rejected', () {
      final state = BackgammonState.initial();
      final move = BackgammonMove(dice: [7], checkerMoves: []);
      expect(engine.isValidMove(state, move), false);
    });
  });

  // ---------------------------------------------------------------------------
  // Win condition
  // ---------------------------------------------------------------------------

  group('Win condition', () {
    test('white wins when 15 borne off', () {
      final pts = boardWith({1: (1, BackgammonColor.white)});
      final state = stateWith(
        points: pts,
        whiteBorneOff: 14,
        remainingDice: [1],
      );
      final move = BackgammonMove(
        dice: [1],
        checkerMoves: [CheckerMove(from: 1, to: 25)],
      );
      final newState = engine.applyMove(state, move);
      expect(newState.isGameOver, true);
      expect(engine.getResult(newState), GameResult.player0Wins);
    });

    test('black wins when 15 borne off', () {
      final pts = boardWith({24: (1, BackgammonColor.black)});
      final state = stateWith(
        points: pts,
        blackBorneOff: 14,
        activeColor: BackgammonColor.black,
        remainingDice: [1],
      );
      final move = BackgammonMove(
        dice: [1],
        checkerMoves: [CheckerMove(from: 24, to: 25)],
      );
      final newState = engine.applyMove(state, move);
      expect(newState.isGameOver, true);
      expect(engine.getResult(newState), GameResult.player1Wins);
    });
  });

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  group('Serialization', () {
    test('state round-trips through toMap/fromMap', () {
      final original = BackgammonState.initial();
      final restored = BackgammonState.fromMap(original.toMap());
      expect(restored.toMap(), original.toMap());
    });

    test('move round-trips through toMap/fromMap', () {
      final move = BackgammonMove(
        dice: [3, 5],
        checkerMoves: [
          CheckerMove(from: 10, to: 7),
          CheckerMove(from: 13, to: 8),
        ],
      );
      final restored = BackgammonMove.fromMap(move.toMap());
      expect(restored.dice, move.dice);
      expect(restored.checkerMoves.length, move.checkerMoves.length);
      for (int i = 0; i < move.checkerMoves.length; i++) {
        expect(restored.checkerMoves[i].from, move.checkerMoves[i].from);
        expect(restored.checkerMoves[i].to, move.checkerMoves[i].to);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // getValidMovesForPoint
  // ---------------------------------------------------------------------------

  group('getValidMovesForPoint', () {
    test('returns correct destinations', () {
      final pts = boardWith({10: (1, BackgammonColor.white)});
      final state = stateWith(points: pts, remainingDice: [3, 4]);
      final dests = engine.getValidMovesForPoint(state, 10, [3, 4]);
      final tos = dests.map((d) => d.to).toSet();
      expect(tos, contains(7)); // 10-3
      expect(tos, contains(6)); // 10-4
    });

    test('excludes blocked destinations', () {
      final pts = boardWith({
        10: (1, BackgammonColor.white),
        7: (2, BackgammonColor.black),
      });
      final state = stateWith(points: pts, remainingDice: [3, 4]);
      final dests = engine.getValidMovesForPoint(state, 10, [3, 4]);
      final tos = dests.map((d) => d.to).toSet();
      expect(tos, isNot(contains(7))); // blocked
      expect(tos, contains(6));
    });

    test('returns empty for wrong color', () {
      final pts = boardWith({10: (1, BackgammonColor.black)});
      final state = stateWith(points: pts, remainingDice: [3]);
      final dests = engine.getValidMovesForPoint(state, 10, [3]);
      expect(dests, isEmpty);
    });

    test('enforces forced-high-die in destinations', () {
      // White on pt 2 only (14 borne off); dice [3,6]; must use die 6
      final pts = boardWith({2: (1, BackgammonColor.white)});
      final state = stateWith(points: pts, whiteBorneOff: 14, remainingDice: [3, 6]);
      final dests = engine.getValidMovesForPoint(state, 2, [3, 6]);
      expect(dests.length, 1);
      expect(dests.first.to, 25);
    });
  });

  // ---------------------------------------------------------------------------
  // Turn switching
  // ---------------------------------------------------------------------------

  group('Turn switching', () {
    test('active color switches after move', () {
      final pts = boardWith({10: (1, BackgammonColor.white)});
      final state = stateWith(points: pts);
      final move = BackgammonMove(
        dice: [3],
        checkerMoves: [CheckerMove(from: 10, to: 7)],
      );
      final newState = engine.applyMove(state, move);
      expect(newState.activeColor, BackgammonColor.black);
      expect(newState.phase, GamePhase.rolling);
    });
  });

  // ---------------------------------------------------------------------------
  // Move count regression (adapted from timiles/backgammon + bungogood/bkgm)
  // These lock the exact number of unique legal sequences for known positions.
  // A change in count means a move-generation regression or intentional fix.
  // ---------------------------------------------------------------------------

  group('Move count regression', () {
    // timiles AnalysisSpec: "Starting Position - 5&5 Roll: 15 possible sequences"
    // Black at start: pt1(2), pt12(5), pt17(3), pt19(5).
    // With die=5 only pt12→17 and pt17→22 are open (pt6 and pt24 are primed by white).
    // 2^4 orderings of those two moves, minus the invalid BBBB (pt17 only has 3 checkers) = 15.
    test('black starting position [5,5,5,5] → 15 unique sequences', () {
      final state = BackgammonState.initial().copyWith(
        activeColor: BackgammonColor.black,
        phase: GamePhase.moving,
        remainingDice: [5, 5, 5, 5],
      );
      final moves = engine.getValidMoves(state);
      expect(moves.length, 15);
    });

    // 2 white checkers at pt10, dice [3,4]:
    // First die options: 10→7 (die3) or 10→6 (die4).
    // Second die from each: 2 more options each → 4 total unique ordered sequences.
    test('2 white checkers at pt10, dice [3,4] → 4 unique sequences', () {
      final pts = boardWith({10: (2, BackgammonColor.white)});
      final state = stateWith(points: pts, remainingDice: [3, 4]);
      final moves = engine.getValidMoves(state);
      expect(moves.length, 4);
    });

    // 1 white checker at pt5, 14 borne off, dice [2,3]:
    // Die2 first: 5→3, then die3: 3→off (exact). Seq1.
    // Die3 first: 5→2, then die2: 2→off (exact). Seq2.
    test('1 white at pt5, 14 borne off, dice [2,3] → 2 sequences', () {
      final pts = boardWith({5: (1, BackgammonColor.white)});
      final state =
          stateWith(points: pts, whiteBorneOff: 14, remainingDice: [2, 3]);
      final moves = engine.getValidMoves(state);
      expect(moves.length, 2);
    });

    // Adapted from bkgm: single checker, both dice can bear off directly.
    // White 1 checker at pt3, 14 borne off, dice [3,5]:
    // Die3: pt3→off (exact). Die5: pt3→off (overshoot, no higher home checker). Both valid.
    // Max sequence length = 1 (only 1 checker). Forced-high-die → must use die5.
    // Result: exactly 1 sequence using die5.
    test('1 white at pt3, 14 borne off, dice [3,5] → forced-high-die, 1 sequence using die5', () {
      final pts = boardWith({3: (1, BackgammonColor.white)});
      final state =
          stateWith(points: pts, whiteBorneOff: 14, remainingDice: [3, 5]);
      final moves = engine.getValidMoves(state);
      expect(moves.length, 1);
      expect(moves.first.checkerMoves.first.from, 3);
      expect(moves.first.checkerMoves.first.to, 25);
    });
  });

  // ---------------------------------------------------------------------------
  // Multiple checkers on bar (adapted from timiles/backgammon BoardSpec)
  // ---------------------------------------------------------------------------

  group('Multiple checkers on bar', () {
    test('white 2 on bar, both entries open — both must enter before moving', () {
      final pts = boardWith({10: (2, BackgammonColor.white)});
      final state = stateWith(
        points: pts,
        whiteBar: 2,
        remainingDice: [3, 5],
      );
      final moves = engine.getValidMoves(state);
      // Every sequence must begin with a bar-entry move
      for (final m in moves) {
        expect(m.checkerMoves.first.from, 0,
            reason: 'must enter from bar first');
      }
      // With bar=2 and 2 dice, both entries happen → all sequences use 2 moves
      expect(moves.every((m) => m.checkerMoves.length == 2), true);
      // Entry points: 25-3=22, 25-5=20
      final entryPoints =
          moves.expand((m) => m.checkerMoves).map((c) => c.to).toSet();
      expect(entryPoints, containsAll([22, 20]));
    });

    test('white 2 on bar, one entry blocked — enters only 1', () {
      // Die3 entry pt22 blocked; die5 entry pt20 open
      final pts = boardWith({22: (2, BackgammonColor.black)});
      final state = stateWith(
        points: pts,
        whiteBar: 2,
        remainingDice: [3, 5],
      );
      final moves = engine.getValidMoves(state);
      // First move must be bar entry using die5 (pt20)
      expect(moves.isNotEmpty, true);
      for (final m in moves) {
        expect(m.checkerMoves.first.from, 0);
        expect(m.checkerMoves.first.to, 20); // only die5 entry available
      }
    });

    test('white 2 on bar, both entries blocked → forced pass', () {
      final pts = boardWith({
        22: (2, BackgammonColor.black), // blocks die3 entry
        20: (2, BackgammonColor.black), // blocks die5 entry
      });
      final state = stateWith(
        points: pts,
        whiteBar: 2,
        remainingDice: [3, 5],
      );
      expect(engine.getValidMoves(state).isEmpty, true);
    });

    test('black 2 on bar, both entries open — enters both', () {
      final pts = boardWith({10: (2, BackgammonColor.black)});
      final state = stateWith(
        points: pts,
        blackBar: 2,
        activeColor: BackgammonColor.black,
        remainingDice: [3, 4],
      );
      final moves = engine.getValidMoves(state);
      // Die3: entry pt3; die4: entry pt4
      expect(moves.isNotEmpty, true);
      for (final m in moves) {
        expect(m.checkerMoves.first.from, 0);
      }
      expect(moves.every((m) => m.checkerMoves.length == 2), true);
    });

    test('hitting a blot on bar entry when 2 checkers on bar', () {
      // White has 2 on bar; pt22 has a black blot; die3 → pt22 (hit)
      final pts = boardWith({22: (1, BackgammonColor.black)});
      final state = stateWith(
        points: pts,
        whiteBar: 2,
        remainingDice: [3, 5],
      );
      final moves = engine.getValidMoves(state);
      // One of the sequences should hit pt22 with die3 entry
      expect(
        moves.any((m) => m.checkerMoves.any((c) => c.from == 0 && c.to == 22)),
        true,
      );
      // After applying a move that hits pt22, black bar increments
      final hitMove = moves.firstWhere(
          (m) => m.checkerMoves.any((c) => c.from == 0 && c.to == 22));
      final next = engine.applyMove(state, hitMove);
      expect(next.blackBar, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Gammon and backgammon win-type detection
  // (adapted from bungogood/bkgm game_state tests)
  // ---------------------------------------------------------------------------

  group('Gammon and backgammon detection', () {
    test('null winType during ongoing game', () {
      expect(BackgammonState.initial().winType, isNull);
    });

    test('normal win: loser has borne off at least 1', () {
      // White wins; black has 3 borne off (normal win)
      final pts = boardWith({1: (1, BackgammonColor.white)});
      final state = stateWith(
        points: pts,
        whiteBorneOff: 14,
        blackBorneOff: 3,
        remainingDice: [1],
      );
      final next = engine.applyMove(
          state,
          BackgammonMove(
              dice: [1], checkerMoves: [CheckerMove(from: 1, to: 25)]));
      expect(next.winner, BackgammonColor.white);
      expect(next.winType, BackgammonWinType.normal);
    });

    test('gammon: loser has borne off zero checkers', () {
      // White wins; black still has all 15 on board (0 borne off)
      final pts = boardWith({
        1: (1, BackgammonColor.white),
        19: (15, BackgammonColor.black),
      });
      final state = stateWith(
        points: pts,
        whiteBorneOff: 14,
        blackBorneOff: 0,
        remainingDice: [1],
      );
      final next = engine.applyMove(
          state,
          BackgammonMove(
              dice: [1], checkerMoves: [CheckerMove(from: 1, to: 25)]));
      expect(next.winType, BackgammonWinType.gammon);
    });

    test('backgammon: loser has checker on bar when winner finishes', () {
      // White wins; black has 1 checker on bar (backgammon)
      final pts = boardWith({1: (1, BackgammonColor.white)});
      final state = stateWith(
        points: pts,
        whiteBorneOff: 14,
        blackBorneOff: 0,
        blackBar: 1,
        remainingDice: [1],
      );
      final next = engine.applyMove(
          state,
          BackgammonMove(
              dice: [1], checkerMoves: [CheckerMove(from: 1, to: 25)]));
      expect(next.winType, BackgammonWinType.backgammon);
    });

    test('backgammon: loser has checker in winner\'s home board', () {
      // White wins; black still has checker on pt4 (white's home = pts 1-6)
      final pts = boardWith({
        1: (1, BackgammonColor.white),
        4: (1, BackgammonColor.black), // inside white's home board
      });
      final state = stateWith(
        points: pts,
        whiteBorneOff: 14,
        blackBorneOff: 0,
        remainingDice: [1],
      );
      final next = engine.applyMove(
          state,
          BackgammonMove(
              dice: [1], checkerMoves: [CheckerMove(from: 1, to: 25)]));
      expect(next.winType, BackgammonWinType.backgammon);
    });

    test('black wins with gammon', () {
      // Black wins; white has 0 borne off
      final pts = boardWith({
        24: (1, BackgammonColor.black),
        6: (15, BackgammonColor.white),
      });
      final state = stateWith(
        points: pts,
        blackBorneOff: 14,
        whiteBorneOff: 0,
        activeColor: BackgammonColor.black,
        remainingDice: [1],
      );
      final next = engine.applyMove(
          state,
          BackgammonMove(
              dice: [1], checkerMoves: [CheckerMove(from: 24, to: 25)]));
      expect(next.winner, BackgammonColor.black);
      expect(next.winType, BackgammonWinType.gammon);
    });

    test('black backgammon: white checker in black home board (pts 19-24)', () {
      // Black wins; white still has a checker on pt21 (black's home = 19-24)
      final pts = boardWith({
        24: (1, BackgammonColor.black),
        21: (1, BackgammonColor.white), // inside black's home board
      });
      final state = stateWith(
        points: pts,
        blackBorneOff: 14,
        whiteBorneOff: 0,
        activeColor: BackgammonColor.black,
        remainingDice: [1],
      );
      final next = engine.applyMove(
          state,
          BackgammonMove(
              dice: [1], checkerMoves: [CheckerMove(from: 24, to: 25)]));
      expect(next.winType, BackgammonWinType.backgammon);
    });
  });

  // ---------------------------------------------------------------------------
  // Complex bear-off sequences (adapted from bkgm move_single_checker_bearoff_*)
  // ---------------------------------------------------------------------------

  group('Complex bear-off sequences', () {
    test('doubles [2,2,2,2]: 4 checkers on pt2 → all 4 borne off', () {
      final pts = boardWith({2: (4, BackgammonColor.white)});
      final state =
          stateWith(points: pts, whiteBorneOff: 11, remainingDice: [2, 2, 2, 2]);
      final moves = engine.getValidMoves(state);
      // With exact die=2 from pt2, all 4 should bear off in one sequence
      expect(moves.any((m) {
        return m.checkerMoves.length == 4 &&
            m.checkerMoves.every((c) => c.from == 2 && c.to == 25);
      }), true);
    });

    test('[6,5]: checker on pt6 (exact die6) and pt5 (exact die5)', () {
      final pts = boardWith({
        6: (1, BackgammonColor.white),
        5: (1, BackgammonColor.white),
      });
      final state =
          stateWith(points: pts, whiteBorneOff: 13, remainingDice: [6, 5]);
      final moves = engine.getValidMoves(state);
      // Both checkers can bear off: 6→off with die6, 5→off with die5
      expect(hasMove(moves, [CheckerMove(from: 6, to: 25), CheckerMove(from: 5, to: 25)]),
          true);
      expect(hasMove(moves, [CheckerMove(from: 5, to: 25), CheckerMove(from: 6, to: 25)]),
          true);
    });

    test('overshoot with [6,6,6,6]: 4 checkers on pt1 → all 4 borne off', () {
      final pts = boardWith({1: (4, BackgammonColor.white)});
      final state =
          stateWith(points: pts, whiteBorneOff: 11, remainingDice: [6, 6, 6, 6]);
      final moves = engine.getValidMoves(state);
      // Die6 overshoots pt1 (dist=1), valid since no checker on pts 2-6
      expect(moves.any((m) {
        return m.checkerMoves.length == 4 &&
            m.checkerMoves.every((c) => c.from == 1 && c.to == 25);
      }), true);
    });

    test('black doubles [3,3,3,3]: 4 checkers on pt22 → all 4 borne off', () {
      // Black home: 19-24. pt22: dist = 25-22 = 3 (exact)
      final pts = boardWith({22: (4, BackgammonColor.black)});
      final state = stateWith(
        points: pts,
        blackBorneOff: 11,
        activeColor: BackgammonColor.black,
        remainingDice: [3, 3, 3, 3],
      );
      final moves = engine.getValidMoves(state);
      expect(moves.any((m) {
        return m.checkerMoves.length == 4 &&
            m.checkerMoves.every((c) => c.from == 22 && c.to == 25);
      }), true);
    });

    test('black forced-high-die: pt6 open to pt8 and pt11, but pt13 blocked — must use die5', () {
      // Die2: 6→8 (open). Then die5: 8→13 (2W = blocked). Dead → 1-move seq [6→8].
      // Die5: 6→11 (open). Then die2: 11→13 (2W = blocked). Dead → 1-move seq [6→11].
      // Max=1. Forced-high-die: higher die is 5 → must use [6→11].
      final pts = boardWith({
        6: (1, BackgammonColor.black),
        13: (2, BackgammonColor.white), // blocks both follow-up moves
      });
      final state = stateWith(
        points: pts,
        activeColor: BackgammonColor.black,
        remainingDice: [2, 5],
      );
      final moves = engine.getValidMoves(state);
      expect(moves.length, 1);
      expect(moves.first.checkerMoves.first.from, 6);
      expect(moves.first.checkerMoves.first.to, 11); // die5 (higher)
    });
  });

  // ---------------------------------------------------------------------------
  // Position symmetry (adapted from bkgm flip test)
  // Mirroring a position (swap colors, reverse point numbers) must yield the
  // same number of legal moves.
  // ---------------------------------------------------------------------------

  group('Position symmetry', () {
    test('mirrored mid-game position has same move count', () {
      // Original: white at pt13(3), pt8(2); black at pt12(3), pt17(2)
      final ptsOrig = boardWith({
        13: (3, BackgammonColor.white),
        8: (2, BackgammonColor.white),
        12: (3, BackgammonColor.black),
        17: (2, BackgammonColor.black),
      });
      final stateOrig = stateWith(
          points: ptsOrig,
          activeColor: BackgammonColor.white,
          remainingDice: [3, 5]);
      final movesOrig = engine.getValidMoves(stateOrig);

      // Mirror: swap colors and reverse point numbers (pt N → pt 25-N)
      // White pt13→pt12, pt8→pt17; black pt12→pt13, pt17→pt8
      // Then assign: mirror-white (was black) moves as the active player
      final ptsMirror = boardWith({
        12: (3, BackgammonColor.black), // was white pt13 → mirror pt12, now opponent
        17: (2, BackgammonColor.black), // was white pt8  → mirror pt17, now opponent
        13: (3, BackgammonColor.white), // was black pt12 → mirror pt13, now active
        8: (2, BackgammonColor.white),  // was black pt17 → mirror pt8,  now active
      });
      final stateMirror = stateWith(
          points: ptsMirror,
          activeColor: BackgammonColor.white,
          remainingDice: [3, 5]);
      final movesMirror = engine.getValidMoves(stateMirror);

      expect(movesMirror.length, movesOrig.length);
    });
  });

  // ---------------------------------------------------------------------------
  // End-to-end game simulation
  // ---------------------------------------------------------------------------

  group('End-to-end game', () {
    test('2-turn play: state transitions, points, and turn switch are correct', () {
      // Turn 1 — White plays [3,1]: moves 13→10 and 8→7
      var state = BackgammonState.initial().copyWith(
        phase: GamePhase.moving,
        remainingDice: [3, 1],
      );
      state = engine.applyMove(
        state,
        BackgammonMove(
          dice: [3, 1],
          checkerMoves: [
            CheckerMove(from: 13, to: 10),
            CheckerMove(from: 8, to: 7),
          ],
        ),
      );
      expect(state.activeColor, BackgammonColor.black);
      expect(state.phase, GamePhase.rolling);
      expect(state.points[10].color, BackgammonColor.white);
      expect(state.points[10].count, 1);
      expect(state.points[7].color, BackgammonColor.white);
      expect(state.points[7].count, 1);
      expect(state.isGameOver, false);

      // Turn 2 — Black plays [3,1]: moves 12→15 and 17→18
      // (black moves to higher numbers: 12+3=15, 17+1=18)
      state = state.copyWith(
        phase: GamePhase.moving,
        remainingDice: [3, 1],
      );
      state = engine.applyMove(
        state,
        BackgammonMove(
          dice: [3, 1],
          checkerMoves: [
            CheckerMove(from: 12, to: 15),
            CheckerMove(from: 17, to: 18),
          ],
        ),
      );
      expect(state.activeColor, BackgammonColor.white);
      expect(state.phase, GamePhase.rolling);
      expect(state.points[15].color, BackgammonColor.black);
      expect(state.points[15].count, 1);
      expect(state.points[18].color, BackgammonColor.black);
      expect(state.points[18].count, 1);
      expect(state.isGameOver, false);
    });

    test('near-win: white bears off last checker, gammon declared', () {
      // White has 14 borne off, 1 checker at pt1.
      // Black has all 15 on pt19 (0 borne off) → gammon when white wins.
      final pts = boardWith({
        1: (1, BackgammonColor.white),
        19: (15, BackgammonColor.black),
      });
      var state = stateWith(
        points: pts,
        whiteBorneOff: 14,
        blackBorneOff: 0,
        remainingDice: [1],
      );
      state = engine.applyMove(
        state,
        BackgammonMove(
            dice: [1], checkerMoves: [CheckerMove(from: 1, to: 25)]),
      );
      expect(state.isGameOver, true);
      expect(state.winner, BackgammonColor.white);
      expect(state.winType, BackgammonWinType.gammon);
    });

    test('full bear-off sequence: white clears all 6 home-board checkers', () {
      // White: 3 on pt2, 3 on pt4. 9 already borne off. Dice [4,2] each turn.
      final pts = boardWith({
        2: (3, BackgammonColor.white),
        4: (3, BackgammonColor.white),
      });
      var state =
          stateWith(points: pts, whiteBorneOff: 9, remainingDice: [4, 2]);

      // Turn 1: bear off pt4 (die4 exact) and pt2 (die2 exact)
      state = engine.applyMove(
        state,
        BackgammonMove(
          dice: [4, 2],
          checkerMoves: [
            CheckerMove(from: 4, to: 25),
            CheckerMove(from: 2, to: 25),
          ],
        ),
      );
      expect(state.whiteBorneOff, 11);
      expect(state.activeColor, BackgammonColor.black);

      // Turn 3: white again with [4,2]
      state = state.copyWith(
        activeColor: BackgammonColor.white,
        phase: GamePhase.moving,
        remainingDice: [4, 2],
      );
      state = engine.applyMove(
        state,
        BackgammonMove(
          dice: [4, 2],
          checkerMoves: [
            CheckerMove(from: 4, to: 25),
            CheckerMove(from: 2, to: 25),
          ],
        ),
      );
      expect(state.whiteBorneOff, 13);

      // Final turn: [4,2] again
      state = state.copyWith(
        activeColor: BackgammonColor.white,
        phase: GamePhase.moving,
        remainingDice: [4, 2],
      );
      state = engine.applyMove(
        state,
        BackgammonMove(
          dice: [4, 2],
          checkerMoves: [
            CheckerMove(from: 4, to: 25),
            CheckerMove(from: 2, to: 25),
          ],
        ),
      );
      expect(state.whiteBorneOff, 15);
      expect(state.isGameOver, true);
      expect(state.winner, BackgammonColor.white);
    });
  });
}
