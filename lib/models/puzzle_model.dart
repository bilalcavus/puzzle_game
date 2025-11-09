import 'tile_model.dart';

class PuzzleModel {
  const PuzzleModel({required this.size, required this.tiles});

  final int size;
  final List<TileModel> tiles;

  TileModel get emptyTile => tiles.firstWhere((tile) => tile.isEmpty);

  bool get isSolved => tiles.every((tile) => tile.isEmpty || tile.isInCorrectPosition);

  TileModel tileByValue(int value) => tiles.firstWhere((tile) => tile.value == value);

  bool canMove(TileModel tile) {
    if (tile.isEmpty) return false;
    final empty = emptyTile;
    final sameRow = tile.currentRow == empty.currentRow && (tile.currentCol - empty.currentCol).abs() == 1;
    final sameCol = tile.currentCol == empty.currentCol && (tile.currentRow - empty.currentRow).abs() == 1;
    return sameRow || sameCol;
  }

  PuzzleModel moveTile(TileModel tile) {
    if (!canMove(tile)) return this;
    final empty = emptyTile;
    final updatedTiles = List<TileModel>.from(tiles);
    final tileIndex = updatedTiles.indexWhere((element) => element.id == tile.id);
    final emptyIndex = updatedTiles.indexWhere((element) => element.id == empty.id);

    updatedTiles[tileIndex] = tile.copyWith(currentRow: empty.currentRow, currentCol: empty.currentCol);
    updatedTiles[emptyIndex] = empty.copyWith(currentRow: tile.currentRow, currentCol: tile.currentCol);

    return PuzzleModel(size: size, tiles: updatedTiles);
  }

  PuzzleModel copyWith({List<TileModel>? tiles}) {
    return PuzzleModel(size: size, tiles: tiles ?? this.tiles);
  }

  factory PuzzleModel.empty(int size) {
    final total = size * size;
    final solvedSequence = List<int>.generate(total, (index) => (index + 1) % total);
    return PuzzleModel.fromSequence(size: size, sequence: solvedSequence);
  }

  factory PuzzleModel.fromSequence({required int size, required List<int> sequence}) {
    final tiles = <TileModel>[];
    for (var index = 0; index < sequence.length; index++) {
      final value = sequence[index];
      final currentRow = index ~/ size;
      final currentCol = index % size;
      final total = size * size;
      final correctIndex = value == 0 ? total - 1 : value - 1;
      final correctRow = correctIndex ~/ size;
      final correctCol = correctIndex % size;
      tiles.add(
        TileModel(
          id: index,
          value: value,
          correctRow: correctRow,
          correctCol: correctCol,
          currentRow: currentRow,
          currentCol: currentCol,
        ),
      );
    }
    return PuzzleModel(size: size, tiles: tiles);
  }
}
