class TileModel {
  const TileModel({
    required this.id,
    required this.value,
    required this.correctRow,
    required this.correctCol,
    required this.currentRow,
    required this.currentCol,
  });

  final int id;
  final int value;
  final int correctRow;
  final int correctCol;
  final int currentRow;
  final int currentCol;

  bool get isInCorrectPosition => currentRow == correctRow && currentCol == correctCol;
  bool get isEmpty => value == 0;

  TileModel copyWith({
    int? currentRow,
    int? currentCol,
  }) {
    return TileModel(
      id: id,
      value: value,
      correctRow: correctRow,
      correctCol: correctCol,
      currentRow: currentRow ?? this.currentRow,
      currentCol: currentCol ?? this.currentCol,
    );
  }
}
