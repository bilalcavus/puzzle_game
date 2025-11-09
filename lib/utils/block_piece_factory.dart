import 'dart:math';

import 'package:flutter/material.dart';

import '../models/block_model.dart';
import '../models/piece_model.dart';

final _random = Random();

const _palette = [
  Color(0xFFDAA06D),
  Color(0xFFEBC999),
  Color(0xFFD58C42),
  Color(0xFFE7B37A),
  Color(0xFFBE8A4A),
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
];

List<PieceModel> generateRandomPieces([int count = 3]) {
  return List<PieceModel>.generate(count, (_) => _createRandomPiece());
}

PieceModel _createRandomPiece() {
  final shape = _shapes[_random.nextInt(_shapes.length)];
  final color = _palette[_random.nextInt(_palette.length)];
  final blocks = shape.map((pair) => BlockModel(rowOffset: pair[0], colOffset: pair[1])).toList();
  return PieceModel(
    id: 'piece_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}',
    blocks: blocks,
    color: color,
  );
}
