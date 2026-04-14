import 'package:flutter/material.dart';

import '../game/checkers_engine.dart';
import '../game/checkers_move.dart';
import '../game/checkers_state.dart';
import '../services/rating_service.dart';
import '../src/l10n/app_localizations.dart';
import 'checkers_board_widget.dart';

/// Local "Pass & Play" mode — two players on one device.
class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({super.key});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  final CheckersEngine _engine = CheckersEngine();
  late CheckersState _state;

  int _whiteScore = 0;
  int _blackScore = 0;

  @override
  void initState() {
    super.initState();
    _state = _engine.initialState;
  }

  void _onMove(CheckersMove move) {
    if (!_engine.isValidMove(_state, move)) return;
    setState(() {
      _state = _engine.applyMove(_state, move);
    });
    if (_state.isGameOver) {
      RatingService().recordGameCompleted();
      final winner = _state.winnerIndex;
      if (winner != null) {
        setState(() {
          if (winner == 0) {
            _whiteScore++;
          } else {
            _blackScore++;
          }
        });
      }
    }
  }

  void _startNextGame() {
    setState(() {
      _state = _engine.initialState;
    });
  }

  void _resetMatch() {
    setState(() {
      _whiteScore = 0;
      _blackScore = 0;
      _state = _engine.initialState;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final turnText = _state.isGameOver
        ? (_state.winnerIndex == 0
            ? l10n.localGameWhiteWins
            : l10n.localGameBlackWins)
        : (_state.activePlayerIndex == 0
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
            _buildCapturedBar(_state),

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

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CheckersBoardWidget(
                    state: _state,
                    engine: _engine,
                    interactive: !_state.isGameOver,
                    onMove: _onMove,
                  ),
                ),
              ),
            ),

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
