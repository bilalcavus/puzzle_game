import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/block_model.dart';
import '../../models/piece_model.dart';

final _random = Random();

int _normalizeCount(int count) => count < 1 ? 1 : (count > 6 ? 6 : count);

// Default vivid yet soft puzzle palette (distinct, non-clashing hues).
const _palette = [
  Color.fromARGB(255, 199, 118, 4), // mavi (koyu)
  Color(0xFFF67C1F), // turuncu
  Color.fromARGB(255, 76, 215, 104), // yeşil
  Color(0xFF9C4DFF), // mor
  Color(0xFFF4C542), // sarı
];

final List<List<List<int>>> _shapes = [
  // Single block
  [
    [0, 0],
  ],
  // Two line horizontal
  [
    [0, 0],
    [0, 1],
  ],
  // Three line horizontal
  [
    [0, 0],
    [0, 1],
    [0, 2],
  ],
  // Three vertical
  [
    [0, 0],
    [1, 0],
    [2, 0],
  ],
  // Square 2x2
  [
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1],
  ],
  // L shape
  [
    [0, 0],
    [1, 0],
    [2, 0],
    [2, 1],
  ],
  // T shape
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 1],
  ],
  // Long 4 horizontal
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [0, 3],
  ],
  // Long 4 vertical
  [
    [0, 0],
    [1, 0],
    [2, 0],
    [3, 0],
  ],
  // Z shape
  [
    [0, 0],
    [0, 1],
    [1, 1],
    [1, 2],
  ],
  //Horizontal T shape
  [
    [0, 0],
    [1, 0],
    [1, 1],
    [2, 0],
  ],
  //Short-horizontal L shape
  [
    [0, 0],
    [1, 0],
    [1, 1],
  ],
  // Full 3x3 square
  [
    [0, 0],
    [0, 1],
    [0, 2],
    [1, 0],
    [1, 1],
    [1, 2],
    [2, 0],
    [2, 1],
    [2, 2],
  ],
  //vertical two line
  [
    [0, 0],
    [1, 0],
  ]
  
];

const List<int> _easyShapeIndices = [0, 1, 2, 3, 4];
const _singleBlockShapeIndex = 0;

class _Placement {
  const _Placement({
    required this.row,
    required this.col,
    required this.linesCleared,
    required this.adjacency,
    required this.cavityCovered,
    required this.clusterCount,
    required this.largestCluster,
    required this.score,
    required this.nextFilled,
  });

  final int row;
  final int col;
  final int linesCleared;
  final int adjacency;
  final int cavityCovered;
  final int clusterCount;
  final int largestCluster;
  final int score;
  final Map<int, Color> nextFilled;
}

class _ShapeFit {
  const _ShapeFit({
    required this.shape,
    required this.totalPlacements,
    required this.placements,
    required this.bestScore,
  });

  final List<List<int>> shape;
  final int totalPlacements;
  final List<_Placement> placements;
  final int bestScore;
}

const int _maxPlacementsPerShape = 10;
const int _cavityNeighborThreshold = 2;
const int _lineShapePenalty = 18;

class _SearchBudget {
  _SearchBudget(this.remaining);

  int remaining;

  bool take() {
    if (remaining <= 0) return false;
    remaining -= 1;
    return true;
  }
}

List<PieceModel> generateRandomPieces({int count = 3, double easyBias = 0.65, int? maxWidth, int? maxHeight, List<List<List<int>>> preferredShapes = const [], bool uniqueShapes = false}) {
  final target = _normalizeCount(count);
  final pieces = <PieceModel>[];
  final filteredShapes = _filterShapes(maxWidth: maxWidth, maxHeight: maxHeight);
  final hasPreferred = preferredShapes.isNotEmpty;
  final shapePool = (hasPreferred ? preferredShapes : filteredShapes).isEmpty ? _shapes : (hasPreferred ? preferredShapes : filteredShapes);
  final easyPool = shapePool.where(_isEasyShape).toList().isEmpty ? shapePool : shapePool.where(_isEasyShape).toList();
  final usedKeys = uniqueShapes ? <String>{} : null;

  // At least one easy shape, optionally more based on bias.
  final easyCount = max(1, (target * easyBias).round());
  for (var i = 0; i < easyCount && pieces.length < target; i++) {
    final easyShape = _pickShape(easyPool, usedKeys);
    if (easyShape != null) {
      pieces.add(_createRandomPiece(easyShape));
    }
  }
  while (pieces.length < target) {
    final shape = _pickShape(shapePool, usedKeys);
    if (shape == null) break;
    pieces.add(_createRandomPiece(shape));
  }
  if (pieces.isEmpty && shapePool.isNotEmpty) {
    pieces.add(_createRandomPiece(shapePool.first));
  }
  pieces.shuffle(_random);
  return pieces;
}

