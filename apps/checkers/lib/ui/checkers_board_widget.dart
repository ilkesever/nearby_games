import 'package:flutter/material.dart';

import '../game/checkers_engine.dart';
import '../game/checkers_move.dart';
import '../game/checkers_state.dart';

// ---------------------------------------------------------------------------
// Square coordinate helper (international draughts numbering, 1–50)
//
//   row 0 (top): squares 1-5  at cols 1,3,5,7,9
//   row 1:       squares 6-10 at cols 0,2,4,6,8
//   row r: col = 2 * position_in_row + (r.isEven ? 1 : 0)
// ---------------------------------------------------------------------------

Offset _squareCenter(int sq, double cellSize) {
  final idx = sq - 1;
  final row = idx ~/ 5;
  final pos = idx % 5;
  final col = 2 * pos + (row.isEven ? 1 : 0);
  return Offset((col + 0.5) * cellSize, (row + 0.5) * cellSize);
}

/// Returns the draughts square (1-50) at [localOffset], or null.
int? _hitSquare(Offset localOffset, double cellSize) {
  final col = (localOffset.dx / cellSize).floor();
  final row = (localOffset.dy / cellSize).floor();
  if (col < 0 || col >= 10 || row < 0 || row >= 10) return null;
  if ((row + col).isEven) return null; // light squares are unused
  final pos = col ~/ 2;
  final sq = row * 5 + pos + 1;
  if (sq < 1 || sq > 50) return null;
  return sq;
}

/// International draughts (10×10) board widget.
///
/// Renders the board, pieces, selection highlights, and valid-destination dots.
/// For multi-jump moves the user taps through each step one at a time, with a
/// gold trail showing the path taken so far. Interaction is enabled when
/// [interactive] is true.
class CheckersBoardWidget extends StatefulWidget {
  final CheckersState state;
  final CheckersEngine engine;
  final bool interactive;
  final void Function(CheckersMove move) onMove;

  const CheckersBoardWidget({
    super.key,
    required this.state,
    required this.engine,
    required this.interactive,
    required this.onMove,
  });

  @override
  State<CheckersBoardWidget> createState() => _CheckersBoardWidgetState();
}

class _CheckersBoardWidgetState extends State<CheckersBoardWidget> {
  int? _selectedSquare;
  List<CheckersMove> _validFromSelected = []; // all moves from selected piece
  List<int> _partialPath = []; // squares confirmed so far [from, ...]
  Set<int> _validNextSquares = {}; // dots to show at current step

  void _reset() {
    _selectedSquare = null;
    _validFromSelected = [];
    _partialPath = [];
    _validNextSquares = {};
  }

  /// Returns true if [jumps] starts with every element of [prefix].
  bool _pathStartsWith(List<int> jumps, List<int> prefix) {
    if (jumps.length < prefix.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (jumps[i] != prefix[i]) return false;
    }
    return true;
  }

  /// Returns the set of valid next squares given [confirmedSteps] already taken.
  Set<int> _nextStepSquares(List<CheckersMove> moves, int confirmedSteps) =>
      moves
          .where((m) => m.jumps.length > confirmedSteps)
          .map((m) => m.jumps[confirmedSteps])
          .toSet();

  void _onTap(Offset localOffset, double cellSize) {
    if (!widget.interactive) return;
    final sq = _hitSquare(localOffset, cellSize);
    if (sq == null) {
      setState(_reset);
      return;
    }

    // ── Phase A: a piece is already selected ─────────────────────────────
    if (_selectedSquare != null) {
      if (_validNextSquares.contains(sq)) {
        final newPath = [..._partialPath, sq];
        final stillValid = _validFromSelected
            .where((m) => _pathStartsWith(m.jumps, newPath))
            .toList();

        // Check for a complete move whose full jumps match newPath.
        final complete = stillValid
            .where((m) => m.jumps.length == newPath.length)
            .firstOrNull;

        if (complete != null) {
          widget.onMove(complete);
          setState(_reset);
          return;
        }

        // Not done yet — advance partial path and show next options.
        setState(() {
          _partialPath = newPath;
          _validFromSelected = stillValid;
          _validNextSquares = _nextStepSquares(stillValid, newPath.length);
        });
        return;
      }

      // Tapped the already-selected source — deselect.
      if (sq == _selectedSquare) {
        setState(_reset);
        return;
      }

      // Tapped elsewhere — try to re-select as new source.
      _reset();
    }

    // ── Phase B: select sq as source ─────────────────────────────────────
    final movesFrom = widget.engine.getMovesFromSquare(widget.state, sq);
    if (movesFrom.isNotEmpty) {
      setState(() {
        _selectedSquare = sq;
        _validFromSelected = movesFrom;
        _partialPath = [sq];
        _validNextSquares = _nextStepSquares(movesFrom, 1);
      });
    } else {
      setState(_reset);
    }
  }

