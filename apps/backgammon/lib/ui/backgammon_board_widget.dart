import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/backgammon_engine.dart';
import '../src/l10n/app_localizations.dart';
import '../game/backgammon_move.dart';
import '../game/backgammon_state.dart';

class OpponentPreview {
  final List<int> dice;
  final List<CheckerMove> moves;
  const OpponentPreview({required this.dice, required this.moves});
}

class BackgammonBoardWidget extends StatefulWidget {
  final BackgammonState state;
  final BackgammonEngine engine;
  final bool interactive;
  final bool flipped;
  final BackgammonMove? lastMove;
  final void Function(BackgammonMove)? onMove;
  final void Function(List<int> dice, List<CheckerMove> moves)? onPreviewChanged;
  final OpponentPreview? opponentPreview;
  // When set, bar checkers for this color pulse with a gold ring on the
  // player's turn. Pass null for pass-and-play (no focused pulse).
  final BackgammonColor? localColor;

  const BackgammonBoardWidget({
    super.key,
    required this.state,
    required this.engine,
    required this.interactive,
    required this.flipped,
    this.lastMove,
    this.onMove,
    this.onPreviewChanged,
    this.opponentPreview,
    this.localColor,
  });

  @override
  State<BackgammonBoardWidget> createState() =>
      _BackgammonBoardWidgetState();
}

