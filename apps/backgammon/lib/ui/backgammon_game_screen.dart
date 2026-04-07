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
  OpponentPreview? _opponentPreview;

  // Match-level score (persists for the duration of this BLE session)
  int _whiteScore = 0;
  int _blackScore = 0;
  BackgammonColor? _lastWinner;

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
        _opponentPreview = null;
      });
    });

    _session.customStream.listen((payload) {
      if (payload['action'] != 'preview') return;
      final dice = List<int>.from(payload['dice'] as List? ?? []);
      final moves = (payload['moves'] as List? ?? [])
          .map((m) =>
              CheckerMove.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
      setState(() {
        _opponentPreview = dice.isEmpty
            ? null
            : OpponentPreview(dice: dice, moves: moves);
      });
    });

    _session.statusStream.listen((status) {
      if (status != GameSessionStatus.gameOver) return;
      RatingService().recordGameCompleted();
      final state = _session.state;
      final winner = state.winner;
      if (winner != null) {
        final points = _pointsForWin(state.winType);
        setState(() {
          if (winner == BackgammonColor.white) {
            _whiteScore += points;
          } else {
            _blackScore += points;
          }
          _lastWinner = winner;
        });
      }
    });

    _session.errorStream.listen((event) {
      if (!mounted) return;
      switch (event) {
        case 'DRAW_OFFERED':
          _showDrawOfferDialog();
        default:
          if (!event.startsWith('DRAW_')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(event)),
            );
          }
      }
    });
  }

  @override
  void dispose() {
    widget.bleService.reset(); // fire-and-forget: stop native BLE before leaving
    _session.dispose();
    super.dispose();
  }

  int _pointsForWin(BackgammonWinType? type) {
    switch (type) {
      case BackgammonWinType.gammon:
        return 2;
      case BackgammonWinType.backgammon:
        return 3;
      default:
        return 1;
    }
  }

  void _onMove(BackgammonMove move) {
    _session.makeMove(move);
  }

  void _startNextGame() {
    if (_lastWinner == null) return;
    _session.rematch(
      initialState: BackgammonState.initial(startingColor: _lastWinner!),
    );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameScaffold<BackgammonState, BackgammonMove>(
      session: _session,
      gameName: l10n.appTitle,
      accentColor: Colors.brown[700],
      onExit: () => Navigator.of(context).pop(),
      scoreBannerWidget: _buildScoreBar(l10n),
      gameBoard: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          final isBlack =
              _session.localPlayer?.side == PlayerSide.player1;
          return Column(
            children: [
              Expanded(
                child: BackgammonBoardWidget(
                  state: _session.state,
                  engine: _engine,
                  interactive: _session.isMyTurn && _session.isPlaying,
                  flipped: isBlack,
                  lastMove: _lastMove,
                  onMove: _onMove,
                  opponentPreview: _opponentPreview,
                  onPreviewChanged: (dice, moves) {
                    _session.sendCustom({
                      'action': 'preview',
                      'dice': dice,
                      'moves': moves.map((m) => m.toMap()).toList(),
                    });
                  },
                ),
              ),
              if (_session.status == GameSessionStatus.gameOver)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _startNextGame,
                    icon: const Icon(Icons.replay),
                    label: Text(l10n.localGamePlayAgain),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScoreBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.brown[900],
      child: Row(
        children: [
          _scoreChip(Colors.white, l10n.scoreWhite, _whiteScore),
          const Spacer(),
          _scoreChip(Colors.grey[850]!, l10n.scoreBlack, _blackScore,
              reversed: true),
        ],
      ),
    );
  }

  Widget _scoreChip(Color chipColor, String label, int score,
      {bool reversed = false}) {
    final items = <Widget>[
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: chipColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.brown[400]!, width: 1.5),
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(width: 4),
      Text('$score',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold)),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reversed ? items.reversed.toList() : items,
    );
  }
}