List<PieceModel> generatePlayablePieces({required int boardSize, required Map<int, Color> filledCells, int count = 3, int maxAttempts = 32, double easyBias = 0.65}) {
  final targetCount = _normalizeCount(count);
  final attemptLimit = max(6, maxAttempts);
  final shapes = _findPlayableShapeSet(
    boardSize: boardSize,
    filledCells: filledCells,
    targetCount: targetCount,
    easyBias: easyBias,
    maxNodes: attemptLimit * 120,
  );
  if (shapes.isNotEmpty) {
    final pieces = shapes.map(_createRandomPiece).toList();
    pieces.shuffle(_random);
    return pieces;
  }

  final fits = _shapeFits(boardSize: boardSize, filledCells: filledCells);
  if (fits.isEmpty) {
    final fallback = <PieceModel>[];
    if (targetCount > 1) {
      fallback.addAll(generateRandomPieces(count: targetCount - 1, easyBias: easyBias));
    }
    fallback.add(_createRandomPiece(_shapes[_singleBlockShapeIndex]));
    return fallback;
  }

  final easyFits = fits.where((fit) => _isEasyShape(fit.shape)).toList();
  final pieces = <PieceModel>[];
  final usedKeys = <String>{};
  final hasCavities = _cavityCells(boardSize, filledCells).isNotEmpty;
  final easyTarget = easyFits.isEmpty
      ? 0
      : hasCavities
          ? 0
          : min(targetCount, max(1, (targetCount * easyBias).round()));

  for (var i = 0; i < targetCount; i++) {
    final wantsEasy = i < easyTarget;
    var pick = _pickWeightedShape(wantsEasy ? easyFits : fits, usedKeys);
    pick ??= _pickWeightedShape(wantsEasy ? easyFits : fits, null);
    if (pick == null) break;
    usedKeys.add(_shapeKey(pick.shape));
    pieces.add(_createRandomPiece(pick.shape));
  }

  while (pieces.length < targetCount) {
    final pick = _pickWeightedShape(fits, null);
    if (pick == null) break;
    pieces.add(_createRandomPiece(pick.shape));
  }

  pieces.shuffle(_random);
  return pieces;
}

PieceModel _createRandomPiece([List<List<int>>? shapeOverride]) {
  final shape = shapeOverride ?? _shapes[_random.nextInt(_shapes.length)];
  final color = _palette[_random.nextInt(_palette.length)];
  final blocks = shape.map((pair) => BlockModel(rowOffset: pair[0], colOffset: pair[1])).toList();
  return PieceModel(id: 'piece_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}', blocks: blocks, color: color);
}

List<_ShapeFit> _shapeFits({required int boardSize, required Map<int, Color> filledCells}) {
  final fits = <_ShapeFit>[];
  final cavityCells = _cavityCells(boardSize, filledCells);
  for (final shape in _shapes) {
    final dims = _shapeSize(shape);
    if (dims.width > boardSize || dims.height > boardSize) continue;
    final placementResult = _placementsForShape(
      shape: shape,
      boardSize: boardSize,
      filledCells: filledCells,
      cavityCells: cavityCells,
    );
    if (placementResult.total > 0) {
      final placements = placementResult.placements;
      fits.add(_ShapeFit(
        shape: shape,
        totalPlacements: placementResult.total,
        placements: placements,
        bestScore: placements.isEmpty ? 0 : placements.first.score,
      ));
    }
  }
  return fits;
}

