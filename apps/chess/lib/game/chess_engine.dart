import 'package:game_framework/game_framework.dart';
import 'chess_move.dart';
import 'chess_state.dart';

/// Chess game engine implementing all chess rules.
///
/// This is the concrete implementation of [GameEngine] for chess.
/// Handles move validation, check/checkmate, castling, en passant,
/// pawn promotion, and the 50-move draw rule.
class ChessEngine extends GameEngine<ChessState, ChessMove> {
  @override
  String get gameType => 'chess';

  @override
  String get gameName => 'Chess';

  @override
  ChessState get initialState => ChessState.initial();

  @override
  ChessState applyMove(ChessState state, ChessMove move) {
    final newBoard = List<ChessPiece?>.from(state.board);
    final piece = newBoard[move.from]!;
    final captured = newBoard[move.to];
    var newCastling = state.castlingRights;
    int? newEnPassant;
    var halfMoves = state.halfMoveClock + 1;
    var fullMoves = state.fullMoveNumber;

    // Reset half-move clock on pawn move or capture
    if (piece.type == ChessPieceType.pawn || captured != null) {
      halfMoves = 0;
    }

    // Handle en passant capture
    if (piece.type == ChessPieceType.pawn && move.to == state.enPassantTarget) {
      final capturedPawnIndex =
          move.to + (piece.color == ChessColor.white ? 8 : -8);
      newBoard[capturedPawnIndex] = null;
    }

    // Handle pawn double push (set en passant target)
    if (piece.type == ChessPieceType.pawn &&
        (move.fromRow - move.toRow).abs() == 2) {
      newEnPassant = (move.from + move.to) ~/ 2;
    }

    // Handle castling
    if (piece.type == ChessPieceType.king && (move.fromCol - move.toCol).abs() == 2) {
      if (move.toCol == 6) {
        // King-side castle
        newBoard[move.toRow * 8 + 5] = newBoard[move.toRow * 8 + 7];
        newBoard[move.toRow * 8 + 7] = null;
      } else if (move.toCol == 2) {
        // Queen-side castle
        newBoard[move.toRow * 8 + 3] = newBoard[move.toRow * 8 + 0];
        newBoard[move.toRow * 8 + 0] = null;
      }
    }

    // Update castling rights
    if (piece.type == ChessPieceType.king) {
      if (piece.color == ChessColor.white) {
        newCastling = newCastling.copyWith(
            whiteKingSide: false, whiteQueenSide: false);
      } else {
        newCastling = newCastling.copyWith(
            blackKingSide: false, blackQueenSide: false);
      }
    }
    if (piece.type == ChessPieceType.rook) {
      if (move.from == 63) newCastling = newCastling.copyWith(whiteKingSide: false);
      if (move.from == 56) newCastling = newCastling.copyWith(whiteQueenSide: false);
      if (move.from == 7) newCastling = newCastling.copyWith(blackKingSide: false);
      if (move.from == 0) newCastling = newCastling.copyWith(blackQueenSide: false);
    }
    // Rook captured
    if (move.to == 63) newCastling = newCastling.copyWith(whiteKingSide: false);
    if (move.to == 56) newCastling = newCastling.copyWith(whiteQueenSide: false);
    if (move.to == 7) newCastling = newCastling.copyWith(blackKingSide: false);
    if (move.to == 0) newCastling = newCastling.copyWith(blackQueenSide: false);

    // Move the piece
    newBoard[move.to] = piece;
    newBoard[move.from] = null;

    // Handle pawn promotion
    if (piece.type == ChessPieceType.pawn &&
        (move.toRow == 0 || move.toRow == 7)) {
      newBoard[move.to] = ChessPiece(
        move.promotion ?? ChessPieceType.queen,
        piece.color,
      );
    }

    // Switch turns
    final nextColor = state.activeColor.opposite;
    if (nextColor == ChessColor.white) {
      fullMoves++;
    }

    // Create new state
    var newState = ChessState(
      board: newBoard,
      activeColor: nextColor,
      castlingRights: newCastling,
      enPassantTarget: newEnPassant,
      halfMoveClock: halfMoves,
      fullMoveNumber: fullMoves,
    );

    // Check for check, checkmate, stalemate
    final inCheck = _isKingInCheck(newState, nextColor);
    final validMoves = _getAllValidMoves(newState);

    if (validMoves.isEmpty) {
      if (inCheck) {
        // Checkmate!
        newState = newState.copyWith(
          isInCheck: true,
          isGameOver: true,
          winner: state.activeColor,
        );
      } else {
        // Stalemate
        newState = newState.copyWith(
          isGameOver: true,
          clearWinner: true,
        );
      }
    } else {
      newState = newState.copyWith(isInCheck: inCheck);
    }

    // 50-move rule
    if (halfMoves >= 100) {
      newState = newState.copyWith(isGameOver: true, clearWinner: true);
    }

    return newState;
  }

