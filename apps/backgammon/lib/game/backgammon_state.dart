import 'package:game_framework/game_framework.dart';

import 'backgammon_move.dart';

class PointState {
  final int count;
  final BackgammonColor? color;

  const PointState({this.count = 0, this.color});

  const PointState.empty()
      : count = 0,
        color = null;

  bool get isEmpty => count == 0;

  Map<String, dynamic> toMap() => {
        'count': count,
        'color': color?.index,
      };

  factory PointState.fromMap(Map<String, dynamic> map) => PointState(
        count: map['count'] as int,
        color: map['color'] != null
            ? BackgammonColor.values[map['color'] as int]
            : null,
      );
}

/// [openingRoll] — both players roll one die to determine who goes first.
/// [rolling]    — active player rolls their two game dice.
/// [moving]     — active player moves their checkers.
/// [gameOver]   — game has ended.
enum GamePhase { openingRoll, rolling, moving, gameOver }

/// Win classification. Only meaningful when [BackgammonState.winner] is non-null.
///
/// - [normal]     Loser has borne off at least one checker.
/// - [gammon]     Loser has borne off zero checkers.
/// - [backgammon] Loser has a checker on the bar or in the winner's home board.
enum BackgammonWinType { normal, gammon, backgammon }

class BackgammonState extends GameState {
  // index 0 unused; indices 1-24 are the board points
  final List<PointState> points;
  final int whiteBar;
  final int blackBar;
  final int whiteBorneOff;
  final int blackBorneOff;
  final BackgammonColor activeColor;
  final GamePhase phase;
  final List<int> remainingDice;
  final int _moveCount;

  /// Opening die for white, set after white submits their opening roll move.
  /// Cleared when the opening roll resolves (winner found or tie re-roll).
  final int? whiteOpeningDie;

  /// Opening die for black, set after black submits their opening roll move.
  final int? blackOpeningDie;

  // Sentinel used by copyWith to distinguish "not provided" from explicit null.
  static const Object _keep = Object();

  BackgammonState({
    required this.points,
    required this.whiteBar,
    required this.blackBar,
    required this.whiteBorneOff,
    required this.blackBorneOff,
    required this.activeColor,
    required this.phase,
    required this.remainingDice,
    required int moveCount,
    this.whiteOpeningDie,
    this.blackOpeningDie,
  }) : _moveCount = moveCount;

  /// Creates the standard starting position.
  ///
  /// - [startingColor] omitted (new match / BLE): starts in [GamePhase.openingRoll]
  ///   with white rolling first. Both devices produce the **same** deterministic
  ///   state — no random numbers here.
  /// - [startingColor] provided (winner starts next game): skips the opening roll
  ///   and starts directly in [GamePhase.rolling].
  factory BackgammonState.initial({BackgammonColor? startingColor}) {
    final pts = List<PointState>.filled(25, const PointState.empty());
    pts[24] = const PointState(count: 2, color: BackgammonColor.white);
    pts[13] = const PointState(count: 5, color: BackgammonColor.white);
    pts[8] = const PointState(count: 3, color: BackgammonColor.white);
    pts[6] = const PointState(count: 5, color: BackgammonColor.white);
    pts[1] = const PointState(count: 2, color: BackgammonColor.black);
    pts[12] = const PointState(count: 5, color: BackgammonColor.black);
    pts[17] = const PointState(count: 3, color: BackgammonColor.black);
    pts[19] = const PointState(count: 5, color: BackgammonColor.black);
    return BackgammonState(
      points: List.unmodifiable(pts),
      whiteBar: 0,
      blackBar: 0,
      whiteBorneOff: 0,
      blackBorneOff: 0,
      // White always rolls first in the opening; or use the provided winner.
      activeColor: startingColor ?? BackgammonColor.white,
      phase: startingColor != null ? GamePhase.rolling : GamePhase.openingRoll,
      remainingDice: const [],
      moveCount: 0,
    );
  }

  BackgammonColor? get winner {
    if (whiteBorneOff == 15) return BackgammonColor.white;
    if (blackBorneOff == 15) return BackgammonColor.black;
    return null;
  }

