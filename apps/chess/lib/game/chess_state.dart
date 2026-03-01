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

  /// Convert this state to a FEN string (for interop with the chess library).
  String toFen() {
    final sb = StringBuffer();

    // Board (rank 8 to rank 1, which matches our row 0 to row 7)
    for (int row = 0; row < 8; row++) {
      int empty = 0;
      for (int col = 0; col < 8; col++) {
        final piece = board[row * 8 + col];
        if (piece == null) {
          empty++;
        } else {
          if (empty > 0) {
            sb.write(empty);
            empty = 0;
          }
          sb.write(_pieceToFenChar(piece));
        }
      }
      if (empty > 0) sb.write(empty);
      if (row < 7) sb.write('/');
    }

    // Active color
    sb.write(' ');
    sb.write(activeColor == ChessColor.white ? 'w' : 'b');

    // Castling rights
    sb.write(' ');
    final c = StringBuffer();
    if (castlingRights.whiteKingSide) c.write('K');
    if (castlingRights.whiteQueenSide) c.write('Q');
    if (castlingRights.blackKingSide) c.write('k');
    if (castlingRights.blackQueenSide) c.write('q');
    sb.write(c.isEmpty ? '-' : c.toString());

    // En passant target
    sb.write(' ');
    if (enPassantTarget != null) {
      sb.write(ChessMove.indexToAlgebraic(enPassantTarget!));
    } else {
      sb.write('-');
    }

    // Half-move clock and full-move number
    sb.write(' $halfMoveClock');
    sb.write(' $fullMoveNumber');

    return sb.toString();
  }

  static String _pieceToFenChar(ChessPiece piece) {
    const map = {
      ChessPieceType.king: 'k',
      ChessPieceType.queen: 'q',
      ChessPieceType.rook: 'r',
      ChessPieceType.bishop: 'b',
      ChessPieceType.knight: 'n',
      ChessPieceType.pawn: 'p',
    };
    final ch = map[piece.type]!;
    return piece.color == ChessColor.white ? ch.toUpperCase() : ch;
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
        'fen': toFen(),
        'isInCheck': isInCheck,
        'isGameOver': _isGameOver,
        'winner': winner?.name,
      };

  /// Create a [ChessState] from a FEN string plus game metadata.
  factory ChessState.fromFen(
    String fen, {
    bool isInCheck = false,
    bool isGameOver = false,
    ChessColor? winner,
  }) {
    final parts = fen.split(' ');

    // Parse board
    final board = _parseFenBoard(parts[0]);

    // Active color
    final activeColor =
        parts[1] == 'w' ? ChessColor.white : ChessColor.black;

    // Castling rights
    final castlingStr = parts[2];
    final castlingRights = CastlingRights(
      whiteKingSide: castlingStr.contains('K'),
      whiteQueenSide: castlingStr.contains('Q'),
      blackKingSide: castlingStr.contains('k'),
      blackQueenSide: castlingStr.contains('q'),
    );

    // En passant target
    int? enPassantTarget;
    if (parts[3] != '-') {
      enPassantTarget = ChessMove.algebraicToIndex(parts[3]);
    }

    // Clocks
    final halfMoveClock = int.parse(parts[4]);
    final fullMoveNumber = int.parse(parts[5]);

    return ChessState(
      board: board,
      activeColor: activeColor,
      castlingRights: castlingRights,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
      isInCheck: isInCheck,
      isGameOver: isGameOver,
      winner: winner,
    );
  }

  /// Parse the board portion of a FEN string into our 64-square array.
  static List<ChessPiece?> _parseFenBoard(String boardStr) {
    final board = List<ChessPiece?>.filled(64, null);
    final rows = boardStr.split('/');

    for (int row = 0; row < 8; row++) {
      int col = 0;
      for (int i = 0; i < rows[row].length; i++) {
        final ch = rows[row][i];
        final digit = int.tryParse(ch);
        if (digit != null) {
          col += digit;
        } else {
          board[row * 8 + col] = _fenCharToPiece(ch);
          col++;
        }
      }
    }

    return board;
  }

  /// Convert a FEN piece character to a [ChessPiece].
  static ChessPiece _fenCharToPiece(String ch) {
    final color = ch == ch.toUpperCase() ? ChessColor.white : ChessColor.black;
    const typeMap = {
      'k': ChessPieceType.king,
      'q': ChessPieceType.queen,
      'r': ChessPieceType.rook,
      'b': ChessPieceType.bishop,
      'n': ChessPieceType.knight,
      'p': ChessPieceType.pawn,
    };
    final type = typeMap[ch.toLowerCase()]!;
    return ChessPiece(type, color);
  }

  factory ChessState.fromMap(Map<String, dynamic> map) {
    // Compact FEN-based format
    if (map.containsKey('fen')) {
      return ChessState.fromFen(
        map['fen'] as String,
        isInCheck: map['isInCheck'] as bool? ?? false,
        isGameOver: map['isGameOver'] as bool? ?? false,
        winner: map['winner'] != null
            ? ChessColor.values.byName(map['winner'] as String)
            : null,
      );
    }

    // Legacy verbose format (backward compatibility)
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