  @override
  void didUpdateWidget(CheckersBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear selection when state changes (after a move is applied).
    if (oldWidget.state != widget.state) {
      _selectedSquare = null;
      _validFromSelected = [];
      _partialPath = [];
      _validNextSquares = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, constraints) {
        final cellSize = constraints.maxWidth / 10;
        final allMoves = widget.engine.getValidMoves(widget.state);
        final mustCaptureSquares = allMoves
            .where((m) => m.isCapture)
            .map((m) => m.from)
            .toSet();

        return GestureDetector(
          onTapDown: (d) => _onTap(d.localPosition, cellSize),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxWidth),
            painter: _BoardPainter(
              state: widget.state,
              engine: widget.engine,
              cellSize: cellSize,
              selectedSquare: _selectedSquare,
              validNextSquares: _validNextSquares,
              partialPath: _partialPath,
              mustCaptureSquares: mustCaptureSquares,
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _BoardPainter extends CustomPainter {
  final CheckersState state;
  final CheckersEngine engine;
  final double cellSize;
  final int? selectedSquare;
  final Set<int> validNextSquares;
  final List<int> partialPath;
  final Set<int> mustCaptureSquares;

  static const Color _lightSquare = Color(0xFFF0D9B5);
  static const Color _darkSquare = Color(0xFF8B4513);
  static const Color _selectedColor = Color(0xFFFFD700);
  static const Color _dotColor = Color(0x99FFD700);
  static const Color _pathLineColor = Color(0x88FFD700);
  static const Color _pathNodeColor = Color(0x55FFD700);
  static const Color _whitePiece = Color(0xFFF5F5F5);
  static const Color _blackPiece = Color(0xFF1A1A1A);
  static const Color _pieceBorder = Color(0xFF555555);
  static const Color _kingRing = Color(0xFFFFD700);
  static const Color _mustCaptureRing = Color(0xFFFF6B35);

  _BoardPainter({
    required this.state,
    required this.engine,
    required this.cellSize,
    required this.selectedSquare,
    required this.validNextSquares,
    required this.partialPath,
    required this.mustCaptureSquares,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoard(canvas);
    _drawHighlights(canvas);
    _drawPath(canvas);
    _drawPieces(canvas);
    _drawDots(canvas);
  }

  void _drawBoard(Canvas canvas) {
    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 10; col++) {
        final isDark = (row + col).isOdd;
        final paint = Paint()
          ..color = isDark ? _darkSquare : _lightSquare;
        canvas.drawRect(
          Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  void _drawHighlights(Canvas canvas) {
    if (selectedSquare == null) return;
    final center = _squareCenter(selectedSquare!, cellSize);
    final paint = Paint()
      ..color = _selectedColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: cellSize, height: cellSize),
      paint,
    );
  }

  void _drawPath(Canvas canvas) {
    if (partialPath.length < 2) return;

    // Draw connecting lines between consecutive confirmed squares.
    final linePaint = Paint()
      ..color = _pathLineColor
      ..strokeWidth = cellSize * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < partialPath.length - 1; i++) {
      canvas.drawLine(
        _squareCenter(partialPath[i], cellSize),
        _squareCenter(partialPath[i + 1], cellSize),
        linePaint,
      );
    }

    // Small dimmed circles at intermediate waypoints already passed through.
    final nodePaint = Paint()
      ..color = _pathNodeColor
      ..style = PaintingStyle.fill;
    for (int i = 1; i < partialPath.length - 1; i++) {
      canvas.drawCircle(
          _squareCenter(partialPath[i], cellSize), cellSize * 0.12, nodePaint);
    }
  }

  void _drawPieces(Canvas canvas) {
    final radius = cellSize * 0.38;
    for (int sq = 1; sq <= 50; sq++) {
      final piece = state.draughts.getPiece(sq);
      if (piece == null) continue;

      final center = _squareCenter(sq, cellSize);
      final isWhite = piece == 'w' || piece == 'W';
      final isKing = piece == 'W' || piece == 'B';

      // Shadow
      final shadowPaint = Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center.translate(2, 2), radius, shadowPaint);

      // Body
      final bodyPaint = Paint()
        ..color = isWhite ? _whitePiece : _blackPiece
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, bodyPaint);

      // Border
      final borderPaint = Paint()
        ..color = _pieceBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, borderPaint);

      // King indicator: golden inner ring
      if (isKing) {
        final kingPaint = Paint()
          ..color = _kingRing
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(center, radius * 0.55, kingPaint);
      }

      // Must-capture indicator: orange outer ring
      if (mustCaptureSquares.contains(sq)) {
        final capturePaint = Paint()
          ..color = _mustCaptureRing
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(center, radius + 4, capturePaint);
      }
    }
  }

  void _drawDots(Canvas canvas) {
    for (final sq in validNextSquares) {
      final center = _squareCenter(sq, cellSize);
      canvas.drawCircle(
        center,
        cellSize * 0.18,
        Paint()
          ..color = _dotColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.state != state ||
      old.selectedSquare != selectedSquare ||
      old.validNextSquares != validNextSquares ||
      old.partialPath != partialPath ||
      old.mustCaptureSquares != mustCaptureSquares;
}
