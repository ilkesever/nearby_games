import 'package:game_framework/game_framework.dart';
import 'chess_move.dart';

/// Represents the full state of a chess game.
class ChessState extends GameState {
  /// The board as a flat array of 64 squares (0=a8, 63=h1).
  final List<ChessPiece?> board;

  /// Whose turn it is.
  final ChessColor activeColor;

  /// Castling rights.
  final CastlingRights castlingRights;

  /// En passant target square index (or null).
  final int? enPassantTarget;

  /// Half-move clock for 50-move rule.
  final int halfMoveClock;

  /// Full move number.
  final int fullMoveNumber;

  /// Whether the game is in check.
  final bool isInCheck;

  /// Whether the game is over (checkmate or stalemate).
  final bool _isGameOver;

  /// Winner color (null if draw or ongoing).
  final ChessColor? winner;

  ChessState({
    required this.board,
    required this.activeColor,
    required this.castlingRights,
    this.enPassantTarget,
    this.halfMoveClock = 0,
    this.fullMoveNumber = 1,
    this.isInCheck = false,
    bool isGameOver = false,
    this.winner,
  }) : _isGameOver = isGameOver;

  /// Create the standard starting position.
  factory ChessState.initial() {
    final board = List<ChessPiece?>.filled(64, null);

    // Black pieces (row 0 = rank 8)
    board[0] = const ChessPiece(ChessPieceType.rook, ChessColor.black);
    board[1] = const ChessPiece(ChessPieceType.knight, ChessColor.black);
    board[2] = const ChessPiece(ChessPieceType.bishop, ChessColor.black);
    board[3] = const ChessPiece(ChessPieceType.queen, ChessColor.black);
    board[4] = const ChessPiece(ChessPieceType.king, ChessColor.black);
    board[5] = const ChessPiece(ChessPieceType.bishop, ChessColor.black);
    board[6] = const ChessPiece(ChessPieceType.knight, ChessColor.black);
    board[7] = const ChessPiece(ChessPieceType.rook, ChessColor.black);
    for (int i = 8; i < 16; i++) {
      board[i] = const ChessPiece(ChessPieceType.pawn, ChessColor.black);
    }

    // White pieces (row 7 = rank 1)
    board[56] = const ChessPiece(ChessPieceType.rook, ChessColor.white);
    board[57] = const ChessPiece(ChessPieceType.knight, ChessColor.white);
    board[58] = const ChessPiece(ChessPieceType.bishop, ChessColor.white);
    board[59] = const ChessPiece(ChessPieceType.queen, ChessColor.white);
    board[60] = const ChessPiece(ChessPieceType.king, ChessColor.white);
    board[61] = const ChessPiece(ChessPieceType.bishop, ChessColor.white);
    board[62] = const ChessPiece(ChessPieceType.knight, ChessColor.white);
    board[63] = const ChessPiece(ChessPieceType.rook, ChessColor.white);
    for (int i = 48; i < 56; i++) {
      board[i] = const ChessPiece(ChessPieceType.pawn, ChessColor.white);
    }

    return ChessState(
      board: board,
      activeColor: ChessColor.white,
      castlingRights: const CastlingRights(),
    );
  }

  /// Get the piece at a given index.
  ChessPiece? pieceAt(int index) =>
      index >= 0 && index < 64 ? board[index] : null;

  /// Get the piece at row, col.
  ChessPiece? pieceAtRowCol(int row, int col) =>
      pieceAt(row * 8 + col);

  /// Find the king position for a color.
  int findKing(ChessColor color) {
    for (int i = 0; i < 64; i++) {
      if (board[i]?.type == ChessPieceType.king && board[i]?.color == color) {
        return i;
      }
    }
    return -1; // Should never happen in a valid game
  }

