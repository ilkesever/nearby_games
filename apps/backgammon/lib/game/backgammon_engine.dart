import 'dart:math' show max;

import 'package:game_framework/game_framework.dart';

import 'backgammon_move.dart';
import 'backgammon_state.dart';

class BackgammonEngine
    extends GameEngine<BackgammonState, BackgammonMove> {
  @override
  String get gameType => 'backgammon';

  @override
  String get gameName => 'Backgammon';

  @override
  BackgammonState get initialState => BackgammonState.initial();

  // ---------------------------------------------------------------------------
  // applyMove
  // ---------------------------------------------------------------------------

  @override
  BackgammonState applyMove(BackgammonState state, BackgammonMove move) {
    var s = state;
    for (final cm in move.checkerMoves) {
      s = applyCheckerMove(s, cm);
    }

    final immutablePts = List<PointState>.unmodifiable(s.points);

    // Check for win
    if (s.whiteBorneOff == 15 || s.blackBorneOff == 15) {
      return s.copyWith(
        points: immutablePts,
        phase: GamePhase.gameOver,
        remainingDice: const [],
        moveCount: state.moveCount + 1,
      );
    }

    // Switch to next player's rolling phase
    return s.copyWith(
      points: immutablePts,
      activeColor: state.activeColor.opposite,
      phase: GamePhase.rolling,
      remainingDice: const [],
      moveCount: state.moveCount + 1,
    );
  }

  // ---------------------------------------------------------------------------
  // isValidMove
  // ---------------------------------------------------------------------------

  @override
  bool isValidMove(BackgammonState state, BackgammonMove move) {
    if (state.isGameOver) return false;

    final dice = move.dice;
    if (dice.length != 2 && dice.length != 4) return false;
    if (dice.any((d) => d < 1 || d > 6)) return false;
    if (dice.length == 4 && dice.any((d) => d != dice[0])) return false;

    final simState = state.copyWith(remainingDice: dice);
    final validMoves = getValidMoves(simState);

    // Forced pass: valid only when no legal moves exist
    if (move.checkerMoves.isEmpty) {
      return validMoves.isEmpty;
    }

    // Check if submitted move matches any valid move
    final submitKey = move.checkerMoves
        .map((c) => '${c.from}>>${c.to}')
        .join('|');
    return validMoves.any((vm) {
      final vmKey = vm.checkerMoves
          .map((c) => '${c.from}>>${c.to}')
          .join('|');
      return vmKey == submitKey;
    });
  }

  // ---------------------------------------------------------------------------
  // getValidMoves — full recursive generation (the canonical source of truth)
  // ---------------------------------------------------------------------------

  @override
  List<BackgammonMove> getValidMoves(BackgammonState state) {
    if (state.isGameOver || state.remainingDice.isEmpty) return const [];

    final sequences = <List<CheckerMove>>[];
    _generateSequences(
        state, List<int>.from(state.remainingDice), [], sequences);

    if (sequences.isEmpty) return const [];

    // Must use maximum number of dice
    final maxLen = sequences.map((s) => s.length).reduce(max);
    final candidates =
        sequences.where((s) => s.length == maxLen).toList();

    // Forced-high-die rule
    final filtered =
        _applyForcedHighDie(state, candidates, state.remainingDice);

    // Deduplicate by sequence key
    final seen = <String>{};
    return filtered
        .where((s) =>
            seen.add(s.map((c) => '${c.from}>>${c.to}').join('|')))
        .map((s) => BackgammonMove(
            dice: state.remainingDice, checkerMoves: s))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // isGameOver / getResult
  // ---------------------------------------------------------------------------

  @override
  bool isGameOver(BackgammonState state) => state.isGameOver;

  @override
  GameResult? getResult(BackgammonState state) {
    if (state.winner == BackgammonColor.white) return GameResult.player0Wins;
    if (state.winner == BackgammonColor.black) return GameResult.player1Wins;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  @override
  Map<String, dynamic> serializeMove(BackgammonMove move) => move.toMap();

  @override
  BackgammonMove deserializeMove(Map<String, dynamic> map) =>
      BackgammonMove.fromMap(map);

  @override
  Map<String, dynamic> serializeState(BackgammonState state) =>
      state.toMap();

  @override
  BackgammonState deserializeState(Map<String, dynamic> map) =>
      BackgammonState.fromMap(map);

  // ---------------------------------------------------------------------------
  // UI helper: valid destinations for a checker at fromPoint given dice
  // Derives from getValidMoves() so all constraints are automatically enforced.
  // ---------------------------------------------------------------------------

  List<CheckerMove> getValidMovesForPoint(
      BackgammonState state, int fromPoint, List<int> dice) {
    final allMoves =
        getValidMoves(state.copyWith(remainingDice: dice));
    final dests = <int>{};
    for (final move in allMoves) {
      // Find first checker move from fromPoint in this sequence
      for (final cm in move.checkerMoves) {
        if (cm.from == fromPoint) {
          dests.add(cm.to);
          break;
        } else {
          // First move is from somewhere else — skip this sequence
          break;
        }
      }
    }
    return dests.map((to) => CheckerMove(from: fromPoint, to: to)).toList();
  }

  // ---------------------------------------------------------------------------
  // Public helper used by UI to advance intermediate board state mid-turn
  // ---------------------------------------------------------------------------

  BackgammonState applyCheckerMove(BackgammonState state, CheckerMove cm) {
    final color = state.activeColor;
    final pts = List<PointState>.from(state.points);
    var whiteBar = state.whiteBar;
    var blackBar = state.blackBar;
    var whiteBorneOff = state.whiteBorneOff;
    var blackBorneOff = state.blackBorneOff;

    // Remove checker from source
    if (cm.from == 0) {
      if (color == BackgammonColor.white) {
        whiteBar--;
      } else {
        blackBar--;
      }
    } else {
      final src = pts[cm.from];
      pts[cm.from] = PointState(
        count: src.count - 1,
        color: src.count - 1 == 0 ? null : src.color,
      );
    }

    // Place checker at destination
    if (cm.to == 25) {
      if (color == BackgammonColor.white) {
        whiteBorneOff++;
      } else {
        blackBorneOff++;
      }
    } else {
      final dest = pts[cm.to];
      if (dest.count == 1 && dest.color != null && dest.color != color) {
        // Hit blot — send opponent to bar
        if (dest.color == BackgammonColor.white) {
          whiteBar++;
        } else {
          blackBar++;
        }
        pts[cm.to] = PointState(count: 1, color: color);
      } else {
        pts[cm.to] = PointState(count: dest.count + 1, color: color);
      }
    }

    return state.copyWith(
      points: List.unmodifiable(pts),
      whiteBar: whiteBar,
      blackBar: blackBar,
      whiteBorneOff: whiteBorneOff,
      blackBorneOff: blackBorneOff,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: recursive move sequence generator
  // ---------------------------------------------------------------------------

  void _generateSequences(
      BackgammonState state,
      List<int> dice,
      List<CheckerMove> current,
      List<List<CheckerMove>> out) {
    bool moved = false;
    final tried = <int>{};

    for (int i = 0; i < dice.length; i++) {
      final die = dice[i];
      if (tried.contains(die)) continue;
      tried.add(die);

      for (final cm in _getPossibleCheckerMoves(state, die)) {
        moved = true;
        final newDice = List<int>.from(dice)..removeAt(i);
        final newState = applyCheckerMove(state, cm);
        _generateSequences(newState, newDice, [...current, cm], out);
      }
    }

    if (!moved && current.isNotEmpty) {
      out.add(current);
    }
  }

  // ---------------------------------------------------------------------------
  // Private: forced-high-die filter
  // Applies only when exactly 2 non-equal dice and max sequence length == 1.
  // ---------------------------------------------------------------------------

  List<List<CheckerMove>> _applyForcedHighDie(
      BackgammonState state,
      List<List<CheckerMove>> candidates,
      List<int> dice) {
    if (dice.length != 2 || dice[0] == dice[1]) return candidates;
    if (candidates.isEmpty || candidates.first.length != 1) return candidates;

    final higher = dice.reduce(max);
    final withHigher = candidates
        .where((s) => _dieForMove(state.activeColor, s.first) == higher)
        .toList();
    return withHigher.isNotEmpty ? withHigher : candidates;
  }

  // ---------------------------------------------------------------------------
  // Private: all single-checker moves possible with one die value
  // ---------------------------------------------------------------------------

  List<CheckerMove> _getPossibleCheckerMoves(
      BackgammonState state, int die) {
    final color = state.activeColor;
    final bar =
        color == BackgammonColor.white ? state.whiteBar : state.blackBar;
    final moves = <CheckerMove>[];

    if (bar > 0) {
      // Must enter from bar
      final dest = color == BackgammonColor.white ? (25 - die) : die;
      if (dest >= 1 &&
          dest <= 24 &&
          _isDestinationReachable(state, dest, color)) {
        moves.add(CheckerMove(from: 0, to: dest));
      }
      return moves;
    }

    final allInHome = _allInHomeBoard(state, color);

    for (int pt = 1; pt <= 24; pt++) {
      final p = state.points[pt];
      if (p.isEmpty || p.color != color) continue;

      final dest = _destForDie(color, pt, die);
      if (dest == 25) {
        if (!allInHome) continue;
        if (_isBearOffValid(state, pt, die, color)) {
          moves.add(CheckerMove(from: pt, to: 25));
        }
      } else if (dest >= 1 && dest <= 24) {
        if (_isDestinationReachable(state, dest, color)) {
          moves.add(CheckerMove(from: pt, to: dest));
        }
      }
    }
    return moves;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Destination point when moving from [from] using [die]. Returns 25 = bear off.
  int _destForDie(BackgammonColor color, int from, int die) {
    if (color == BackgammonColor.white) {
      final dest = from - die;
      return dest <= 0 ? 25 : dest;
    } else {
      final dest = from + die;
      return dest >= 25 ? 25 : dest;
    }
  }

  /// Nominal die value consumed by [cm] (ignoring overshoot).
  int _dieForMove(BackgammonColor color, CheckerMove cm) {
    if (cm.from == 0) {
      return color == BackgammonColor.white ? (25 - cm.to) : cm.to;
    } else if (cm.to == 25) {
      return color == BackgammonColor.white ? cm.from : (25 - cm.from);
    } else {
      return color == BackgammonColor.white
          ? (cm.from - cm.to)
          : (cm.to - cm.from);
    }
  }

  /// Whether destination [dest] is reachable (not blocked by ≥2 opponents).
  bool _isDestinationReachable(
      BackgammonState state, int dest, BackgammonColor color) {
    if (dest < 1 || dest > 24) return false;
    final pt = state.points[dest];
    if (pt.isEmpty) return true;
    if (pt.color == color) return true;
    return pt.count == 1; // opponent blot can be hit
  }

  /// Whether all of [color]'s checkers are in their home board.
  bool _allInHomeBoard(BackgammonState state, BackgammonColor color) {
    if (color == BackgammonColor.white) {
      if (state.whiteBar > 0) return false;
      for (int pt = 7; pt <= 24; pt++) {
        final p = state.points[pt];
        if (!p.isEmpty && p.color == BackgammonColor.white) return false;
      }
      return true;
    } else {
      if (state.blackBar > 0) return false;
      for (int pt = 1; pt <= 18; pt++) {
        final p = state.points[pt];
        if (!p.isEmpty && p.color == BackgammonColor.black) return false;
      }
      return true;
    }
  }

  /// Whether bearing off from [from] with [die] is valid (handles overshoot).
  bool _isBearOffValid(
      BackgammonState state, int from, int die, BackgammonColor color) {
    if (color == BackgammonColor.white) {
      final dist = from;
      if (die == dist) return true;
      if (die > dist) {
        // Overshoot valid only if no white checker on higher home points
        for (int pt = from + 1; pt <= 6; pt++) {
          final p = state.points[pt];
          if (!p.isEmpty && p.color == BackgammonColor.white) return false;
        }
        return true;
      }
      return false;
    } else {
      final dist = 25 - from;
      if (die == dist) return true;
      if (die > dist) {
        // Overshoot valid only if no black checker on lower home points
        for (int pt = from - 1; pt >= 19; pt--) {
          final p = state.points[pt];
          if (!p.isEmpty && p.color == BackgammonColor.black) return false;
        }
        return true;
      }
      return false;
    }
  }
}
