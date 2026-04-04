enum BackgammonColor {
  white,
  black;

  BackgammonColor get opposite => this == white ? black : white;
}

class CheckerMove {
  final int from; // 1–24, or 0 = from bar
  final int to;   // 1–24, or 25 = bear off

  const CheckerMove({required this.from, required this.to});

  Map<String, dynamic> toMap() => {'from': from, 'to': to};

  factory CheckerMove.fromMap(Map<String, dynamic> map) =>
      CheckerMove(from: map['from'] as int, to: map['to'] as int);

  @override
  String toString() {
    final fromStr = from == 0 ? 'bar' : from.toString();
    final toStr = to == 25 ? 'off' : to.toString();
    return '$fromStr/$toStr';
  }

  @override
  bool operator ==(Object other) =>
      other is CheckerMove && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

class BackgammonMove {
  final List<int> dice;
  final List<CheckerMove> checkerMoves;

  const BackgammonMove({required this.dice, required this.checkerMoves});

  Map<String, dynamic> toMap() => {
        'dice': dice,
        'checkerMoves': checkerMoves.map((m) => m.toMap()).toList(),
      };

  factory BackgammonMove.fromMap(Map<String, dynamic> map) => BackgammonMove(
        dice: List<int>.from(map['dice'] as List),
        checkerMoves: (map['checkerMoves'] as List)
            .map((m) =>
                CheckerMove.fromMap(Map<String, dynamic>.from(m as Map)))
            .toList(),
      );

  @override
  String toString() => checkerMoves.map((m) => m.toString()).join(' ');
}