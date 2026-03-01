import 'package:chess/chess.dart' as chess_lib;
import 'package:game_framework/game_framework.dart';
import 'chess_move.dart';
import 'chess_state.dart';

/// Chess game engine — thin adapter over the `chess` package.
///
/// Delegates all rule logic (move validation, check/checkmate detection,
/// castling, en passant, promotion, draw rules) to the battle-tested
/// [chess](https://pub.dev/packages/chess) library (BSD-2 license).
///
/// This class bridges that library with our [GameEngine] framework interface,
/// converting between our [ChessState]/[ChessMove] types and the library's
/// internal representation via FEN strings.
class ChessEngine extends GameEngine<ChessState, ChessMove> {
  @override
  String get gameType => 'chess';

  @override
  String get gameName => 'Chess';

  @override
  ChessState get initialState => ChessState.initial();

  @override
  ChessState applyMove(ChessState state, ChessMove move) {
    final game = chess_lib.Chess.fromFEN(state.toFen());

    final success = game.move({
      'from': move.fromAlgebraic,
      'to': move.toAlgebraic,
      if (move.promotion != null)
        'promotion': _pieceTypeToFenChar(move.promotion!),
    });

    if (!success) {
      throw StateError('Invalid move: $move in state:\n${state.toFen()}');
    }

    return _stateFromChess(game);
  }

  @override
  bool isValidMove(ChessState state, ChessMove move) {
    final game = chess_lib.Chess.fromFEN(state.toFen());
    final legalMoves = game.generate_moves();

    return legalMoves.any((m) =>
        m.fromAlgebraic == move.fromAlgebraic &&
        m.toAlgebraic == move.toAlgebraic &&
        (move.promotion == null ||
            m.promotion?.name == _pieceTypeToFenChar(move.promotion!)));
  }

  @override
  List<ChessMove> getValidMoves(ChessState state) {
    final game = chess_lib.Chess.fromFEN(state.toFen());
    final legalMoves = game.generate_moves();
    return legalMoves.map(_libMoveToChessMove).toList();
  }

  /// Get valid moves for a specific square.
  List<ChessMove> getValidMovesFrom(ChessState state, int square) {
    return getValidMoves(state).where((m) => m.from == square).toList();
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
  // CONVERSION HELPERS
  // ==========================================================================

  /// Convert a chess library [chess_lib.Move] to our [ChessMove].
  static ChessMove _libMoveToChessMove(chess_lib.Move m) {
    return ChessMove(
      from: ChessMove.algebraicToIndex(m.fromAlgebraic),
      to: ChessMove.algebraicToIndex(m.toAlgebraic),
      promotion: m.promotion != null ? _fenCharToPieceType(m.promotion!.name) : null,
    );
  }

  /// Build a [ChessState] from the chess library's [chess_lib.Chess] instance.
  static ChessState _stateFromChess(chess_lib.Chess game) {
    final fen = game.fen;
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

    // Game status from the library
    final isInCheck = game.in_check;
    final isGameOver = game.game_over;
    ChessColor? winner;
    if (game.in_checkmate) {
      // The current player (whose turn it is) is checkmated — the other wins.
      winner = activeColor == ChessColor.white
          ? ChessColor.black
          : ChessColor.white;
    }

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

  /// Convert a FEN piece character to our [ChessPiece].
  static ChessPiece _fenCharToPiece(String ch) {
    final color = ch == ch.toUpperCase() ? ChessColor.white : ChessColor.black;
    final type = _fenCharToPieceType(ch.toLowerCase());
    return ChessPiece(type, color);
  }

  /// Convert a lowercase FEN piece character to our [ChessPieceType].
  static ChessPieceType _fenCharToPieceType(String ch) {
    return switch (ch) {
      'k' => ChessPieceType.king,
      'q' => ChessPieceType.queen,
      'r' => ChessPieceType.rook,
      'b' => ChessPieceType.bishop,
      'n' => ChessPieceType.knight,
      'p' => ChessPieceType.pawn,
      _ => throw ArgumentError('Unknown FEN piece: $ch'),
    };
  }

  /// Convert our [ChessPieceType] to FEN character (lowercase).
  static String _pieceTypeToFenChar(ChessPieceType type) {
    return switch (type) {
      ChessPieceType.king => 'k',
      ChessPieceType.queen => 'q',
      ChessPieceType.rook => 'r',
      ChessPieceType.bishop => 'b',
      ChessPieceType.knight => 'n',
      ChessPieceType.pawn => 'p',
    };
  }
}
