import 'package:flutter/material.dart';
import 'package:game_framework/game_framework.dart';
import 'package:nearby_ble/nearby_ble.dart';

import '../game/chess_engine.dart';
import '../game/chess_move.dart';
import '../game/chess_state.dart';
import 'chess_board_widget.dart';

/// The main chess game screen.
///
/// Wraps [GameScaffold] with the chess-specific board widget.
class ChessGameScreen extends StatefulWidget {
  final BleService bleService;
  final BleConnection connection;
  final bool isHost;
  final String playerName;

  const ChessGameScreen({
    super.key,
    required this.bleService,
    required this.connection,
    required this.isHost,
    required this.playerName,
  });

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  late final ChessEngine _engine;
  late final GameSession<ChessState, ChessMove> _session;
  ChessMove? _lastMove;

  @override
  void initState() {
    super.initState();
    _engine = ChessEngine();
    _session = GameSession<ChessState, ChessMove>(
      engine: _engine,
      bleService: widget.bleService,
    );

    // Start the game: host is white (player0), joiner is black (player1)
    _session.startGame(
      localSide: widget.isHost ? PlayerSide.player0 : PlayerSide.player1,
      localName: widget.playerName,
      remoteName: widget.connection.remoteDevice.name,
    );

    // Track the last move for highlighting
    _session.moveStream.listen((move) {
      setState(() {
        _lastMove = move;
      });
    });

    // Listen for game events
    _session.errorStream.listen((event) {
      if (!mounted) return;
      switch (event) {
        case 'DRAW_OFFERED':
          _showDrawOfferDialog();
        case 'UNDO_REQUESTED':
          _showUndoRequestDialog();
        default:
          if (!event.startsWith('DRAW_') && !event.startsWith('UNDO_')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(event)),
            );
          }
      }
    });
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _onMove(ChessMove move) {
    _session.makeMove(move);
  }

  void _showDrawOfferDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Draw Offered'),
        content: const Text('Your opponent is offering a draw. Accept?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.declineDraw();
            },
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.acceptDraw();
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showUndoRequestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Requested'),
        content:
            const Text('Your opponent wants to undo their last move. Allow?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.declineUndo();
            },
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.acceptUndo();
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold<ChessState, ChessMove>(
      session: _session,
      gameName: 'Chess',
      accentColor: Colors.brown[700],
      onExit: () => Navigator.of(context).pop(),
      gameBoard: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          final isBlack =
              _session.localPlayer?.side == PlayerSide.player1;

          return ChessBoardWidget(
            state: _session.state,
            engine: _engine,
            interactive: _session.isMyTurn && _session.isPlaying,
            flipped: isBlack,
            lastMove: _lastMove,
            onMove: _onMove,
          );
        },
      ),
    );
  }
}