int _placementAdjacencyScore({
  required List<List<int>> shape,
  required int baseRow,
  required int baseCol,
  required int size,
  required Map<int, Color> filledCells,
}) {
  final occupied = <int>{};
  for (final block in shape) {
    final r = baseRow + block[0];
    final c = baseCol + block[1];
    occupied.add(r * size + c);
  }
  var score = 0;
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  for (final block in shape) {
    final r = baseRow + block[0];
    final c = baseCol + block[1];
    for (final dir in dirs) {
      final nr = r + dir.$1;
      final nc = c + dir.$2;
      if (nr < 0 || nc < 0 || nr >= size || nc >= size) {
        score++;
        continue;
      }
      final index = nr * size + nc;
      if (occupied.contains(index)) continue;
      if (filledCells.containsKey(index)) score++;
    }
  }
  return score;
}

Set<int> _cavityCells(int size, Map<int, Color> filledCells) {
  final cavities = <int>{};
  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      final index = row * size + col;
      if (filledCells.containsKey(index)) continue;
      var neighbors = 0;
      if (row == 0 || filledCells.containsKey((row - 1) * size + col)) neighbors++;
      if (row == size - 1 || filledCells.containsKey((row + 1) * size + col)) neighbors++;
      if (col == 0 || filledCells.containsKey(row * size + col - 1)) neighbors++;
      if (col == size - 1 || filledCells.containsKey(row * size + col + 1)) neighbors++;
      if (neighbors >= _cavityNeighborThreshold) {
        cavities.add(index);
      }
    }
  }
  return cavities;
}

bool _isLineShape(List<List<int>> shape) {
  var sameRow = true;
  var sameCol = true;
  final firstRow = shape.first[0];
  final firstCol = shape.first[1];
  for (final block in shape) {
    if (block[0] != firstRow) sameRow = false;
    if (block[1] != firstCol) sameCol = false;
  }
  return sameRow || sameCol;
}

int _shapeFitWeight(_ShapeFit fit) {
  final scoreBoost = min(12, (fit.bestScore / 10).round());
  final placementBoost = min(4, fit.totalPlacements);
  return 1 + scoreBoost + placementBoost;
}

_ShapeFit? _pickWeightedShape(List<_ShapeFit> fits, Set<String>? usedKeys) {
  if (fits.isEmpty) return null;
  final pool = usedKeys == null
      ? fits
      : fits.where((fit) => !usedKeys.contains(_shapeKey(fit.shape))).toList();
  if (pool.isEmpty) return null;
  var total = 0;
  for (final fit in pool) {
    total += _shapeFitWeight(fit);
  }
  if (total <= 0) return pool[_random.nextInt(pool.length)];
  final target = _random.nextInt(total);
  var running = 0;
  for (final fit in pool) {
    running += _shapeFitWeight(fit);
    if (target < running) return fit;
  }
  return pool.last;
}

({List<_Placement> placements, int total}) _placementsForShape({
  required List<List<int>> shape,
  required int boardSize,
  required Map<int, Color> filledCells,
  required Set<int> cavityCells,
}) {
  final dims = _shapeSize(shape);
  final placements = <_Placement>[];
  var total = 0;
  final lineShape = _isLineShape(shape);
  for (var row = 0; row <= boardSize - dims.height; row++) {
    for (var col = 0; col <= boardSize - dims.width; col++) {
      var fitsHere = true;
      for (final block in shape) {
        final r = row + block[0];
        final c = col + block[1];
        final index = r * boardSize + c;
        if (filledCells.containsKey(index)) {
          fitsHere = false;
          break;
        }
      }
      if (!fitsHere) continue;
      total++;
      final adjacency = _placementAdjacencyScore(
        shape: shape,
        baseRow: row,
        baseCol: col,
        size: boardSize,
        filledCells: filledCells,
      );
      final placed = Map<int, Color>.from(filledCells);
      for (final block in shape) {
        final r = row + block[0];
        final c = col + block[1];
        placed[r * boardSize + c] = const Color(0xFFFFFFFF);
      }
      var cavityCovered = 0;
      for (final block in shape) {
        final r = row + block[0];
        final c = col + block[1];
        if (cavityCells.contains(r * boardSize + c)) cavityCovered++;
      }
      final clearResult = _clearCompletedLines(placed, boardSize);
      final clusterStats = _emptyClusterStats(boardSize, clearResult.cells);
      final score = _placementScore(
        linesCleared: clearResult.linesCleared,
        adjacency: adjacency,
        cavityCovered: cavityCovered,
        clusterCount: clusterStats.clusterCount,
        largestCluster: clusterStats.largestCluster,
        lineShape: lineShape,
      );
      placements.add(_Placement(
        row: row,
        col: col,
        linesCleared: clearResult.linesCleared,
        adjacency: adjacency,
        cavityCovered: cavityCovered,
        clusterCount: clusterStats.clusterCount,
        largestCluster: clusterStats.largestCluster,
        score: score,
        nextFilled: clearResult.cells,
      ));
    }
  }
  placements.sort((a, b) => b.score.compareTo(a.score));
  return (placements: placements.take(_maxPlacementsPerShape).toList(), total: total);
}

