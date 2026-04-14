import 'package:flutter/material.dart';
import 'package:game_framework/game_framework.dart';
import 'package:nearby_ble/nearby_ble.dart';

import '../game/checkers_engine.dart';
import '../game/checkers_move.dart';
import '../game/checkers_state.dart';
import '../services/rating_service.dart';
import '../src/l10n/app_localizations.dart';
import 'checkers_board_widget.dart';

class CheckersGameScreen extends StatefulWidget {
  final BleService bleService;
  final BleConnection connection;
  final bool isHost;
  final String playerName;

  const CheckersGameScreen({
    super.key,
    required this.bleService,
    required this.connection,
    required this.isHost,
    required this.playerName,
  });

  @override
  State<CheckersGameScreen> createState() => _CheckersGameScreenState();
}

class _CheckersGameScreenState extends State<CheckersGameScreen> {
  late final CheckersEngine _engine;
  late final GameSession<CheckersState, CheckersMove> _session;

  // Match-level score (persists for the BLE session)
  int _whiteScore = 0;
  int _blackScore = 0;

  @override
  void initState() {
    super.initState();
    _engine = CheckersEngine();
    _session = GameSession<CheckersState, CheckersMove>(
      engine: _engine,
      bleService: widget.bleService,
    );

    _session.startGame(
      localSide: widget.isHost ? PlayerSide.player0 : PlayerSide.player1,
      localName: widget.playerName,
      remoteName: widget.connection.remoteDevice.name,
    );

    _session.statusStream.listen((status) {
      if (status != GameSessionStatus.gameOver) return;
      RatingService().recordGameCompleted();
      final winner = _session.state.winnerIndex;
      if (winner != null && mounted) {
        setState(() {
          if (winner == 0) {
            _whiteScore++;
          } else {
            _blackScore++;
          }
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
    widget.bleService.reset();
    _session.dispose();
    super.dispose();
  }

  void _onMove(CheckersMove move) => _session.makeMove(move);

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
    return GameScaffold<CheckersState, CheckersMove>(
      session: _session,
      gameName: l10n.appTitle,
      accentColor: Colors.brown[700],
      onExit: () => Navigator.of(context).pop(),
      scoreBannerWidget: _buildScoreBar(l10n),
      gameBoard: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          return Column(
            children: [
              _buildCapturedBar(_session.state),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CheckersBoardWidget(
                    state: _session.state,
                    engine: _engine,
                    interactive:
                        _session.isMyTurn && _session.isPlaying,
                    onMove: _onMove,
                  ),
                ),
              ),
              if (_session.status == GameSessionStatus.gameOver)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => _session.rematch(),
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

  Widget _buildCapturedBar(CheckersState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: Colors.brown[850],
      child: Row(
        children: [
          _buildCapturedChip(state.blackCaptured, Colors.grey[850]!),
          const Spacer(),
          _buildCapturedChip(state.whiteCaptured, Colors.white,
              reversed: true),
        ],
      ),
    );
  }

  Widget _buildCapturedChip(int count, Color color, {bool reversed = false}) {
    final circles = List.generate(
      count,
      (_) => Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.brown[400]!, width: 1),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reversed ? circles.reversed.toList() : circles,
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