  @override
  bool isValidMove(ChessState state, ChessMove move) {
    final piece = state.pieceAt(move.from);
    if (piece == null) return false;
    if (piece.color != state.activeColor) return false;

    final validMoves = getValidMoves(state);
    return validMoves.any((m) => m.from == move.from && m.to == move.to);
  }

  @override
  List<ChessMove> getValidMoves(ChessState state) {
    return _getAllValidMoves(state);
  }

  /// Get valid moves for a specific square.
  List<ChessMove> getValidMovesFrom(ChessState state, int square) {
    return _getAllValidMoves(state)
        .where((m) => m.from == square)
        .toList();
  }

  @override
  bool isGameOver(ChessState state) => state.isGameOver;

  @override
  GameResult? getResult(ChessState state) {
    if (!state.isGameOver) return null;
    if (state.winner == ChessColor.white) return GameResult.player0Wins;
    if (state.winner == ChessColor.black) return GameResult.player1Wins;
    return GameResult.draw;
  }

  @override
  Map<String, dynamic> serializeMove(ChessMove move) => move.toMap();

  @override
  ChessMove deserializeMove(Map<String, dynamic> map) => ChessMove.fromMap(map);

  @override
  Map<String, dynamic> serializeState(ChessState state) => state.toMap();

  @override
  ChessState deserializeState(Map<String, dynamic> map) =>
      ChessState.fromMap(map);

  // ==========================================================================
  // MOVE GENERATION
  // ==========================================================================

  List<ChessMove> _getAllValidMoves(ChessState state) {
    final moves = <ChessMove>[];
    final color = state.activeColor;

    for (int i = 0; i < 64; i++) {
      final piece = state.board[i];
      if (piece == null || piece.color != color) continue;

      final pseudoMoves = _getPseudoLegalMoves(state, i, piece);
      for (final move in pseudoMoves) {
        // Filter out moves that leave our king in check
        if (!_wouldLeaveKingInCheck(state, move)) {
          moves.add(move);
        }
      }
    }

    return moves;
  }

  List<ChessMove> _getPseudoLegalMoves(
      ChessState state, int square, ChessPiece piece) {
    switch (piece.type) {
      case ChessPieceType.pawn:
        return _getPawnMoves(state, square, piece.color);
      case ChessPieceType.knight:
        return _getKnightMoves(state, square, piece.color);
      case ChessPieceType.bishop:
        return _getSlidingMoves(state, square, piece.color, _bishopDirs);
      case ChessPieceType.rook:
        return _getSlidingMoves(state, square, piece.color, _rookDirs);
      case ChessPieceType.queen:
        return _getSlidingMoves(state, square, piece.color, _queenDirs);
      case ChessPieceType.king:
        return _getKingMoves(state, square, piece.color);
    }
  }

