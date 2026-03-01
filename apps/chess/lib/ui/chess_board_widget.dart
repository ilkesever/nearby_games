import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../game/chess_engine.dart';
import '../game/chess_move.dart';
import '../game/chess_state.dart';

/// Returns the asset path for a chess piece SVG.
String _pieceAssetPath(ChessPiece piece) {
  final colorPrefix = piece.color == ChessColor.white ? 'w' : 'b';
  final typeChar = switch (piece.type) {
    ChessPieceType.king => 'K',
    ChessPieceType.queen => 'Q',
    ChessPieceType.rook => 'R',
    ChessPieceType.bishop => 'B',
    ChessPieceType.knight => 'N',
    ChessPieceType.pawn => 'P',
  };
  return 'assets/pieces/$colorPrefix$typeChar.svg';
}

/// Interactive chess board widget.
///
/// Renders the 8x8 board with pieces and handles tap-based move input.
/// Highlights selected piece, valid move targets, and last move.
class ChessBoardWidget extends StatefulWidget {
  /// Current chess state to render.
  final ChessState state;

  /// The chess engine (for move validation/highlighting).
  final ChessEngine engine;

  /// Whether the board is interactive (it's our turn).
  final bool interactive;

  /// Whether to flip the board (black perspective).
  final bool flipped;

  /// Called when the player makes a valid move.
  final void Function(ChessMove move)? onMove;

  /// The last move made (for highlighting).
  final ChessMove? lastMove;

  const ChessBoardWidget({
    super.key,
    required this.state,
    required this.engine,
    this.interactive = true,
    this.flipped = false,
    this.onMove,
    this.lastMove,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  int? _selectedSquare;
  List<ChessMove> _validMovesFromSelected = [];

  @override
  void didUpdateWidget(ChessBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear selection when state changes (after a move)
    if (oldWidget.state != widget.state) {
      _selectedSquare = null;
      _validMovesFromSelected = [];
    }
  }

  void _onSquareTapped(int square) {
    if (!widget.interactive) return;

    final piece = widget.state.pieceAt(square);

    if (_selectedSquare != null) {
      // Try to make a move to the tapped square
      final move = _validMovesFromSelected.where((m) => m.to == square);

      if (move.isNotEmpty) {
        // Check if this is a promotion move
        final promoMoves = move.where((m) => m.promotion != null).toList();
        if (promoMoves.isNotEmpty) {
          _showPromotionDialog(square, promoMoves);
        } else {
          widget.onMove?.call(move.first);
        }
        setState(() {
          _selectedSquare = null;
          _validMovesFromSelected = [];
        });
        return;
      }

      // Tapped on own piece — reselect
      if (piece != null && piece.color == widget.state.activeColor) {
        setState(() {
          _selectedSquare = square;
          _validMovesFromSelected =
              widget.engine.getValidMovesFrom(widget.state, square);
        });
        return;
      }

      // Tapped elsewhere — deselect
      setState(() {
        _selectedSquare = null;
        _validMovesFromSelected = [];
      });
      return;
    }

    // No piece selected — select if it's our piece
    if (piece != null && piece.color == widget.state.activeColor) {
      setState(() {
        _selectedSquare = square;
        _validMovesFromSelected =
            widget.engine.getValidMovesFrom(widget.state, square);
      });
    }
  }

  void _showPromotionDialog(int toSquare, List<ChessMove> promoMoves) {
    final color = widget.state.activeColor;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote pawn to:'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final type in [
              ChessPieceType.queen,
              ChessPieceType.rook,
              ChessPieceType.bishop,
              ChessPieceType.knight,
            ])
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  final move =
                      promoMoves.firstWhere((m) => m.promotion == type);
                  widget.onMove?.call(move);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    _pieceAssetPath(ChessPiece(type, color)),
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown[800]!, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: List.generate(8, (visualRow) {
            final row = widget.flipped ? (7 - visualRow) : visualRow;
            return Expanded(
              child: Row(
                children: List.generate(8, (visualCol) {
                  final col = widget.flipped ? (7 - visualCol) : visualCol;
                  final index = row * 8 + col;
                  return Expanded(
                    child: _buildSquare(index, row, col),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSquare(int index, int row, int col) {
    final piece = widget.state.board[index];
    final isLight = (row + col) % 2 == 0;
    final isSelected = _selectedSquare == index;
    final isValidTarget =
        _validMovesFromSelected.any((m) => m.to == index);
    final isLastMoveFrom = widget.lastMove?.from == index;
    final isLastMoveTo = widget.lastMove?.to == index;
    final isKingInCheck = widget.state.isInCheck &&
        piece?.type == ChessPieceType.king &&
        piece?.color == widget.state.activeColor;

    Color bgColor;
    if (isKingInCheck) {
      bgColor = Colors.red[400]!;
    } else if (isSelected) {
      bgColor = Colors.yellow[300]!;
    } else if (isLastMoveFrom || isLastMoveTo) {
      bgColor = isLight ? Colors.yellow[100]! : Colors.yellow[700]!;
    } else {
      bgColor = isLight
          ? const Color(0xFFF0D9B5)
          : const Color(0xFFB58863);
    }

    return GestureDetector(
      onTap: () => _onSquareTapped(index),
      child: Container(
        color: bgColor,
        child: Stack(
          children: [
            // Piece
            if (piece != null)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: SvgPicture.asset(
                    _pieceAssetPath(piece),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            // Valid move indicator (drawn on top of pieces)
            if (isValidTarget)
              Center(
                child: piece != null
                    ? FractionallySizedBox(
                        widthFactor: 0.85,
                        heightFactor: 0.85,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.4),
                              width: 3,
                            ),
                          ),
                        ),
                      )
                    : FractionallySizedBox(
                        widthFactor: 0.3,
                        heightFactor: 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
              ),

            // Coordinate labels (a-h, 1-8)
            if (col == 0)
              Positioned(
                top: 2,
                left: 2,
                child: Text(
                  '${8 - row}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isLight ? const Color(0xFFB58863) : const Color(0xFFF0D9B5),
                  ),
                ),
              ),
            if (row == 7)
              Positioned(
                bottom: 1,
                right: 2,
                child: Text(
                  String.fromCharCode('a'.codeUnitAt(0) + col),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isLight ? const Color(0xFFB58863) : const Color(0xFFF0D9B5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
