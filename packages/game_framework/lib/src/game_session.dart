import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nearby_ble/nearby_ble.dart';

import 'game_engine.dart';
import 'game_player.dart';
import 'game_state.dart';

/// Manages a multiplayer game session over BLE.
///
/// [GameSession] bridges the [GameEngine] (game logic) with [BleService]
/// (communication), handling:
/// - Turn management and validation
/// - State synchronization between devices
/// - Move sending/receiving
/// - Game lifecycle (start, resign, draw, rematch)
///
/// Usage:
/// ```dart
/// final session = GameSession(
///   engine: ChessEngine(),
///   bleService: bleService,
/// );
///
/// // Listen to state changes
/// session.stateStream.listen((state) {
///   // Update UI
/// });
///
/// // Make a move (validates locally, sends via BLE)
/// session.makeMove(ChessMove(from: 'e2', to: 'e4'));
/// ```
class GameSession<TState extends GameState, TMove> extends ChangeNotifier {
  final GameEngine<TState, TMove> engine;
  final BleService bleService;

  // --- State ---
  TState _state;
  GameSessionStatus _status = GameSessionStatus.waiting;
  GamePlayer? _localPlayer;
  GamePlayer? _remotePlayer;
  final List<TMove> _moveHistory = [];
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;

  // --- Streams ---
  final _stateController = StreamController<TState>.broadcast();
  final _statusController = StreamController<GameSessionStatus>.broadcast();
  final _moveController = StreamController<TMove>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  /// Create a new game session.
  GameSession({
    required this.engine,
    required this.bleService,
  }) : _state = engine.initialState;

  // --- Getters ---

  /// Current game state.
  TState get state => _state;

  /// Current session status.
  GameSessionStatus get status => _status;

  /// The local player.
  GamePlayer? get localPlayer => _localPlayer;

  /// The remote player.
  GamePlayer? get remotePlayer => _remotePlayer;

  /// Move history.
  List<TMove> get moveHistory => List.unmodifiable(_moveHistory);

  /// Whether it's the local player's turn.
  bool get isMyTurn {
    if (_localPlayer == null) return false;
    return _state.activePlayerIndex == _localPlayer!.index;
  }

  /// Whether the game is actively being played.
  bool get isPlaying => _status == GameSessionStatus.playing;

  // --- Streams ---

  /// Stream of game state updates.
  Stream<TState> get stateStream => _stateController.stream;

  /// Stream of session status changes.
  Stream<GameSessionStatus> get statusStream => _statusController.stream;

  /// Stream of moves (both local and remote).
  Stream<TMove> get moveStream => _moveController.stream;

  /// Stream of error messages.
  Stream<String> get errorStream => _errorController.stream;

  // ==========================================================================
  // SESSION LIFECYCLE
  // ==========================================================================

  /// Start the session after a BLE connection is established.
  ///
  /// [localSide] — Which side the local player is on.
  /// [localName] — Display name of the local player.
  /// [remoteName] — Display name of the remote player.
  void startGame({
    required PlayerSide localSide,
    required String localName,
    required String remoteName,
  }) {
    _localPlayer = GamePlayer(
      name: localName,
      side: localSide,
      isLocal: true,
    );
    _remotePlayer = GamePlayer(
      name: remoteName,
      side: localSide == PlayerSide.player0
          ? PlayerSide.player1
          : PlayerSide.player0,
      isLocal: false,
    );

    _state = engine.initialState;
    _moveHistory.clear();
    _updateStatus(GameSessionStatus.playing);
    _stateController.add(_state);

    // Listen for incoming messages
    _messageSubscription?.cancel();
    _messageSubscription = bleService.onMessage.listen(_handleMessage);

    _connectionSubscription?.cancel();
    _connectionSubscription = bleService.onConnectionState.listen((connState) {
      if (connState == BleConnectionState.disconnected) {
        _updateStatus(GameSessionStatus.disconnected);
      }
    });

    // Send game start message with initial state
    bleService.sendTyped(BleMessageType.gameStart, {
      'state': engine.serializeState(_state),
      'localPlayerName': localName,
    });

    notifyListeners();
  }

  // ==========================================================================
  // MOVES
  // ==========================================================================

  /// Make a move as the local player.
  ///
  /// The move is validated locally first. If valid, it's applied to the
  /// state and sent to the remote player via BLE.
  ///
  /// Returns true if the move was valid and applied.
  bool makeMove(TMove move) {
    if (!isPlaying) {
      _errorController.add('Game is not in progress');
      return false;
    }

    if (!isMyTurn) {
      _errorController.add('Not your turn');
      return false;
    }

    if (!engine.isValidMove(_state, move)) {
      _errorController.add('Invalid move');
      return false;
    }

    // Apply the move locally
    _applyMove(move);

    // Send the move to the remote player
    bleService.sendMove(engine.serializeMove(move));

    // Check for game over
    if (engine.isGameOver(_state)) {
      final result = engine.getResult(_state);
      _updateStatus(GameSessionStatus.gameOver);
      bleService.sendTyped(BleMessageType.gameOver, {
        'result': result?.name ?? 'unknown',
        'state': engine.serializeState(_state),
      });
    }

    return true;
  }