  static const _rookDirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];
  static const _bishopDirs = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
  static const _queenDirs = [
    [-1, 0], [1, 0], [0, -1], [0, 1],
    [-1, -1], [-1, 1], [1, -1], [1, 1],
  ];
  static const _knightOffsets = [
    [-2, -1], [-2, 1], [-1, -2], [-1, 2],
    [1, -2], [1, 2], [2, -1], [2, 1],
  ];

  List<ChessMove> _getPawnMoves(ChessState state, int square, ChessColor color) {
    final moves = <ChessMove>[];
    final row = square ~/ 8;
    final col = square % 8;
    final dir = color == ChessColor.white ? -1 : 1;
    final startRow = color == ChessColor.white ? 6 : 1;
    final promoRow = color == ChessColor.white ? 0 : 7;

    // Forward one
    final fwd = (row + dir) * 8 + col;
    if (_onBoard(row + dir, col) && state.board[fwd] == null) {
      if (row + dir == promoRow) {
        for (final promo in _promotionTypes) {
          moves.add(ChessMove(from: square, to: fwd, promotion: promo));
        }
      } else {
        moves.add(ChessMove(from: square, to: fwd));
      }

      // Forward two from start
      if (row == startRow) {
        final fwd2 = (row + dir * 2) * 8 + col;
        if (state.board[fwd2] == null) {
          moves.add(ChessMove(from: square, to: fwd2));
        }
      }
    }

    // Captures (including en passant)
    for (final dc in [-1, 1]) {
      final tr = row + dir;
      final tc = col + dc;
      if (!_onBoard(tr, tc)) continue;
      final target = tr * 8 + tc;
      final targetPiece = state.board[target];

      if (targetPiece != null && targetPiece.color != color) {
        if (tr == promoRow) {
          for (final promo in _promotionTypes) {
            moves.add(ChessMove(from: square, to: target, promotion: promo));
          }
        } else {
          moves.add(ChessMove(from: square, to: target));
        }
      }

      // En passant
      if (target == state.enPassantTarget) {
        moves.add(ChessMove(from: square, to: target));
      }
    }

    return moves;
  }

  static const _promotionTypes = [
    ChessPieceType.queen,
    ChessPieceType.rook,
    ChessPieceType.bishop,
    ChessPieceType.knight,
  ];

  List<ChessMove> _getKnightMoves(
      ChessState state, int square, ChessColor color) {
    final moves = <ChessMove>[];
    final row = square ~/ 8;
    final col = square % 8;

    for (final offset in _knightOffsets) {
      final tr = row + offset[0];
      final tc = col + offset[1];
      if (!_onBoard(tr, tc)) continue;
      final target = tr * 8 + tc;
      final targetPiece = state.board[target];
      if (targetPiece == null || targetPiece.color != color) {
        moves.add(ChessMove(from: square, to: target));
      }
    }

    return moves;
  }

  List<ChessMove> _getSlidingMoves(
      ChessState state, int square, ChessColor color, List<List<int>> dirs) {
    final moves = <ChessMove>[];
    final row = square ~/ 8;
    final col = square % 8;

    for (final dir in dirs) {
      var r = row + dir[0];
      var c = col + dir[1];
      while (_onBoard(r, c)) {
        final target = r * 8 + c;
        final targetPiece = state.board[target];
        if (targetPiece == null) {
          moves.add(ChessMove(from: square, to: target));
        } else {
          if (targetPiece.color != color) {
            moves.add(ChessMove(from: square, to: target));
          }
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    return moves;
  }

  List<ChessMove> _getKingMoves(
      ChessState state, int square, ChessColor color) {
    final moves = <ChessMove>[];
    final row = square ~/ 8;
    final col = square % 8;

    // Normal king moves
    for (final dir in _queenDirs) {
      final tr = row + dir[0];
      final tc = col + dir[1];
      if (!_onBoard(tr, tc)) continue;
      final target = tr * 8 + tc;
      final targetPiece = state.board[target];
      if (targetPiece == null || targetPiece.color != color) {
        moves.add(ChessMove(from: square, to: target));
      }
    }

    // Castling
    if (!_isKingInCheck(state, color)) {
      final cr = state.castlingRights;

      if (color == ChessColor.white) {
        // White king-side (e1 -> g1)
        if (cr.whiteKingSide &&
            state.board[61] == null &&
            state.board[62] == null &&
            !_isSquareAttacked(state, 61, ChessColor.black) &&
            !_isSquareAttacked(state, 62, ChessColor.black)) {
          moves.add(ChessMove(from: 60, to: 62));
        }
        // White queen-side (e1 -> c1)
        if (cr.whiteQueenSide &&
            state.board[59] == null &&
            state.board[58] == null &&
            state.board[57] == null &&
            !_isSquareAttacked(state, 59, ChessColor.black) &&
            !_isSquareAttacked(state, 58, ChessColor.black)) {
          moves.add(ChessMove(from: 60, to: 58));
        }
      } else {
        // Black king-side (e8 -> g8)
        if (cr.blackKingSide &&
            state.board[5] == null &&
            state.board[6] == null &&
            !_isSquareAttacked(state, 5, ChessColor.white) &&
            !_isSquareAttacked(state, 6, ChessColor.white)) {
          moves.add(ChessMove(from: 4, to: 6));
        }
        // Black queen-side (e8 -> c8)
        if (cr.blackQueenSide &&
            state.board[3] == null &&
            state.board[2] == null &&
            state.board[1] == null &&
            !_isSquareAttacked(state, 3, ChessColor.white) &&
            !_isSquareAttacked(state, 2, ChessColor.white)) {
          moves.add(ChessMove(from: 4, to: 2));
        }
      }
    }

    return moves;
  }

  // ==========================================================================
  // CHECK DETECTION
  // ==========================================================================

  bool _isKingInCheck(ChessState state, ChessColor color) {
    final kingPos = state.findKing(color);
    if (kingPos == -1) return false;
    return _isSquareAttacked(state, kingPos, color.opposite);
  }

  bool _isSquareAttacked(ChessState state, int square, ChessColor byColor) {
    final row = square ~/ 8;
    final col = square % 8;

    // Check for pawn attacks
    final pawnDir = byColor == ChessColor.white ? 1 : -1;
    for (final dc in [-1, 1]) {
      final pr = row + pawnDir;
      final pc = col + dc;
      if (_onBoard(pr, pc)) {
        final piece = state.board[pr * 8 + pc];
        if (piece?.type == ChessPieceType.pawn && piece?.color == byColor) {
          return true;
        }
      }
    }

    // Check for knight attacks
    for (final offset in _knightOffsets) {
      final nr = row + offset[0];
      final nc = col + offset[1];
      if (_onBoard(nr, nc)) {
        final piece = state.board[nr * 8 + nc];
        if (piece?.type == ChessPieceType.knight && piece?.color == byColor) {
          return true;
        }
      }
    }

    // Check for sliding attacks (bishop, rook, queen)
    for (final dir in _bishopDirs) {
      var r = row + dir[0];
      var c = col + dir[1];
      while (_onBoard(r, c)) {
        final piece = state.board[r * 8 + c];
        if (piece != null) {
          if (piece.color == byColor &&
              (piece.type == ChessPieceType.bishop ||
                  piece.type == ChessPieceType.queen)) {
            return true;
          }
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    for (final dir in _rookDirs) {
      var r = row + dir[0];
      var c = col + dir[1];
      while (_onBoard(r, c)) {
        final piece = state.board[r * 8 + c];
        if (piece != null) {
          if (piece.color == byColor &&
              (piece.type == ChessPieceType.rook ||
                  piece.type == ChessPieceType.queen)) {
            return true;
          }
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    // Check for king attacks (adjacent squares)
    for (final dir in _queenDirs) {
      final kr = row + dir[0];
      final kc = col + dir[1];
      if (_onBoard(kr, kc)) {
        final piece = state.board[kr * 8 + kc];
        if (piece?.type == ChessPieceType.king && piece?.color == byColor) {
          return true;
        }
      }
    }

    return false;
  }

  bool _wouldLeaveKingInCheck(ChessState state, ChessMove move) {
    // Simulate the move
    final newBoard = List<ChessPiece?>.from(state.board);
    final piece = newBoard[move.from]!;

    // Handle en passant
    if (piece.type == ChessPieceType.pawn && move.to == state.enPassantTarget) {
      final capturedPawnIndex =
          move.to + (piece.color == ChessColor.white ? 8 : -8);
      newBoard[capturedPawnIndex] = null;
    }

    // Handle castling rook move
    if (piece.type == ChessPieceType.king &&
        (move.fromCol - move.toCol).abs() == 2) {
      if (move.toCol == 6) {
        newBoard[move.toRow * 8 + 5] = newBoard[move.toRow * 8 + 7];
        newBoard[move.toRow * 8 + 7] = null;
      } else if (move.toCol == 2) {
        newBoard[move.toRow * 8 + 3] = newBoard[move.toRow * 8 + 0];
        newBoard[move.toRow * 8 + 0] = null;
      }
    }

    newBoard[move.to] = piece;
    newBoard[move.from] = null;

    final tempState = state.copyWith(board: newBoard);
    return _isKingInCheck(tempState, state.activeColor);
  }

  bool _onBoard(int row, int col) =>
      row >= 0 && row < 8 && col >= 0 && col < 8;
}
