import 'package:flutter/material.dart';

import '../game/backgammon_engine.dart';
import '../game/backgammon_move.dart';
import '../game/backgammon_state.dart';
import '../services/rating_service.dart';
import '../src/l10n/app_localizations.dart';
import 'backgammon_board_widget.dart';

/// Local "Pass & Play" mode — two players on one device.
class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({super.key});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  final BackgammonEngine _engine = BackgammonEngine();
  late BackgammonState _state;
  BackgammonMove? _lastMove;
  final List<String> _moveHistory = [];

  @override
  void initState() {
    super.initState();
    _state = _engine.initialState;
  }

  void _onMove(BackgammonMove move) {
    if (!_engine.isValidMove(_state, move)) return;
    setState(() {
      _moveHistory.add(move.toString());
      _state = _engine.applyMove(_state, move);
      _lastMove = move;
    });
    if (_state.isGameOver) {
      RatingService().recordGameCompleted();
    }
  }

  void _resetGame() {
    setState(() {
      _state = _engine.initialState;
      _lastMove = null;
      _moveHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final turnText = _state.isGameOver
        ? (_state.winner == BackgammonColor.white
            ? l10n.localGameWhiteWins
            : l10n.localGameBlackWins)
        : (_state.activeColor == BackgammonColor.white
            ? l10n.localGameWhiteTurn
            : l10n.localGameBlackTurn);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.localGameTitle),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.localGameNewGame,
            onPressed: _resetGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: _state.isGameOver
                  ? Colors.deepPurple.withValues(alpha: 0.1)
                  : Colors.brown.withValues(alpha: 0.05),
              child: Text(
                turnText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _state.isGameOver
                      ? Colors.deepPurple
                      : Colors.brown[800],
                ),
              ),
            ),

            // Board
            Expanded(
              child: Center(
                child: BackgammonBoardWidget(
                  state: _state,
                  engine: _engine,
                  interactive: !_state.isGameOver,
                  flipped: false,
                  lastMove: _lastMove,
                  onMove: _onMove,
                ),
              ),
            ),

            // Move history
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.brown[50],
              child: _moveHistory.isEmpty
                  ? Center(
                      child: Text(
                        l10n.localGameRollDice,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _moveHistory.length,
                      itemBuilder: (context, index) {
                        final moveNum = index + 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 12),
                          child: Text(
                            '$moveNum. ${_moveHistory[index]}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.brown[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Game over actions
            if (_state.isGameOver)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _resetGame,
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
        ),
      ),
    );
  }
}