  /// Win type. Returns null if the game is not over.
  BackgammonWinType? get winType {
    final w = winner;
    if (w == null) return null;
    final loserBorneOff =
        w == BackgammonColor.white ? blackBorneOff : whiteBorneOff;
    final loserBar = w == BackgammonColor.white ? blackBar : whiteBar;
    final homeStart = w == BackgammonColor.white ? 1 : 19;
    final homeEnd = w == BackgammonColor.white ? 6 : 24;
    final loserInWinnerHome = points
        .sublist(homeStart, homeEnd + 1)
        .any((p) => p.color == w.opposite && p.count > 0);
    if (loserBar > 0 || loserInWinnerHome) return BackgammonWinType.backgammon;
    if (loserBorneOff == 0) return BackgammonWinType.gammon;
    return BackgammonWinType.normal;
  }

  @override
  int get activePlayerIndex =>
      activeColor == BackgammonColor.white ? 0 : 1;

  @override
  bool get isGameOver => winner != null;

  @override
  int? get winnerIndex {
    final w = winner;
    if (w == null) return null;
    return w == BackgammonColor.white ? 0 : 1;
  }

  @override
  int get moveCount => _moveCount;

  @override
  Map<String, dynamic> toMap() => {
        'points': points.map((p) => p.toMap()).toList(),
        'whiteBar': whiteBar,
        'blackBar': blackBar,
        'whiteBorneOff': whiteBorneOff,
        'blackBorneOff': blackBorneOff,
        'activeColor': activeColor.index,
        'phase': phase.index,
        'remainingDice': remainingDice,
        'moveCount': _moveCount,
        'whiteOpeningDie': whiteOpeningDie,
        'blackOpeningDie': blackOpeningDie,
      };

  factory BackgammonState.fromMap(Map<String, dynamic> map) => BackgammonState(
        points: (map['points'] as List)
            .map((p) =>
                PointState.fromMap(Map<String, dynamic>.from(p as Map)))
            .toList(),
        whiteBar: map['whiteBar'] as int,
        blackBar: map['blackBar'] as int,
        whiteBorneOff: map['whiteBorneOff'] as int,
        blackBorneOff: map['blackBorneOff'] as int,
        activeColor: BackgammonColor.values[map['activeColor'] as int],
        phase: GamePhase.values[map['phase'] as int],
        remainingDice: List<int>.from(map['remainingDice'] as List),
        moveCount: map['moveCount'] as int,
        whiteOpeningDie: map['whiteOpeningDie'] as int?,
        blackOpeningDie: map['blackOpeningDie'] as int?,
      );

  /// [whiteOpeningDie] and [blackOpeningDie] use a sentinel default so that
  /// passing `null` explicitly sets the field to null, while omitting the
  /// parameter keeps the existing value.
  BackgammonState copyWith({
    List<PointState>? points,
    int? whiteBar,
    int? blackBar,
    int? whiteBorneOff,
    int? blackBorneOff,
    BackgammonColor? activeColor,
    GamePhase? phase,
    List<int>? remainingDice,
    int? moveCount,
    Object? whiteOpeningDie = _keep,
    Object? blackOpeningDie = _keep,
  }) =>
      BackgammonState(
        points: points ?? this.points,
        whiteBar: whiteBar ?? this.whiteBar,
        blackBar: blackBar ?? this.blackBar,
        whiteBorneOff: whiteBorneOff ?? this.whiteBorneOff,
        blackBorneOff: blackBorneOff ?? this.blackBorneOff,
        activeColor: activeColor ?? this.activeColor,
        phase: phase ?? this.phase,
        remainingDice: remainingDice ?? this.remainingDice,
        moveCount: moveCount ?? _moveCount,
        whiteOpeningDie: identical(whiteOpeningDie, _keep)
            ? this.whiteOpeningDie
            : whiteOpeningDie as int?,
        blackOpeningDie: identical(blackOpeningDie, _keep)
            ? this.blackOpeningDie
            : blackOpeningDie as int?,
      );
}
