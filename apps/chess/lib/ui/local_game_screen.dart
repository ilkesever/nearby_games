import 'package:flutter/material.dart';
import '../game/chess_engine.dart';
import '../game/chess_move.dart';
import '../game/chess_state.dart';
import 'chess_board_widget.dart';

/// Local "Pass & Play" mode — two players on one device.
///
/// This allows testing the chess board and engine without BLE.
/// Players take turns tapping the same screen.
class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({super.key});

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  final ChessEngine _engine = ChessEngine();
  late ChessState _state;
  ChessMove? _lastMove;
  final List<String> _moveHistory = [];

  @override
  void initState() {
    super.initState();
    _state = _engine.initialState;
  }

  void _onMove(ChessMove move) {
    setState(() {
      _moveHistory.add('${move.fromAlgebraic}→${move.toAlgebraic}');
      _state = _engine.applyMove(_state, move);
      _lastMove = move;
    });
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
    final turnText = _state.isGameOver
        ? (_state.winner != null
            ? '${_state.winner == ChessColor.white ? "White" : "Black"} wins!'
            : 'Draw!')
        : '${_state.activeColor == ChessColor.white ? "White" : "Black"}\'s turn';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess — Local Play'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
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
                  : (_state.isInCheck
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.brown.withValues(alpha: 0.05)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_state.isInCheck && !_state.isGameOver)
                    const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                  if (_state.isInCheck && !_state.isGameOver)
                    const SizedBox(width: 6),
                  Text(
                    _state.isInCheck && !_state.isGameOver
                        ? '$turnText — CHECK!'
                        : turnText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _state.isGameOver
                          ? Colors.deepPurple
                          : (_state.isInCheck ? Colors.red : Colors.brown[800]),
                    ),
                  ),
                ],
              ),
            ),

            // Board
            Expanded(
              child: Center(
                child: ChessBoardWidget(
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
                  ? const Center(
                      child: Text(
                        'Tap a piece to start playing',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (_moveHistory.length + 1) ~/ 2,
                      itemBuilder: (context, index) {
                        final moveNum = index + 1;
                        final whiteMove = _moveHistory[index * 2];
                        final blackMove = index * 2 + 1 < _moveHistory.length
                            ? _moveHistory[index * 2 + 1]
                            : '...';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 12),
                          child: Text(
                            '$moveNum. $whiteMove $blackMove',
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
                  label: const Text('Play Again'),
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
