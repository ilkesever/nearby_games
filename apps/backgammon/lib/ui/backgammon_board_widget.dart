import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/backgammon_engine.dart';
import '../game/backgammon_move.dart';
import '../game/backgammon_state.dart';

class BackgammonBoardWidget extends StatefulWidget {
  final BackgammonState state;
  final BackgammonEngine engine;
  final bool interactive;
  final bool flipped;
  final BackgammonMove? lastMove;
  final void Function(BackgammonMove)? onMove;

  const BackgammonBoardWidget({
    super.key,
    required this.state,
    required this.engine,
    required this.interactive,
    required this.flipped,
    this.lastMove,
    this.onMove,
  });

  @override
  State<BackgammonBoardWidget> createState() =>
      _BackgammonBoardWidgetState();
}

class _BackgammonBoardWidgetState extends State<BackgammonBoardWidget> {
  List<int> _rolledDice = [];
  List<int> _usedDice = [];
  int? _selectedPoint; // null = none; 0 = bar
  List<CheckerMove> _pendingMoves = [];
  List<CheckerMove> _validDestinations = [];
  // Tracks the board state after each pending checker move so that
  // subsequent move hints are computed on the correct intermediate position.
  late BackgammonState _currentBoardState;

  @override
  void initState() {
    super.initState();
    _currentBoardState = widget.state;
  }