({Map<int, Color> cells, int linesCleared}) _clearCompletedLines(
  Map<int, Color> cells,
  int size,
) {
  final mutable = Map<int, Color>.from(cells);
  final clearedRows = <int>[];
  final clearedCols = <int>[];

  for (var row = 0; row < size; row++) {
    var full = true;
    for (var col = 0; col < size; col++) {
      if (!mutable.containsKey(row * size + col)) {
        full = false;
        break;
      }
    }
    if (full) clearedRows.add(row);
  }

  for (var col = 0; col < size; col++) {
    var full = true;
    for (var row = 0; row < size; row++) {
      if (!mutable.containsKey(row * size + col)) {
        full = false;
        break;
      }
    }
    if (full) clearedCols.add(col);
  }

  if (clearedRows.isEmpty && clearedCols.isEmpty) {
    return (cells: mutable, linesCleared: 0);
  }

  final toRemove = <int>{};
  for (final row in clearedRows) {
    for (var col = 0; col < size; col++) {
      toRemove.add(row * size + col);
    }
  }
  for (final col in clearedCols) {
    for (var row = 0; row < size; row++) {
      toRemove.add(row * size + col);
    }
  }
  for (final index in toRemove) {
    mutable.remove(index);
  }

  return (cells: mutable, linesCleared: clearedRows.length + clearedCols.length);
}

({int clusterCount, int largestCluster}) _emptyClusterStats(
  int size,
  Map<int, Color> filled,
) {
  final visited = List.generate(size, (_) => List.generate(size, (_) => false));
  var clusterCount = 0;
  var largestCluster = 0;

  bool isEmpty(int row, int col) => !filled.containsKey(row * size + col);

  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      if (visited[row][col] || !isEmpty(row, col)) continue;
      clusterCount++;
      var cells = 0;
      final queue = <({int r, int c})>[(r: row, c: col)];
      visited[row][col] = true;
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        cells++;
        const dirs = [(dr: 1, dc: 0), (dr: -1, dc: 0), (dr: 0, dc: 1), (dr: 0, dc: -1)];
        for (final dir in dirs) {
          final nr = current.r + dir.dr;
          final nc = current.c + dir.dc;
          if (nr < 0 || nc < 0 || nr >= size || nc >= size) continue;
          if (visited[nr][nc] || !isEmpty(nr, nc)) continue;
          visited[nr][nc] = true;
          queue.add((r: nr, c: nc));
        }
      }
      if (cells > largestCluster) largestCluster = cells;
    }
  }

  return (clusterCount: clusterCount, largestCluster: largestCluster);
}

int _placementScore({
  required int linesCleared,
  required int adjacency,
  required int cavityCovered,
  required int clusterCount,
  required int largestCluster,
  required bool lineShape,
}) {
  final clearScore = linesCleared * 40;
  final adjacencyScore = adjacency * 4;
  final cavityScore = cavityCovered * 20;
  final clusterScore = largestCluster;
  final fragmentationPenalty = clusterCount * 6;
  final linePenalty = lineShape && cavityCovered > 0 ? _lineShapePenalty : 0;
  return clearScore + adjacencyScore + cavityScore + clusterScore - fragmentationPenalty - linePenalty;
}

int _fitPreferenceScore(_ShapeFit fit, double easyBias, bool hasCavities) {
  final easyBonus = _isEasyShape(fit.shape) && !hasCavities ? (easyBias * 12).round() : 0;
  final linePenalty = hasCavities && _isLineShape(fit.shape) ? _lineShapePenalty : 0;
  return fit.bestScore + easyBonus - linePenalty;
}

