import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearby_ble/nearby_ble.dart';
import 'package:game_framework/game_framework.dart';

// =============================================================================
// Fake BLE service — overrides only the streams and send methods used by
// GameSession, so no platform channel is touched during tests.
// =============================================================================

class _FakeBleService extends BleService {
  final _msgCtrl = StreamController<BleMessage>.broadcast();
  final _connCtrl = StreamController<BleConnectionState>.broadcast();

  @override
  Stream<BleMessage> get onMessage => _msgCtrl.stream;

  @override
  Stream<BleConnectionState> get onConnectionState => _connCtrl.stream;

  @override
  Future<void> send(BleMessage message) async {}

  @override
  Future<void> sendMove(Map<String, dynamic> movePayload) async {}

  @override
  Future<void> sendTyped(
    BleMessageType type, [
    Map<String, dynamic> payload = const {},
  ]) async {}

  void injectMessage(BleMessage msg) => _msgCtrl.add(msg);
  void injectConnectionState(BleConnectionState s) => _connCtrl.add(s);

  Future<void> close() async {
    await _msgCtrl.close();
    await _connCtrl.close();
  }
}

// =============================================================================
// Minimal game engine for testing — moves are positive ints, alternates turns.
// =============================================================================

class _TestState extends GameState {
  final int _activePlayer;
  final int _moveCount;
  final bool _over;
  final int? _winner;

  _TestState({
    int activePlayer = 0,
    int moveCount = 0,
    bool over = false,
    int? winner,
  })  : _activePlayer = activePlayer,
        _moveCount = moveCount,
        _over = over,
        _winner = winner;

  @override
  int get activePlayerIndex => _activePlayer;

  @override
  int get moveCount => _moveCount;

  @override
  bool get isGameOver => _over;

  @override
  int? get winnerIndex => _winner;

  @override
  Map<String, dynamic> toMap() => {
        'p': _activePlayer,
        'n': _moveCount,
        'over': _over,
        'w': _winner,
      };
}

class _TestEngine extends GameEngine<_TestState, int> {
  @override
  String get gameType => 'test';

  @override
  String get gameName => 'Test';

  @override
  _TestState get initialState => _TestState();

  @override
  _TestState applyMove(_TestState state, int move) => _TestState(
        activePlayer: 1 - state._activePlayer,
        moveCount: state._moveCount + 1,
      );

  @override
  bool isValidMove(_TestState state, int move) =>
      move > 0 && !state.isGameOver;

  @override
  List<int> getValidMoves(_TestState state) => [1, 2, 3];

  @override
  bool isGameOver(_TestState state) => state.isGameOver;

  @override
  GameResult? getResult(_TestState state) {
    if (!state.isGameOver) return null;
    if (state._winner == 0) return GameResult.player0Wins;
    if (state._winner == 1) return GameResult.player1Wins;
    return GameResult.draw;
  }

  @override
  Map<String, dynamic> serializeMove(int move) => {'v': move};

  @override
  int deserializeMove(Map<String, dynamic> map) => map['v'] as int;

  @override
  Map<String, dynamic> serializeState(_TestState state) => state.toMap();

  @override
  _TestState deserializeState(Map<String, dynamic> map) => _TestState(
        activePlayer: map['p'] as int,
        moveCount: map['n'] as int,
        over: map['over'] as bool,
        winner: map['w'] as int?,
      );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // Enum contracts — these tests act as a compile-time + value guard.
  // If anyone renames or removes a variant, the test fails immediately.
  // ---------------------------------------------------------------------------

  group('PlayerSide enum contract', () {
    test('player0.index == 0', () {
      expect(PlayerSide.player0.index, 0);
    });

    test('player1.index == 1', () {
      expect(PlayerSide.player1.index, 1);
    });

    test('has exactly 2 values', () {
      expect(PlayerSide.values.length, 2);
    });
  });

  group('GameResult enum contract', () {
    test('contains all 4 expected values', () {
      expect(
        GameResult.values,
        containsAll([
          GameResult.player0Wins,
          GameResult.player1Wins,
          GameResult.draw,
          GameResult.abandoned,
        ]),
      );
    });

    test('has exactly 4 values', () {
      expect(GameResult.values.length, 4);
    });
  });