  /// Create a copy with modifications.
  ChessState copyWith({
    List<ChessPiece?>? board,
    ChessColor? activeColor,
    CastlingRights? castlingRights,
    int? enPassantTarget,
    bool clearEnPassant = false,
    int? halfMoveClock,
    int? fullMoveNumber,
    bool? isInCheck,
    bool? isGameOver,
    ChessColor? winner,
    bool clearWinner = false,
  }) {
    return ChessState(
      board: board ?? List.from(this.board),
      activeColor: activeColor ?? this.activeColor,
      castlingRights: castlingRights ?? this.castlingRights,
      enPassantTarget:
          clearEnPassant ? null : (enPassantTarget ?? this.enPassantTarget),
      halfMoveClock: halfMoveClock ?? this.halfMoveClock,
      fullMoveNumber: fullMoveNumber ?? this.fullMoveNumber,
      isInCheck: isInCheck ?? this.isInCheck,
      isGameOver: isGameOver ?? _isGameOver,
      winner: clearWinner ? null : (winner ?? this.winner),
    );
  }

  // --- GameState interface ---

  @override
  int get activePlayerIndex => activeColor == ChessColor.white ? 0 : 1;

  @override
  bool get isGameOver => _isGameOver;

  @override
  int? get winnerIndex {
    if (winner == null) return null;
    return winner == ChessColor.white ? 0 : 1;
  }

  @override
  int get moveCount => (fullMoveNumber - 1) * 2 + (activeColor == ChessColor.black ? 1 : 0);

  @override
  Map<String, dynamic> toMap() => {
        'board': board.map((p) => p?.toMap()).toList(),
        'activeColor': activeColor.name,
        'castlingRights': castlingRights.toMap(),
        'enPassantTarget': enPassantTarget,
        'halfMoveClock': halfMoveClock,
        'fullMoveNumber': fullMoveNumber,
        'isInCheck': isInCheck,
        'isGameOver': _isGameOver,
        'winner': winner?.name,
      };

  factory ChessState.fromMap(Map<String, dynamic> map) {
    final boardList = (map['board'] as List).map((item) {
      if (item == null) return null;
      return ChessPiece.fromMap(Map<String, dynamic>.from(item as Map));
    }).toList();

    return ChessState(
      board: boardList,
      activeColor: ChessColor.values.byName(map['activeColor'] as String),
      castlingRights: CastlingRights.fromMap(
          Map<String, dynamic>.from(map['castlingRights'] as Map)),
      enPassantTarget: map['enPassantTarget'] as int?,
      halfMoveClock: map['halfMoveClock'] as int? ?? 0,
      fullMoveNumber: map['fullMoveNumber'] as int? ?? 1,
      isInCheck: map['isInCheck'] as bool? ?? false,
      isGameOver: map['isGameOver'] as bool? ?? false,
      winner: map['winner'] != null
          ? ChessColor.values.byName(map['winner'] as String)
          : null,
    );
  }
}

/// Castling rights for both sides.
class CastlingRights {
  final bool whiteKingSide;
  final bool whiteQueenSide;
  final bool blackKingSide;
  final bool blackQueenSide;

  const CastlingRights({
    this.whiteKingSide = true,
    this.whiteQueenSide = true,
    this.blackKingSide = true,
    this.blackQueenSide = true,
  });

  CastlingRights copyWith({
    bool? whiteKingSide,
    bool? whiteQueenSide,
    bool? blackKingSide,
    bool? blackQueenSide,
  }) =>
      CastlingRights(
        whiteKingSide: whiteKingSide ?? this.whiteKingSide,
        whiteQueenSide: whiteQueenSide ?? this.whiteQueenSide,
        blackKingSide: blackKingSide ?? this.blackKingSide,
        blackQueenSide: blackQueenSide ?? this.blackQueenSide,
      );

  Map<String, dynamic> toMap() => {
        'wk': whiteKingSide,
        'wq': whiteQueenSide,
        'bk': blackKingSide,
        'bq': blackQueenSide,
      };

  factory CastlingRights.fromMap(Map<String, dynamic> map) => CastlingRights(
        whiteKingSide: map['wk'] as bool? ?? false,
        whiteQueenSide: map['wq'] as bool? ?? false,
        blackKingSide: map['bk'] as bool? ?? false,
        blackQueenSide: map['bq'] as bool? ?? false,
      );
}