List<List<List<int>>> _findPlayableShapeSet({
  required int boardSize,
  required Map<int, Color> filledCells,
  required int targetCount,
  required double easyBias,
  required int maxNodes,
}) {
  final chosen = <List<List<int>>>[];
  final usedKeys = <String>{};
  final budget = _SearchBudget(maxNodes);
  final success = _searchShapeSequence(
    boardSize: boardSize,
    filledCells: filledCells,
    targetCount: targetCount,
    easyBias: easyBias,
    usedKeys: usedKeys,
    chosen: chosen,
    budget: budget,
  );
  return success ? chosen : <List<List<int>>>[];
}

bool _searchShapeSequence({
  required int boardSize,
  required Map<int, Color> filledCells,
  required int targetCount,
  required double easyBias,
  required Set<String> usedKeys,
  required List<List<List<int>>> chosen,
  required _SearchBudget budget,
}) {
  if (chosen.length >= targetCount) return true;
  if (!budget.take()) return false;
  final hasCavities = _cavityCells(boardSize, filledCells).isNotEmpty;
  final fits = _shapeFits(boardSize: boardSize, filledCells: filledCells)
      .where((fit) => !usedKeys.contains(_shapeKey(fit.shape)))
      .toList()
    ..sort((a, b) => _fitPreferenceScore(b, easyBias, hasCavities).compareTo(_fitPreferenceScore(a, easyBias, hasCavities)));

  if (fits.isEmpty) return false;

  final shapeLimit = min(10, fits.length);
  for (var i = 0; i < shapeLimit; i++) {
    final fit = fits[i];
    final key = _shapeKey(fit.shape);
    final placements = fit.placements;
    if (placements.isEmpty) continue;
    for (final placement in placements) {
      chosen.add(fit.shape);
      usedKeys.add(key);
      final success = _searchShapeSequence(
        boardSize: boardSize,
        filledCells: placement.nextFilled,
        targetCount: targetCount,
        easyBias: easyBias,
        usedKeys: usedKeys,
        chosen: chosen,
        budget: budget,
      );
      if (success) return true;
      usedKeys.remove(key);
      chosen.removeLast();
    }
  }

  return false;
}

bool _isEasyShape(List<List<int>> shape) {
  final index = _shapes.indexOf(shape);
  return index != -1 && _easyShapeIndices.contains(index);
}

List<List<int>>? _pickShape(List<List<List<int>>> pool, Set<String>? usedKeys) {
  if (pool.isEmpty) return null;
  final wantsUnique = usedKeys != null;
  final maxAttempts = max(pool.length * 2, 12);
  for (var i = 0; i < maxAttempts; i++) {
    final shape = pool[_random.nextInt(pool.length)];
    if (!wantsUnique) return shape;
    final key = _shapeKey(shape);
    if (usedKeys!.add(key)) {
      return shape;
    }
  }
  // Pool exhausted for uniqueness; allow a duplicate to avoid returning null.
  return wantsUnique ? pool[_random.nextInt(pool.length)] : null;
}

String _shapeKey(List<List<int>> shape) {
  final normalized = shape.map((e) => '${e[0]}_${e[1]}').toList()..sort();
  return normalized.join('|');
}

bool _hasAnyValidMove(List<PieceModel> pieces, Map<int, Color> filled, int size) {
  for (final piece in pieces) {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        var fits = true;
        for (final block in piece.blocks) {
          final targetRow = row + block.rowOffset;
          final targetCol = col + block.colOffset;
          if (targetRow >= size || targetCol >= size || targetRow < 0 || targetCol < 0) {
            fits = false;
            break;
          }
          final index = targetRow * size + targetCol;
          if (filled.containsKey(index)) {
            fits = false;
            break;
          }
        }
        if (fits) return true;
      }
    }
  }
  return false;
}


List<List<List<int>>> _filterShapes({int? maxWidth, int? maxHeight}) {
  if (maxWidth == null && maxHeight == null) return _shapes;
  return _shapes.where((shape) {
    final dims = _shapeSize(shape);
    final withinWidth = maxWidth == null || dims.width <= maxWidth;
    final withinHeight = maxHeight == null || dims.height <= maxHeight;
    return withinWidth && withinHeight;
  }).toList();
}

({int width, int height}) _shapeSize(List<List<int>> shape) {
  var maxRow = 0;
  var maxCol = 0;
  for (final offset in shape) {
    if (offset[0] > maxRow) maxRow = offset[0];
    if (offset[1] > maxCol) maxCol = offset[1];
  }
  return (width: maxCol + 1, height: maxRow + 1);
}