  // ==========================================================================
  // GAME ACTIONS
  // ==========================================================================

  /// Resign the game.
  void resign() {
    if (!isPlaying) return;
    _updateStatus(GameSessionStatus.gameOver);
    bleService.sendTyped(BleMessageType.resign);
    notifyListeners();
  }

  /// Offer a draw.
  void offerDraw() {
    if (!isPlaying) return;
    bleService.sendTyped(BleMessageType.drawOffer);
  }

  /// Accept a draw offer.
  void acceptDraw() {
    _updateStatus(GameSessionStatus.gameOver);
    bleService.sendTyped(BleMessageType.drawAccept);
    notifyListeners();
  }

  /// Decline a draw offer.
  void declineDraw() {
    bleService.sendTyped(BleMessageType.drawDecline);
  }

  /// Request to undo the last move.
  void requestUndo() {
    if (!isPlaying || _moveHistory.isEmpty) return;
    bleService.sendTyped(BleMessageType.undoRequest);
  }

  /// Accept an undo request.
  void acceptUndo() {
    // TODO: Implement undo logic (revert state)
    bleService.sendTyped(BleMessageType.undoAccept);
  }

  /// Decline an undo request.
  void declineUndo() {
    bleService.sendTyped(BleMessageType.undoDecline);
  }

  // ==========================================================================
  // CLEANUP
  // ==========================================================================

  /// Dispose of the session and clean up resources.
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _stateController.close();
    _statusController.close();
    _moveController.close();
    _errorController.close();
    super.dispose();
  }

  // ==========================================================================
  // PRIVATE METHODS
  // ==========================================================================

  void _applyMove(TMove move) {
    _state = engine.applyMove(_state, move);
    _moveHistory.add(move);
    _stateController.add(_state);
    _moveController.add(move);
    notifyListeners();
  }

  void _updateStatus(GameSessionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
    notifyListeners();
  }

  void _handleMessage(BleMessage message) {
    switch (message.type) {
      case BleMessageType.move:
        _handleRemoteMove(message.payload);

      case BleMessageType.stateSync:
        _handleStateSync(message.payload);

      case BleMessageType.gameStart:
        // Remote player confirmed game start
        if (_status != GameSessionStatus.playing) {
          _updateStatus(GameSessionStatus.playing);
        }

      case BleMessageType.gameOver:
        _updateStatus(GameSessionStatus.gameOver);

      case BleMessageType.resign:
        _updateStatus(GameSessionStatus.gameOver);

      case BleMessageType.drawOffer:
        // Notify UI that a draw was offered
        _errorController.add('DRAW_OFFERED');

      case BleMessageType.drawAccept:
        _updateStatus(GameSessionStatus.gameOver);

      case BleMessageType.drawDecline:
        _errorController.add('DRAW_DECLINED');

      case BleMessageType.undoRequest:
        _errorController.add('UNDO_REQUESTED');

      case BleMessageType.undoAccept:
        // TODO: Implement undo
        break;

      case BleMessageType.undoDecline:
        _errorController.add('UNDO_DECLINED');

      case BleMessageType.ping:
        bleService.sendTyped(BleMessageType.pong);

      case BleMessageType.pong:
        // Received ping response
        break;

      case BleMessageType.chat:
        // TODO: Handle chat messages
        break;

      case BleMessageType.custom:
        // Game-specific custom messages
        break;
    }
  }

  void _handleRemoteMove(Map<String, dynamic> payload) {
    try {
      final move = engine.deserializeMove(payload);

      // Validate the remote move
      if (!engine.isValidMove(_state, move)) {
        _errorController.add('Received invalid move from opponent');
        // Request state sync
        bleService.sendTyped(BleMessageType.stateSync, {
          'state': engine.serializeState(_state),
        });
        return;
      }

      // Apply the remote move
      _applyMove(move);

      // Check for game over
      if (engine.isGameOver(_state)) {
        _updateStatus(GameSessionStatus.gameOver);
      }
    } catch (e) {
      _errorController.add('Failed to process remote move: $e');
    }
  }

  void _handleStateSync(Map<String, dynamic> payload) {
    try {
      final stateMap = payload['state'] as Map<String, dynamic>?;
      if (stateMap != null) {
        _state = engine.deserializeState(stateMap);
        _stateController.add(_state);
        notifyListeners();
      }
    } catch (e) {
      _errorController.add('Failed to sync state: $e');
    }
  }
}

/// Status of a game session.
enum GameSessionStatus {
  /// Waiting for an opponent to connect.
  waiting,

  /// Game is actively being played.
  playing,

  /// Game is over (win, loss, draw, or resignation).
  gameOver,

  /// Connection was lost.
  disconnected,
}
