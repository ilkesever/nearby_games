/// Represents a chess move.
class ChessMove {
  /// Starting position (e.g., 0-63, where 0 = a8, 63 = h1).
  final int from;

  /// Destination position.
  final int to;

  /// Promotion piece type (if pawn reaches last rank).
  final ChessPieceType? promotion;

  const ChessMove({
    required this.from,
    required this.to,
    this.promotion,
  });

  /// Create from algebraic notation like "e2" -> row/col.
  factory ChessMove.fromAlgebraic(String fromSq, String toSq,
      {ChessPieceType? promotion}) {
    return ChessMove(
      from: algebraicToIndex(fromSq),
      to: algebraicToIndex(toSq),
      promotion: promotion,
    );
  }

  /// Get algebraic notation for the from-square.
  String get fromAlgebraic => indexToAlgebraic(from);

  /// Get algebraic notation for the to-square.
  String get toAlgebraic => indexToAlgebraic(to);

  int get fromRow => from ~/ 8;
  int get fromCol => from % 8;
  int get toRow => to ~/ 8;
  int get toCol => to % 8;

  Map<String, dynamic> toMap() => {
        'from': from,
        'to': to,
        if (promotion != null) 'promotion': promotion!.name,
      };

  factory ChessMove.fromMap(Map<String, dynamic> map) => ChessMove(
        from: map['from'] as int,
        to: map['to'] as int,
        promotion: map['promotion'] != null
            ? ChessPieceType.values.byName(map['promotion'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChessMove &&
          from == other.from &&
          to == other.to &&
          promotion == other.promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() => '$fromAlgebraic→$toAlgebraic';

  /// Convert algebraic notation (e.g. "e2") to board index (0-63).
  static int algebraicToIndex(String sq) {
    final col = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(sq[1]);
    return row * 8 + col;
  }

  /// Convert board index (0-63) to algebraic notation (e.g. "e2").
  static String indexToAlgebraic(int index) {
    final col = String.fromCharCode('a'.codeUnitAt(0) + (index % 8));
    final row = 8 - (index ~/ 8);
    return '$col$row';
  }
}

/// Types of chess pieces.
enum ChessPieceType {
  king,
  queen,
  rook,
  bishop,
  knight,
  pawn,
}

/// A chess piece with color.
class ChessPiece {
  final ChessPieceType type;
  final ChessColor color;

  const ChessPiece(this.type, this.color);

  /// Unicode character for this piece.
  String get symbol {
    const symbols = {
      (ChessPieceType.king, ChessColor.white): '♔',
      (ChessPieceType.queen, ChessColor.white): '♕',
      (ChessPieceType.rook, ChessColor.white): '♖',
      (ChessPieceType.bishop, ChessColor.white): '♗',
      (ChessPieceType.knight, ChessColor.white): '♘',
      (ChessPieceType.pawn, ChessColor.white): '♙',
      (ChessPieceType.king, ChessColor.black): '♚',
      (ChessPieceType.queen, ChessColor.black): '♛',
      (ChessPieceType.rook, ChessColor.black): '♜',
      (ChessPieceType.bishop, ChessColor.black): '♝',
      (ChessPieceType.knight, ChessColor.black): '♞',
      (ChessPieceType.pawn, ChessColor.black): '♟',
    };
    return symbols[(type, color)]!;
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'color': color.name,
      };

  factory ChessPiece.fromMap(Map<String, dynamic> map) => ChessPiece(
        ChessPieceType.values.byName(map['type'] as String),
        ChessColor.values.byName(map['color'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChessPiece && type == other.type && color == other.color;

  @override
  int get hashCode => Object.hash(type, color);
}

/// Chess piece colors.
enum ChessColor {
  white,
  black;

  ChessColor get opposite =>
      this == ChessColor.white ? ChessColor.black : ChessColor.white;
}
