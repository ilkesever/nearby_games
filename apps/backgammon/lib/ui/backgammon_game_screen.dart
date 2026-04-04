import 'package:flutter/material.dart';
import 'package:game_framework/game_framework.dart';
import 'package:nearby_ble/nearby_ble.dart';

import '../game/backgammon_engine.dart';
import '../game/backgammon_move.dart';
import '../game/backgammon_state.dart';
import '../services/rating_service.dart';
import '../src/l10n/app_localizations.dart';
import 'backgammon_board_widget.dart';

class BackgammonGameScreen extends StatefulWidget {
  final BleService bleService;
  final BleConnection connection;
  final bool isHost;
  final String playerName;

  const BackgammonGameScreen({
    super.key,
    required this.bleService,
    required this.connection,
    required this.isHost,
    required this.playerName,
  });

  @override
  State<BackgammonGameScreen> createState() => _BackgammonGameScreenState();
}

class _BackgammonGameScreenState extends State<BackgammonGameScreen> {
  late final BackgammonEngine _engine;
  late final GameSession<BackgammonState, BackgammonMove> _session;
  BackgammonMove? _lastMove;

  @override
  void initState() {
    super.initState();
    _engine = BackgammonEngine();
    _session = GameSession<BackgammonState, BackgammonMove>(
      engine: _engine,
      bleService: widget.bleService,
    );

    _session.startGame(
      localSide: widget.isHost ? PlayerSide.player0 : PlayerSide.player1,
      localName: widget.playerName,
      remoteName: widget.connection.remoteDevice.name,
    );

    _session.moveStream.listen((move) {
      setState(() {
        _lastMove = move;
      });
    });

    _session.statusStream.listen((status) {
      if (status != GameSessionStatus.gameOver) return;
      RatingService().recordGameCompleted();
    });

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

  void _onMove(BackgammonMove move) {
    _session.makeMove(move);
  }

  void _showDrawOfferDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.drawOfferedTitle),
        content: Text(l10n.drawOfferedContent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.declineDraw();
            },
            child: Text(l10n.drawDecline),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.acceptDraw();
            },
            child: Text(l10n.drawAccept),
          ),
        ],
      ),
    );
  }

  void _showUndoRequestDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.undoRequestedTitle),
        content: Text(l10n.undoRequestedContent),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.declineUndo();
            },
            child: Text(l10n.drawDecline),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _session.acceptUndo();
            },
            child: Text(l10n.undoAllow),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameScaffold<BackgammonState, BackgammonMove>(
      session: _session,
      gameName: l10n.appTitle,
      accentColor: Colors.brown[700],
      onExit: () => Navigator.of(context).pop(),
      gameBoard: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          final isBlack =
              _session.localPlayer?.side == PlayerSide.player1;
          return BackgammonBoardWidget(
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