  @override
  void didUpdateWidget(BackgammonBoardWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _resetLocalState();
    }
  }

  void _resetLocalState() {
    _rolledDice = [];
    _usedDice = [];
    _selectedPoint = null;
    _pendingMoves = [];
    _validDestinations = [];
    _currentBoardState = widget.state;
  }

  List<int> get _remainingDice {
    final remaining = List<int>.from(_rolledDice);
    for (final d in _usedDice) {
      remaining.remove(d);
    }
    return remaining;
  }

  bool get _canSubmit => _pendingMoves.isNotEmpty || _noMoreMoves;

  bool get _noMoreMoves {
    if (_remainingDice.isEmpty) return false;
    return widget.engine
        .getValidMoves(_currentBoardState.copyWith(
          phase: GamePhase.moving,
          remainingDice: _remainingDice,
        ))
        .isEmpty;
  }

  void _rollDice() {
    final rng = math.Random();
    final d1 = rng.nextInt(6) + 1;
    final d2 = rng.nextInt(6) + 1;
    final dice = d1 == d2 ? [d1, d1, d1, d1] : [d1, d2];
    setState(() {
      _rolledDice = dice;
      _usedDice = [];
      _pendingMoves = [];
      _selectedPoint = null;
      _validDestinations = [];
    });
  }

  void _onPointTap(int point) {
    if (!widget.interactive) return;
    if (_rolledDice.isEmpty) return;

    // If a point is already selected
    if (_selectedPoint != null) {
      // Tapping a valid destination
      final dest = _validDestinations.where((d) => d.to == point).toList();
      if (dest.isNotEmpty) {
        _makeCheckerMove(dest.first);
        return;
      }
      // Tapping same point = deselect
      if (_selectedPoint == point) {
        setState(() {
          _selectedPoint = null;
          _validDestinations = [];
        });
        return;
      }
    }

    // Select a new point — check against current (intermediate) board state
    final currentColor = _currentBoardState.activeColor;
    final currentBar = currentColor == BackgammonColor.white
        ? _currentBoardState.whiteBar
        : _currentBoardState.blackBar;

    bool canSelect = false;
    if (currentBar > 0) {
      canSelect = point == 0; // bar
    } else {
      if (point >= 1 && point <= 24) {
        final p = _currentBoardState.points[point];
        canSelect = !p.isEmpty && p.color == currentColor;
      }
    }

    if (!canSelect) {
      setState(() {
        _selectedPoint = null;
        _validDestinations = [];
      });
      return;
    }

    final movingState = _currentBoardState.copyWith(
      phase: GamePhase.moving,
      remainingDice: _remainingDice,
    );

    final dests =
        widget.engine.getValidMovesForPoint(movingState, point, _remainingDice);

    setState(() {
      _selectedPoint = point;
      _validDestinations = dests;
    });
  }

  void _makeCheckerMove(CheckerMove cm) {
    // Figure out which die was used, based on current intermediate board state
    final color = _currentBoardState.activeColor;
    int neededDie;
    if (cm.from == 0) {
      neededDie = color == BackgammonColor.white ? (25 - cm.to) : cm.to;
    } else if (cm.to == 25) {
      neededDie = color == BackgammonColor.white ? cm.from : (25 - cm.from);
    } else {
      neededDie = color == BackgammonColor.white
          ? (cm.from - cm.to)
          : (cm.to - cm.from);
    }

    int dieUsed = neededDie;
    if (!_remainingDice.contains(neededDie) && cm.to == 25) {
      final overshoots =
          _remainingDice.where((d) => d > neededDie).toList()..sort();
      if (overshoots.isNotEmpty) dieUsed = overshoots.first;
    }

    setState(() {
      _usedDice.add(dieUsed);
      _pendingMoves.add(cm);
      _currentBoardState = widget.engine.applyCheckerMove(_currentBoardState, cm);
      _selectedPoint = null;
      _validDestinations = [];
    });

    // Auto-submit when all dice used
    if (_remainingDice.isEmpty) {
      _submit();
    }
  }

  void _submit() {
    widget.onMove?.call(BackgammonMove(
      dice: _rolledDice,
      checkerMoves: List.unmodifiable(_pendingMoves),
    ));
    _resetLocalState();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isRolling =
        widget.interactive && state.phase == GamePhase.rolling && _rolledDice.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final boardWidth = size;
        final boardHeight = size * 0.6;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Borne-off count for top player
            // Not flipped: top = Black (home pts 19-24), bottom = White (home pts 1-6)
            // Flipped: top = White, bottom = Black
            _buildBorneOffRow(
                widget.flipped ? BackgammonColor.white : BackgammonColor.black,
                boardWidth),
            const SizedBox(height: 4),
            // Main board
            SizedBox(
              width: boardWidth,
              height: boardHeight,
              child: GestureDetector(
                onTapUp: (details) =>
                    _handleBoardTap(details.localPosition, boardWidth, boardHeight),
                child: CustomPaint(
                  painter: _BoardPainter(
                    state: state,
                    flipped: widget.flipped,
                    selectedPoint: _selectedPoint,
                    validDests: _validDestinations.map((m) => m.to).toSet(),
                    lastMove: widget.lastMove,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Borne-off count for bottom player
            _buildBorneOffRow(
                widget.flipped ? BackgammonColor.black : BackgammonColor.white,
                boardWidth),
            const SizedBox(height: 12),
            // Dice area
            _buildDiceArea(isRolling, boardWidth),
          ],
        );
      },
    );
  }

  Widget _buildBorneOffRow(BackgammonColor color, double width) {
    final count = color == BackgammonColor.white
        ? widget.state.whiteBorneOff
        : widget.state.blackBorneOff;
    final label = color == BackgammonColor.white ? 'White' : 'Black';
    final checkerColor =
        color == BackgammonColor.white ? Colors.white : Colors.brown[900]!;

    return SizedBox(
      width: width,
      height: 28,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text('$label bore off: ',
              style: TextStyle(fontSize: 12, color: Colors.brown[700])),
          for (int i = 0; i < count; i++)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checkerColor,
                border: Border.all(color: Colors.brown[400]!, width: 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiceArea(bool isRolling, double width) {
    if (isRolling) {
      return ElevatedButton.icon(
        onPressed: _rollDice,
        icon: const Text('🎲', style: TextStyle(fontSize: 20)),
        label: const Text('Roll Dice', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[700],
          foregroundColor: Colors.white,
          minimumSize: const Size(160, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (_rolledDice.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ..._rolledDice.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          final used = i < _usedDice.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DiceFaceWidget(value: d, used: used),
          );
        }),
        if (_canSubmit) ...[
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(72, 40),
            ),
            child: const Text('Done'),
          ),
        ],
      ],
    );
  }

  void _handleBoardTap(Offset pos, double w, double h) {
    if (!widget.interactive || _rolledDice.isEmpty) return;

    final pointIndex = _hitTestPoint(pos, w, h);
    if (pointIndex != null) {
      _onPointTap(pointIndex);
    }
  }

  /// Returns the board point (1–24) or 0 (bar) tapped, or null.
  int? _hitTestPoint(Offset pos, double w, double h) {
    final barLeft = w * 7 / 15;
    final barRight = w * 8 / 15;

    // Bar tap
    if (pos.dx >= barLeft && pos.dx <= barRight) return 0;

    // Top half: points 13–24 (left=13..18, right=19..24)
    // Bottom half: points 12–1 (left=12..7, right=6..1)
    final topHalf = pos.dy < h / 2;

    int? col; // 0-5 or 6-11 (skipping bar column 6)
    if (pos.dx < barLeft) {
      col = (pos.dx / (barLeft / 6)).floor().clamp(0, 5);
    } else if (pos.dx > barRight) {
      col = 6 + ((pos.dx - barRight) / ((w - barRight) / 6)).floor().clamp(0, 5);
    }

    if (col == null) return null;

    // Convert col + topHalf to point number
    if (topHalf) {
      // Left side: col 0→pt13, col 1→pt14, ..., col 5→pt18
      // Right side: col 6→pt19, col 7→pt20, ..., col 11→pt24
      final pt = col < 6 ? 13 + col : 19 + (col - 6);
      return widget.flipped ? (25 - pt) : pt;
    } else {
      // Left side: col 0→pt12, col 1→pt11, ..., col 5→pt7
      // Right side: col 6→pt6, col 7→pt5, ..., col 11→pt1
      final pt = col < 6 ? 12 - col : 6 - (col - 6);
      return widget.flipped ? (25 - pt) : pt;
    }
  }
}

