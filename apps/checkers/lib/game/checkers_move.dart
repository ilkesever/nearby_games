/// A single checkers move, expressed as a from/to pair using the
/// international draughts square numbering (1–50).
class CheckersMove {
  /// Source square (1–50).
  final int from;

  /// Destination square (1–50).
  final int to;

  /// Full path of squares the piece visits, including [from] and [to].
  /// Length 2 = simple move or single capture. Length > 2 = multi-jump.
  /// Used by the UI for step-by-step path display; the engine only needs from/to.
  final List<int> jumps;

  CheckersMove({
    required this.from,
    required this.to,
    List<int>? jumps,
  }) : jumps = jumps ?? [from, to];

  /// True if this move involves more than one jump (multi-jump capture).
  bool get isMultiJump => jumps.length > 2;

  Map<String, dynamic> toMap() => {'from': from, 'to': to, 'jumps': jumps};

  factory CheckersMove.fromMap(Map<String, dynamic> map) {
    final from = map['from'] as int;
    final to = map['to'] as int;
    final raw = map['jumps'];
    return CheckersMove(
      from: from,
      to: to,
      jumps: raw != null ? List<int>.from(raw as List) : [from, to],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CheckersMove && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => jumps.join('→');
}