class _BackgammonBoardWidgetState extends State<BackgammonBoardWidget>
    with SingleTickerProviderStateMixin {
  AppLocalizations get _l10n => AppLocalizations.of(context);

  List<int> _rolledDice = [];
  List<int> _usedDice = [];
  int? _selectedPoint; // null = none; 0 = bar
  List<CheckerMove> _pendingMoves = [];
  List<CheckerMove> _validDestinations = [];
  // Combined (multi-die) destinations: final point → sequence of checker moves
  Map<int, List<CheckerMove>> _combinedMoveMap = {};
  // Tracks the board state after each pending checker move so that
  // subsequent move hints are computed on the correct intermediate position.
  late BackgammonState _currentBoardState;
  // Opening roll: die rolled locally but not yet submitted to engine
  int? _localOpeningDie;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentBoardState = widget.state;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = _pulseController;
    _pulseController.addListener(() => setState(() {}));
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(BackgammonBoardWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _resetLocalState();
    }
    _syncPulseAnimation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _syncPulseAnimation() {
    if (!widget.interactive) {
      _pulseController.stop();
      _pulseController.value = 0.0;
      return;
    }
    // BLE game: pulse the local player's bar checkers.
    // Pass-and-play (localColor == null): pulse whoever is active.
    final effectiveColor =
        widget.localColor ?? _currentBoardState.activeColor;
    final hasBar = effectiveColor == BackgammonColor.white
        ? _currentBoardState.whiteBar > 0
        : _currentBoardState.blackBar > 0;
    if (hasBar) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  void _resetLocalState() {
    _rolledDice = [];
    _usedDice = [];
    _selectedPoint = null;
    _pendingMoves = [];
    _validDestinations = [];
    _combinedMoveMap = {};
    _currentBoardState = widget.state;
    _localOpeningDie = null;
    _syncPulseAnimation();
  }

  List<int> get _remainingDice {
    final remaining = List<int>.from(_rolledDice);
    for (final d in _usedDice) {
      remaining.remove(d);
    }
    return remaining;
  }

  bool get _canSubmit => _remainingDice.isEmpty || _noMoreMoves;

  void _emitPreview() {
    widget.onPreviewChanged?.call(
      List.unmodifiable(_rolledDice),
      List.unmodifiable(_pendingMoves),
    );
  }

  /// Board state to display — uses opponent preview when waiting.
  BackgammonState get _displayState {
    if (!widget.interactive &&
        widget.opponentPreview != null &&
        widget.opponentPreview!.moves.isNotEmpty) {
      var s = widget.state;
      for (final cm in widget.opponentPreview!.moves) {
        s = widget.engine.applyCheckerMove(s, cm);
      }
      return s;
    }
    return _currentBoardState;
  }

  bool get _noMoreMoves {
    if (_remainingDice.isEmpty) return false;
    return widget.engine
        .getValidMoves(_currentBoardState.copyWith(
          phase: GamePhase.moving,
          remainingDice: _remainingDice,
        ))
        .isEmpty;
  }

  // ---------------------------------------------------------------------------
  // Opening roll
  // ---------------------------------------------------------------------------

  void _rollOpeningDie() {
    if (!widget.interactive || _localOpeningDie != null) return;
    final die = math.Random().nextInt(6) + 1;
    setState(() => _localOpeningDie = die);
    // Show result briefly before committing to the engine
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        widget.onMove
            ?.call(BackgammonMove(dice: [die], checkerMoves: const []));
        setState(() => _localOpeningDie = null);
      }
    });
  }

  Widget _buildOpeningRollView() {
    final s = widget.state;
    final isWhiteActive = s.activeColor == BackgammonColor.white;

    // Compute displayed die values: committed (from state) or locally rolled
    final displayWhite = s.whiteOpeningDie ??
        (isWhiteActive && _localOpeningDie != null ? _localOpeningDie : null);
    final displayBlack = s.blackOpeningDie ??
        (!isWhiteActive && _localOpeningDie != null ? _localOpeningDie : null);
    final bothKnown = displayWhite != null && displayBlack != null;

    String statusText;
    Color statusColor = Colors.brown[700]!;
    if (displayWhite != null && displayBlack != null) {
      if (displayWhite == displayBlack) {
        statusText = _l10n.openingRollTie;
        statusColor = Colors.red[700]!;
      } else {
        final winner = displayWhite > displayBlack ? _l10n.scoreWhite : _l10n.scoreBlack;
        statusText = _l10n.openingRollGoesFirst(winner);
        statusColor = Colors.green[700]!;
      }
    } else if (s.whiteOpeningDie != null) {
      statusText = widget.interactive ? _l10n.openingRollYourTurn : _l10n.openingRollBlackToRoll;
    } else if (s.blackOpeningDie != null) {
      statusText = widget.interactive ? _l10n.openingRollYourTurn : _l10n.openingRollWhiteToRoll;
    } else {
      statusText = widget.interactive ? _l10n.openingRollTapToRoll : _l10n.openingRollWaitingForOpponent;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _l10n.openingRollTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: bothKnown ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOpeningDieCard(
                  label: _l10n.scoreWhite,
                  chipColor: Colors.white,
                  borderColor: Colors.brown[400]!,
                  die: displayWhite,
                  canRoll: widget.interactive &&
                      isWhiteActive &&
                      s.whiteOpeningDie == null &&
                      _localOpeningDie == null,
                  isWinner: displayWhite != null &&
                      displayBlack != null &&
                      displayWhite > displayBlack,
                ),
                _buildOpeningDieCard(
                  label: _l10n.scoreBlack,
                  chipColor: Colors.grey[850]!,
                  borderColor: Colors.brown[400]!,
                  die: displayBlack,
                  canRoll: widget.interactive &&
                      !isWhiteActive &&
                      s.blackOpeningDie == null &&
                      _localOpeningDie == null,
                  isWinner: displayWhite != null &&
                      displayBlack != null &&
                      displayBlack > displayWhite,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningDieCard({
    required String label,
    required Color chipColor,
    required Color borderColor,
    required int? die,
    required bool canRoll,
    required bool isWinner,
  }) {
    return GestureDetector(
      onTap: canRoll ? _rollOpeningDie : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isWinner
              ? Colors.amber[50]
              : (canRoll ? Colors.brown[50] : Colors.brown[100]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWinner ? Colors.amber[700]! : borderColor,
            width: isWinner ? 2.5 : 1.5,
          ),
          boxShadow: canRoll
              ? [
                  BoxShadow(
                    color: Colors.brown.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: chipColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 10),
            die != null
                ? _DiceFaceWidget(value: die, used: false)
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: canRoll ? Colors.brown[200] : Colors.brown[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.brown[300]!, width: 1.5),
                    ),
                    child: Icon(
                      canRoll ? Icons.touch_app : Icons.hourglass_empty,
                      color: Colors.brown[400],
                      size: 22,
                    ),
                  ),
          ],
        ),
      ),
    );
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
      _combinedMoveMap = {};
    });

    // Auto-skip if no valid moves exist with these dice
    final hasNoMoves = widget.engine
        .getValidMoves(_currentBoardState.copyWith(
          phase: GamePhase.moving,
          remainingDice: dice,
        ))
        .isEmpty;
    _emitPreview();
    if (hasNoMoves) {
      Future.delayed(const Duration(milliseconds: 800), _submit);
    }
  }

  void _onPointTap(int point) {
    if (!widget.interactive) return;
    if (_rolledDice.isEmpty) return;

    // If a point is already selected
    if (_selectedPoint != null) {
      // Tapping a valid single-die destination
      final dest = _validDestinations.where((d) => d.to == point).toList();
      if (dest.isNotEmpty) {
        _makeCheckerMove(dest.first);
        return;
      }
      // Tapping a combined (multi-die) destination
      if (_combinedMoveMap.containsKey(point)) {
        _makeCombinedMove(_combinedMoveMap[point]!);
        return;
      }
      // Tapping same point = deselect
      if (_selectedPoint == point) {
        setState(() {
          _selectedPoint = null;
          _validDestinations = [];
          _combinedMoveMap = {};
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
        _combinedMoveMap = {};
      });
      return;
    }

    final movingState = _currentBoardState.copyWith(
      phase: GamePhase.moving,
      remainingDice: _remainingDice,
    );

    final dests =
        widget.engine.getValidMovesForPoint(movingState, point, _remainingDice);
    final combined = _remainingDice.length > 1
        ? widget.engine
            .getCombinedDestinations(movingState, point, _remainingDice)
        : <int, List<CheckerMove>>{};

    // Auto-execute if the only possible destination is bearing off
    if (dests.isNotEmpty && dests.every((d) => d.to == 25) && combined.isEmpty) {
      _makeCheckerMove(dests.first);
      return;
    }

    setState(() {
      _selectedPoint = point;
      _validDestinations = dests;
      _combinedMoveMap = combined;
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
      _combinedMoveMap = {};
    });
    _emitPreview();
  }

  /// Executes a combined (multi-die) move sequence in one setState.
  void _makeCombinedMove(List<CheckerMove> moves) {
    setState(() {
      for (final cm in moves) {
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
        final remaining = List<int>.from(_rolledDice);
        for (final d in _usedDice) {
          remaining.remove(d);
        }
        int dieUsed = neededDie;
        if (!remaining.contains(neededDie) && cm.to == 25) {
          final overshoots = remaining.where((d) => d > neededDie).toList()
            ..sort();
          if (overshoots.isNotEmpty) dieUsed = overshoots.first;
        }
        _usedDice.add(dieUsed);
        _pendingMoves.add(cm);
        _currentBoardState =
            widget.engine.applyCheckerMove(_currentBoardState, cm);
      }
      _selectedPoint = null;
      _validDestinations = [];
      _combinedMoveMap = {};
    });
    _emitPreview();
  }

  void _undo() {
    if (_pendingMoves.isEmpty) return;
    setState(() {
      _pendingMoves.removeLast();
      _usedDice.removeLast();
      // Replay remaining moves from canonical state to recompute intermediate state
      _currentBoardState = widget.state;
      for (final move in _pendingMoves) {
        _currentBoardState = widget.engine.applyCheckerMove(_currentBoardState, move);
      }
      _selectedPoint = null;
      _validDestinations = [];
      _combinedMoveMap = {};
    });
    _emitPreview();
  }

  void _submit() {
    widget.onPreviewChanged?.call(const [], const []);
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
    // Show opening roll UI instead of the board during the opening phase
    if (widget.state.phase == GamePhase.openingRoll) {
      return _buildOpeningRollView();
    }

    final isRolling =
        widget.interactive && widget.state.phase == GamePhase.rolling && _rolledDice.isEmpty;

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
                    state: _displayState,
                    flipped: widget.flipped,
                    selectedPoint: _selectedPoint,
                    validDests: _validDestinations.map((m) => m.to).toSet(),
                    combinedDests: _combinedMoveMap.keys.toSet(),
                    lastMove: widget.lastMove,
                    opponentPreview: widget.opponentPreview,
                    pulseValue: _pulseAnimation.value,
                    localColor: widget.localColor,
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
    final boardState = _displayState;
    final count = color == BackgammonColor.white
        ? boardState.whiteBorneOff
        : boardState.blackBorneOff;
    final label = color == BackgammonColor.white ? _l10n.scoreWhite : _l10n.scoreBlack;
    final checkerColor =
        color == BackgammonColor.white ? Colors.white : Colors.brown[900]!;
    final canBearOff = _validDestinations.any((d) => d.to == 25);

    return GestureDetector(
      onTap: () => _onPointTap(25),
      child: Container(
        width: width,
        height: 28,
        decoration: canBearOff
            ? BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
                    width: 2),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Text(_l10n.boreOffLabel(label),
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
      ),
    );
  }

  Widget _buildDiceArea(bool isRolling, double width) {
    if (isRolling) {
      return ElevatedButton.icon(
        onPressed: _rollDice,
        icon: const Text('🎲', style: TextStyle(fontSize: 20)),
        label: Text(_l10n.localGameRollDice, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[700],
          foregroundColor: Colors.white,
          minimumSize: const Size(160, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (_rolledDice.isEmpty) {
      // Show live opponent preview when they're actively playing
      if (!widget.interactive &&
          widget.opponentPreview != null &&
          widget.opponentPreview!.dice.isNotEmpty) {
        return _buildLivePreviewDice(widget.opponentPreview!);
      }
      return const SizedBox.shrink();
    }

    final usedCopy = List<int>.from(_usedDice);
    final usedFlags = _rolledDice.map((d) {
      final idx = usedCopy.indexOf(d);
      if (idx != -1) {
        usedCopy.removeAt(idx);
        return true;
      }
      return false;
    }).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ..._rolledDice.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          final used = usedFlags[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _DiceFaceWidget(value: d, used: used),
          );
        }),
        if (_pendingMoves.isNotEmpty) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _undo,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.brown[700],
              side: BorderSide(color: Colors.brown[400]!),
              minimumSize: const Size(64, 40),
            ),
            child: Text(_l10n.moveUndo),
          ),
        ],
        if (_canSubmit) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(72, 40),
            ),
            child: Text(_l10n.moveDone),
          ),
        ],
      ],
    );
  }

  Widget _buildLivePreviewDice(OpponentPreview preview) {
    final moveCount = preview.moves.length;
    // For doubles, dice list has 4 entries; mark first N as used
    final diceCount = preview.dice.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _l10n.opponentPlaying,
              style: TextStyle(
                fontSize: 12,
                color: Colors.brown[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < diceCount; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DiceFaceWidget(
                  value: preview.dice[i],
                  used: i < moveCount,
                ),
              ),
          ],
        ),
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
  final Set<int> combinedDests;
  final BackgammonMove? lastMove;
  final OpponentPreview? opponentPreview;
  final double pulseValue;
  final BackgammonColor? localColor;

  _BoardPainter({
    required this.state,
    required this.flipped,
    required this.selectedPoint,
    required this.validDests,
    required this.combinedDests,
    required this.pulseValue,
    required this.localColor,
    this.lastMove,
    this.opponentPreview,
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
    final halfW = (barCenter - w * 0.02 - w * 0.01) / 6; // width per point slot

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
      return w * 0.01 + col * halfW + halfW / 2;
    } else if (effectivePt >= 13 && effectivePt <= 18) {
      // Top left
      final col = effectivePt - 13; // 0-5, 0=pt13=closest to left edge
      return w * 0.01 + col * halfW + halfW / 2;
    } else {
      // Top right (19-24)
      final col = effectivePt - 19; // 0-5, 0=pt19=closest to bar
      return barCenter + w * 0.04 / 2 + col * halfW + halfW / 2;
    }
  }

  void _drawTriangles(Canvas canvas, double w, double h) {
    final highlightColor = const Color(0xFFFFEB3B).withValues(alpha: 0.7);
    final destColor = const Color(0xFF4CAF50).withValues(alpha: 0.8);
    // Combined (multi-die) destinations shown in blue
    final combinedDestColor = const Color(0xFF2196F3).withValues(alpha: 0.8);
    final slotW = (w / 2 - w * 0.02 - w * 0.01) / 6;

    for (int pt = 1; pt <= 24; pt++) {
      final logicalIsTop = (pt >= 13 && pt <= 24);
      final isTop = flipped ? !logicalIsTop : logicalIsTop;
      final isEvenVisual = (flipped ? (25 - pt) : pt) % 2 == 0;
      final baseColor = isEvenVisual
          ? const Color(0xFFD7CCC8) // light
          : const Color(0xFFBF360C); // dark red

      Color color = baseColor;
      if (pt == selectedPoint) {
        color = highlightColor;
      } else if (validDests.contains(pt)) {
        color = destColor;
      } else if (combinedDests.contains(pt)) {
        color = combinedDestColor;
      } else if (opponentPreview != null &&
          opponentPreview!.moves.any((m) => m.from == pt || m.to == pt)) {
        final isTarget = opponentPreview!.moves.any((m) => m.to == pt);
        if (isTarget) {
          color = const Color(0xFF90CAF9).withValues(alpha: 0.7); // blue: destination
        } else {
          color = const Color(0xFFFFCC80).withValues(alpha: 0.7); // orange: source
        }
      } else if (lastMove?.checkerMoves.any((m) => m.from == pt || m.to == pt) ??
          false) {
        final isTarget = lastMove!.checkerMoves.any((m) => m.to == pt);
        if (isTarget) {
          color = const Color(0xFF90CAF9).withValues(alpha: 0.7); // blue: destination
        } else {
          color = const Color(0xFFFFCC80).withValues(alpha: 0.7); // orange: source
        }
      }

      _drawTriangle(canvas, _pointX(pt, w), isTop ? 0 : h, slotW, h * 0.42,
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
      final isTop = flipped ? !(pt >= 13 && pt <= 24) : (pt >= 13 && pt <= 24);
      final checkerR = w / 26;
      final count = p.count;

      // Compress spacing so all pieces fit within the triangle height
      final triangleH = h * 0.42;
      final idealSpacing = checkerR * 1.9;
      final maxSpacing = count > 1
          ? (triangleH - 2 * checkerR) / (count - 1)
          : idealSpacing;
      final spacing = math.min(idealSpacing, maxSpacing);

      for (int i = 0; i < count; i++) {
        final dy = isTop
            ? checkerR + i * spacing
            : h - checkerR - i * spacing;
        _drawChecker(canvas, Offset(cx, dy), checkerR, p.color!);
      }
    }
  }

  void _drawBarCheckers(Canvas canvas, double w, double h) {
    final barCx = w / 2;
    final r = w / 26;

    void drawBar(int count, BackgammonColor color, bool top, {required bool pulse}) {
      if (count == 0) return;
      final idealSpacing = r * 2.1;
      final maxSpacing = count > 1
          ? (h * 0.8 - 2 * r) / (count - 1)
          : idealSpacing;
      final spacing = math.min(idealSpacing, maxSpacing);
      for (int i = 0; i < count; i++) {
        final dy = top
            ? h * 0.1 + r + i * spacing
            : h * 0.9 - r - i * spacing;
        _drawChecker(canvas, Offset(barCx, dy), r, color,
            pulseRing: pulse ? pulseValue : null);
      }
    }

    // BLE game: pulse the local player's side. Pass-and-play: pulse active player.
    final effectiveColor = localColor ?? state.activeColor;
    drawBar(state.whiteBar, BackgammonColor.white, !flipped,
        pulse: effectiveColor == BackgammonColor.white);
    drawBar(state.blackBar, BackgammonColor.black, flipped,
        pulse: effectiveColor == BackgammonColor.black);
  }

  void _drawChecker(
      Canvas canvas, Offset center, double radius, BackgammonColor color,
      {double? pulseRing}) {
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
    if (pulseRing != null) {
      final ringRadius = radius * 1.15 + pulseRing * radius * 0.40;
      final opacity = (0.75 * math.sin(pulseRing * math.pi)).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.18
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.state != state ||
      old.selectedPoint != selectedPoint ||
      old.validDests != validDests ||
      old.combinedDests != combinedDests ||
      old.flipped != flipped ||
      old.lastMove != lastMove ||
      old.pulseValue != pulseValue ||
      old.localColor != localColor;
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