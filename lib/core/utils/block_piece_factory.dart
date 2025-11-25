import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/block_model.dart';
import '../../models/piece_model.dart';

final _random = Random();

int _normalizeCount(int count) => count < 1 ? 1 : (count > 6 ? 6 : count);

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
  // Plus shape
  [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, 2],
    [2, 1],
  ],
  //Horizontal T shape 
  [
    [0,0],
    [1,0],
    [1,1],
    [2,0],
  ]
];

const List<int> _easyShapeIndices = [0, 1, 2, 3, 4];
const _singleBlockShapeIndex = 0;

List<PieceModel> generateRandomPieces([int count = 3]) {
  final target = _normalizeCount(count);
  final pieces = <PieceModel>[];
  final easyShape = _shapes[_easyShapeIndices[_random.nextInt(_easyShapeIndices.length)]];
  pieces.add(_createRandomPiece(easyShape));
  while (pieces.length < target) {
    pieces.add(_createRandomPiece());
  }
  pieces.shuffle(_random);
  return pieces;
}

List<PieceModel> generatePlayablePieces({
  required int boardSize,
  required Map<int, Color> filledCells,
  int count = 3,
  int maxAttempts = 32,
}) {
  final attemptLimit = max(1, maxAttempts);
  final targetCount = _normalizeCount(count);
  for (var i = 0; i < attemptLimit; i++) {
    final pieces = generateRandomPieces(targetCount);
    if (_hasAnyValidMove(pieces, filledCells, boardSize)) {
      return pieces;
    }
  }
  final fallback = <PieceModel>[];
  if (targetCount > 1) {
    fallback.addAll(generateRandomPieces(targetCount - 1));
  }
  fallback.add(_createRandomPiece(_shapes[_singleBlockShapeIndex]));
  return fallback;
}

PieceModel _createRandomPiece([List<List<int>>? shapeOverride]) {
  final shape = shapeOverride ?? _shapes[_random.nextInt(_shapes.length)];
  final color = _palette[_random.nextInt(_palette.length)];
  final blocks = shape.map((pair) => BlockModel(rowOffset: pair[0], colOffset: pair[1])).toList();
  return PieceModel(
    id: 'piece_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}',
    blocks: blocks,
    color: color,
  );
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