// ---------------------------------------------------------------------------
// Board painter
// ---------------------------------------------------------------------------

class _BoardPainter extends CustomPainter {
  final BackgammonState state;
  final bool flipped;
  final int? selectedPoint;
  final Set<int> validDests;
  final BackgammonMove? lastMove;

  const _BoardPainter({
    required this.state,
    required this.flipped,
    required this.selectedPoint,
    required this.validDests,
    this.lastMove,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawBackground(canvas, size);
    _drawTriangles(canvas, w, h);
    _drawBar(canvas, w, h);
    _drawCheckers(canvas, w, h);
    _drawBarCheckers(canvas, w, h);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF5D4037),
    );
    // Inner board
    final margin = size.width * 0.01;
    canvas.drawRect(
      Rect.fromLTWH(margin, margin, size.width - margin * 2,
          size.height - margin * 2),
      Paint()..color = const Color(0xFF3E2723),
    );
  }

  // Returns the x-center of point index 1–24.
  // Layout: bottom-left = 12,11,10,9,8,7  bottom-right = 6,5,4,3,2,1
  //         top-left    = 13,14,15,16,17,18  top-right = 19,20,21,22,23,24
  double _pointX(int pt, double w) {
    final barCenter = w / 2;
    final halfW = (barCenter - w * 0.04) / 6; // width per point slot

    // Logical position before flipping:
    // pt 1: rightmost bottom-right → col index 5 on right side
    // pt 6: leftmost bottom-right  → col index 0 on right side
    // pt 7: rightmost bottom-left  → col index 5 on left side
    // pt 12: leftmost bottom-left  → col index 0 on left side
    // pt 13: leftmost top-left     → col index 0 on left side
    // pt 18: rightmost top-left    → col index 5 on left side
    // pt 19: leftmost top-right    → col index 0 on right side
    // pt 24: rightmost top-right   → col index 5 on right side

    final effectivePt = flipped ? (25 - pt) : pt;

    if (effectivePt >= 1 && effectivePt <= 6) {
      // Bottom right
      final col = effectivePt - 1; // 0-5, 0=pt1(right)=farthest right
      return barCenter + w * 0.04 / 2 + (5 - col) * halfW + halfW / 2;
    } else if (effectivePt >= 7 && effectivePt <= 12) {
      // Bottom left: pt12 at leftmost (mirrors pt13 above), pt7 nearest bar
      final col = 12 - effectivePt; // 0=pt12(leftmost), 5=pt7(nearest bar)
      return w * 0.02 + col * halfW + halfW / 2;
    } else if (effectivePt >= 13 && effectivePt <= 18) {
      // Top left
      final col = effectivePt - 13; // 0-5, 0=pt13=closest to left edge
      return w * 0.02 + col * halfW + halfW / 2;
    } else {
      // Top right (19-24)
      final col = effectivePt - 19; // 0-5, 0=pt19=closest to bar
      return barCenter + w * 0.04 / 2 + col * halfW + halfW / 2;
    }
  }

  void _drawTriangles(Canvas canvas, double w, double h) {
    final highlightColor = const Color(0xFFFFEB3B).withValues(alpha: 0.7);
    final destColor = const Color(0xFF4CAF50).withValues(alpha: 0.8);

    for (int pt = 1; pt <= 24; pt++) {
      final isTop = (pt >= 13 && pt <= 24);
      final isEvenVisual = (flipped ? (25 - pt) : pt) % 2 == 0;
      final baseColor = isEvenVisual
          ? const Color(0xFFD7CCC8) // light
          : const Color(0xFFBF360C); // dark red

      Color color = baseColor;
      if (pt == selectedPoint) {
        color = highlightColor;
      } else if (validDests.contains(pt)) {
        color = destColor;
      } else if (lastMove?.checkerMoves.any((m) => m.from == pt || m.to == pt) ??
          false) {
        color = baseColor.withValues(alpha: 0.6);
      }

      _drawTriangle(canvas, _pointX(pt, w), isTop ? 0 : h, w / 13, h * 0.42,
          isTop, color);
    }
  }

  void _drawTriangle(Canvas canvas, double cx, double baseY, double width,
      double height, bool pointDown, Color color) {
    final tipY = pointDown ? baseY + height : baseY - height;
    final path = Path()
      ..moveTo(cx - width / 2, baseY)
      ..lineTo(cx + width / 2, baseY)
      ..lineTo(cx, tipY)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawBar(Canvas canvas, double w, double h) {
    final barPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRect(
      Rect.fromLTWH(w / 2 - w * 0.02, 0, w * 0.04, h),
      barPaint,
    );
  }

  void _drawCheckers(Canvas canvas, double w, double h) {
    for (int pt = 1; pt <= 24; pt++) {
      final p = state.points[pt];
      if (p.isEmpty) continue;

      final cx = _pointX(pt, w);
      final isTop = (pt >= 13 && pt <= 24);
      final checkerR = w / 26;
      final maxVisible = 5;
      final count = p.count;

      for (int i = 0; i < math.min(count, maxVisible); i++) {
        final dy = isTop
            ? checkerR + i * checkerR * 1.9
            : h - checkerR - i * checkerR * 1.9;
        _drawChecker(canvas, Offset(cx, dy), checkerR, p.color!);
      }

      if (count > maxVisible) {
        final dy = isTop
            ? checkerR + maxVisible * checkerR * 1.9
            : h - checkerR - maxVisible * checkerR * 1.9;
        final textPainter = TextPainter(
          text: TextSpan(
            text: '+${count - maxVisible}',
            style: TextStyle(
              fontSize: checkerR * 1.2,
              color: p.color == BackgammonColor.white
                  ? Colors.brown[900]
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
            canvas, Offset(cx - textPainter.width / 2, dy - textPainter.height / 2));
      }
    }
  }

  void _drawBarCheckers(Canvas canvas, double w, double h) {
    final barCx = w / 2;
    final r = w / 26;

    void drawBar(int count, BackgammonColor color, bool top) {
      final visible = count.clamp(0, 4);
      for (int i = 0; i < visible; i++) {
        final dy = top
            ? h * 0.1 + i * r * 2.1
            : h * 0.9 - i * r * 2.1;
        _drawChecker(canvas, Offset(barCx, dy), r, color);
      }
      if (count > 4) {
        final dy = top
            ? h * 0.1 + 4 * r * 2.1
            : h * 0.9 - 4 * r * 2.1;
        final textPainter = TextPainter(
          text: TextSpan(
            text: '+${count - 4}',
            style: TextStyle(
              fontSize: r * 1.2,
              color: color == BackgammonColor.white
                  ? Colors.brown[900]
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
            canvas,
            Offset(barCx - textPainter.width / 2,
                dy - textPainter.height / 2));
      }
    }

    drawBar(state.whiteBar, BackgammonColor.white, !flipped);
    drawBar(state.blackBar, BackgammonColor.black, flipped);
  }

  void _drawChecker(
      Canvas canvas, Offset center, double radius, BackgammonColor color) {
    final isWhite = color == BackgammonColor.white;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = isWhite ? Colors.white : const Color(0xFF1A1A1A),
    );
    canvas.drawCircle(
      center,
      radius * 0.85,
      Paint()
        ..color = (isWhite ? Colors.brown[300]! : Colors.brown[700]!)
            .withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.brown[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.state != state ||
      old.selectedPoint != selectedPoint ||
      old.validDests != validDests ||
      old.flipped != flipped ||
      old.lastMove != lastMove;
}

// ---------------------------------------------------------------------------
// Dice face widget
// ---------------------------------------------------------------------------

class _DiceFaceWidget extends StatelessWidget {
  final int value;
  final bool used;

  const _DiceFaceWidget({required this.value, required this.used});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: used ? Colors.grey[300] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: used ? Colors.grey[400]! : Colors.brown[700]!,
          width: 2,
        ),
        boxShadow: used
            ? null
            : [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(1, 2))
              ],
      ),
      child: CustomPaint(
        painter: _DiceDotsPainter(value: value, used: used),
      ),
    );
  }
}

class _DiceDotsPainter extends CustomPainter {
  final int value;
  final bool used;

  const _DiceDotsPainter({required this.value, required this.used});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = used ? Colors.grey[400]! : Colors.brown[800]!;
    final r = size.width * 0.1;
    final positions = _dotPositions(value, size);
    for (final p in positions) {
      canvas.drawCircle(p, r, paint);
    }
  }

  List<Offset> _dotPositions(int value, Size s) {
    final w = s.width;
    final h = s.height;
    final t = h * 0.25;
    final m = h * 0.5;
    final b = h * 0.75;
    final l = w * 0.25;
    final c = w * 0.5;
    final r = w * 0.75;

    switch (value) {
      case 1:
        return [Offset(c, m)];
      case 2:
        return [Offset(l, t), Offset(r, b)];
      case 3:
        return [Offset(l, t), Offset(c, m), Offset(r, b)];
      case 4:
        return [Offset(l, t), Offset(r, t), Offset(l, b), Offset(r, b)];
      case 5:
        return [
          Offset(l, t), Offset(r, t), Offset(c, m), Offset(l, b), Offset(r, b)
        ];
      case 6:
        return [
          Offset(l, t), Offset(r, t),
          Offset(l, m), Offset(r, m),
          Offset(l, b), Offset(r, b)
        ];
      default:
        return [];
    }
  }

  @override
  bool shouldRepaint(_DiceDotsPainter old) =>
      old.value != value || old.used != used;
}