  group('GameSessionStatus enum contract', () {
    test('contains waiting, playing, gameOver, disconnected', () {
      expect(
        GameSessionStatus.values,
        containsAll([
          GameSessionStatus.waiting,
          GameSessionStatus.playing,
          GameSessionStatus.gameOver,
          GameSessionStatus.disconnected,
        ]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // GamePlayer
  // ---------------------------------------------------------------------------

  group('GamePlayer', () {
    test('player0 index is 0', () {
      const p = GamePlayer(
        name: 'Alice',
        side: PlayerSide.player0,
        isLocal: true,
      );
      expect(p.index, 0);
    });

    test('player1 index is 1', () {
      const p = GamePlayer(
        name: 'Bob',
        side: PlayerSide.player1,
        isLocal: false,
      );
      expect(p.index, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // GameSession — 2-player contract
  // ---------------------------------------------------------------------------

  group('GameSession two-player contract', () {
    late _FakeBleService ble;
    late GameSession<_TestState, int> session;

    setUp(() {
      ble = _FakeBleService();
      session = GameSession(engine: _TestEngine(), bleService: ble);
    });

    tearDown(() async {
      session.dispose();
      await ble.close();
    });

    test('starts in waiting status', () {
      expect(session.status, GameSessionStatus.waiting);
    });

    test('startGame sets localPlayer name and side', () {
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );
      expect(session.localPlayer?.name, 'Alice');
      expect(session.localPlayer?.side, PlayerSide.player0);
    });

    test('startGame assigns opposite side to remotePlayer', () {
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );
      expect(session.remotePlayer?.name, 'Bob');
      expect(session.remotePlayer?.side, PlayerSide.player1);
    });

    test('startGame assigns opposite side when local is player1', () {
      session.startGame(
        localSide: PlayerSide.player1,
        localName: 'Bob',
        remoteName: 'Alice',
      );
      expect(session.localPlayer?.side, PlayerSide.player1);
      expect(session.remotePlayer?.side, PlayerSide.player0);
    });

    test('startGame transitions status to playing', () {
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );
      expect(session.status, GameSessionStatus.playing);
    });

    test('isMyTurn true when activePlayerIndex matches local player', () {
      // player0 moves first; local is player0
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );
      expect(session.isMyTurn, isTrue);
    });

    test('isMyTurn false when activePlayerIndex does not match local player',
        () {
      // player0 moves first; local is player1
      session.startGame(
        localSide: PlayerSide.player1,
        localName: 'Bob',
        remoteName: 'Alice',
      );
      expect(session.isMyTurn, isFalse);
    });

    test('makeMove applies move and emits on stateStream', () async {
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );

      final states = <_TestState>[];
      session.stateStream.listen(states.add);

      final result = session.makeMove(1);
      await Future.microtask(() {});

      expect(result, isTrue);
      expect(states, hasLength(1));
      expect(states.first.moveCount, 1);
    });

    test('makeMove flips activePlayerIndex', () async {
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );

      final states = <_TestState>[];
      session.stateStream.listen(states.add);

      session.makeMove(1);
      await Future.microtask(() {});

      expect(states.first.activePlayerIndex, 1);
    });

    test('makeMove returns false for invalid move (leaves state unchanged)', () {
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );

      final result = session.makeMove(-1); // invalid per _TestEngine
      expect(result, isFalse);
      expect(session.state.moveCount, 0);
    });

    test('makeMove returns false when not your turn', () {
      // player0 goes first; local is player1
      session.startGame(
        localSide: PlayerSide.player1,
        localName: 'Bob',
        remoteName: 'Alice',
      );

      final result = session.makeMove(1);
      expect(result, isFalse);
    });

    test('makeMove returns false when session is not playing', () {
      // startGame never called — status is waiting
      final result = session.makeMove(1);
      expect(result, isFalse);
    });

    test('remote move via onMessage updates state', () async {
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );
      session.makeMove(1); // flip turn to player1 (remote)
      await Future.microtask(() {});

      final states = <_TestState>[];
      final sub = session.stateStream.listen(states.add);
      await Future.microtask(() {}); // let subscription register

      ble.injectMessage(BleMessage.create(
        type: BleMessageType.move,
        seq: 1,
        payload: {'v': 2},
      ));
      await Future.microtask(() {});
      await Future.microtask(() {}); // extra tick for stream propagation

      expect(states, hasLength(1));
      expect(states.first.moveCount, 2);
      expect(states.first.activePlayerIndex, 0); // flipped back
      await sub.cancel();
    });

    test('disconnection updates status to disconnected', () async {
      session.startGame(
        localSide: PlayerSide.player0,
        localName: 'Alice',
        remoteName: 'Bob',
      );
      await Future.microtask(() {});

      final statuses = <GameSessionStatus>[];
      final sub = session.statusStream.listen(statuses.add);
      await Future.microtask(() {}); // let subscription register

      ble.injectConnectionState(BleConnectionState.disconnected);
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(statuses, contains(GameSessionStatus.disconnected));
      await sub.cancel();
    });
  });
}
