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

  // Match-level score
  int _whiteScore = 0;
  int _blackScore = 0;
  BackgammonColor? _lastWinner;

  @override
  void initState() {
    super.initState();
    _state = _engine.initialState; // starts in openingRoll phase
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
      final winner = _state.winner!;
      final points = _pointsForWin(_state.winType);
      setState(() {
        if (winner == BackgammonColor.white) {
          _whiteScore += points;
        } else {
          _blackScore += points;
        }
        _lastWinner = winner;
      });
    }
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

  void _startNextGame() {
    setState(() {
      // Winner skips opening roll and starts directly in rolling phase
      _state = BackgammonState.initial(startingColor: _lastWinner!);
      _lastMove = null;
      _moveHistory.clear();
    });
  }

  void _resetMatch() {
    setState(() {
      _whiteScore = 0;
      _blackScore = 0;
      _lastWinner = null;
      _state = _engine.initialState; // back to opening roll phase
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
            onPressed: _resetMatch,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildScoreBar(l10n),

            // Hide turn text during opening roll (board widget shows its own UI)
            if (_state.phase != GamePhase.openingRoll)
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

            // Board (handles opening roll UI internally)
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

            // Move history (hidden during opening roll)
            if (_state.phase != GamePhase.openingRoll)
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
        ),
      ),
    );
  }

  Widget _buildScoreBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.brown[900],
      child: Row(
        children: [
          _buildScoreChip(
            label: l10n.scoreWhite,
            score: _whiteScore,
            chipColor: Colors.white,
          ),
          const Spacer(),
          _buildScoreChip(
            label: l10n.scoreBlack,
            score: _blackScore,
            chipColor: Colors.grey[850]!,
            reversed: true,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChip({
    required String label,
    required int score,
    required Color chipColor,
    bool reversed = false,
  }) {
    final items = <Widget>[
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: chipColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.brown[400]!, width: 1.5),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        '$score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reversed ? items.reversed.toList() : items,
    );
  }
}
