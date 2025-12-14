import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/block_model.dart';
import '../../models/piece_model.dart';

final _random = Random();

int _normalizeCount(int count) => count < 1 ? 1 : (count > 6 ? 6 : count);

// Default vivid yet soft puzzle palette (distinct, non-clashing hues).
const _palette = [
    Color(0xFFE7C07A),
  Color(0xFFD8AB63),
  Color(0xFFCC9650),
  Color(0xFFBD8643),
  Color(0xFFAD7536),
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
  final attemptLimit = max(1, maxAttempts);
  final targetCount = _normalizeCount(count);
  final spans = _maxEmptySpans(boardSize, filledCells);
  for (var i = 0; i < attemptLimit; i++) {
    final clusters = _emptyClusters(boardSize, filledCells);
    final alignedShapes = _shapesThatFitEmptySpaces(clusters: clusters, maxWidth: spans.maxColSpan, maxHeight: spans.maxRowSpan);
    final pieces = generateRandomPieces(count: targetCount, easyBias: easyBias, maxWidth: spans.maxColSpan, maxHeight: spans.maxRowSpan, preferredShapes: alignedShapes, uniqueShapes: true);
    if (_hasAnyValidMove(pieces, filledCells, boardSize)) {
      return pieces;
    }
  }
  final fallback = <PieceModel>[];
  if (targetCount > 1) {
    fallback.addAll(generateRandomPieces(count: targetCount - 1, easyBias: easyBias));
  }
  fallback.add(_createRandomPiece(_shapes[_singleBlockShapeIndex]));
  return fallback;
}

PieceModel _createRandomPiece([List<List<int>>? shapeOverride]) {
  final shape = shapeOverride ?? _shapes[_random.nextInt(_shapes.length)];
  final color = _palette[_random.nextInt(_palette.length)];
  final blocks = shape.map((pair) => BlockModel(rowOffset: pair[0], colOffset: pair[1])).toList();
  return PieceModel(id: 'piece_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}', blocks: blocks, color: color);
}

List<List<List<int>>> _shapesThatFitEmptySpaces({required List<({int width, int height, int cells})> clusters, int? maxWidth, int? maxHeight}) {
  if (clusters.isEmpty) return _filterShapes(maxWidth: maxWidth, maxHeight: maxHeight);
  final filtered = _filterShapes(maxWidth: maxWidth, maxHeight: maxHeight);
  final candidates = <List<List<int>>>{};
  for (final cluster in clusters) {
    for (final shape in filtered) {
      final dims = _shapeSize(shape);
      if (dims.width <= cluster.width && dims.height <= cluster.height && shape.length <= cluster.cells) {
        candidates.add(shape);
      }
    }
  }
  return candidates.toList();
}

List<({int width, int height, int cells})> _emptyClusters(int size, Map<int, Color> filled) {
  final visited = List.generate(size, (_) => List.generate(size, (_) => false));
  final clusters = <({int width, int height, int cells})>[];

  bool isEmpty(int row, int col) {
    final index = row * size + col;
    return !filled.containsKey(index);
  }

  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      if (visited[row][col] || !isEmpty(row, col)) continue;
      var minRow = row, maxRow = row, minCol = col, maxCol = col, cells = 0;
      final queue = <({int r, int c})>[(r: row, c: col)];
      visited[row][col] = true;
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        cells++;
        minRow = min(minRow, current.r);
        maxRow = max(maxRow, current.r);
        minCol = min(minCol, current.c);
        maxCol = max(maxCol, current.c);
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
      clusters.add((width: (maxCol - minCol) + 1, height: (maxRow - minRow) + 1, cells: cells));
    }
  }
  return clusters;
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

({int maxRowSpan, int maxColSpan}) _maxEmptySpans(int size, Map<int, Color> filled) {
  var maxRowSpan = 1;
  var maxColSpan = 1;
  for (var row = 0; row < size; row++) {
    var run = 0;
    for (var col = 0; col < size; col++) {
      final index = row * size + col;
      if (filled.containsKey(index)) {
        run = 0;
      } else {
        run++;
        if (run > maxRowSpan) maxRowSpan = run;
      }
    }
  }
  for (var col = 0; col < size; col++) {
    var run = 0;
    for (var row = 0; row < size; row++) {
      final index = row * size + col;
      if (filled.containsKey(index)) {
        run = 0;
      } else {
        run++;
        if (run > maxColSpan) maxColSpan = run;
      }
    }
  }
  return (maxRowSpan: maxRowSpan, maxColSpan: maxColSpan);
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
